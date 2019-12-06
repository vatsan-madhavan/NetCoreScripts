<#
.SYNOPSIS
   Creates a test host with private WPF binaries and produces a zip file containing the private SDK. 
.DESCRIPTION
    Creates a "test host" with private WPF binaries from local repos that are clones of https://github.com/dotnet/wpf 
    and https://dev.azure.com/dnceng/internal/_git/dotnet-wpf-int, and produces a zip file containing the private SDK
.PARAMETER BaseSdkVersion
    The .NET Core SDK to use as the base-version upon with the test-host will be built
.PARAMETER Configuration
    The build-configuration (Debug vs. Release) to use when copying binaries from locally built repo clones. 
    Defaults to 'Release'
.PARAMETER Platform
    The SDK platform to download and build a test-host for. Defaults to 'x86'. 
.PARAMETER RepoRoots
    Comma separated list of local repo root directories
.PARAMETER DeleteStagingFiles
    When specified, the staging directory where the base-version of the SDK is downloaded and updated 
    with locally built files will be deleted at the end of the script. 
.PARAMETER NoPath
    When specified, the PATH environment variable is not exported/set after the creation of the test host. Specifying
    -DeleteStagingFiles has the same effect as -NoPath
.EXAMPLE
    CreateTestHost.ps1 -BaseSdkVersion 3.1.100 -Configuration Release -Platform x64 -RepoRoots C:\src\repos\wpf,C:\src\repos\dotnet-wpf-int -DeleteStagingFiles

     - Uses .NET Core SDK version 3.1.100 x86 as the base version 
     - Copies 'Release' 'x64' binaries from the following two local clones onto the downloaded SDK
        - C:\src\repos\wpf
        - C:\src\repos\dotnet-wpf-int
     - Zips up the updated SDK and reports the path
     - Deletes the staging folder
       - Does not export PATH variable
#>
[CmdletBinding(PositionalBinding=$false)]
param(
  [string][Alias('v')]
  [Parameter(HelpMessage="Version number of the core-sdk build to use as the 'base' for the test-host", Mandatory=$true)]
  $BaseSdkVersion,

  [string][Alias('c')]
  [Parameter(HelpMessage="Release or Debug configuration; Defaults to 'Release'")]
  [ValidateSet('Release', 'Debug', IgnoreCase=$true)]
  $Configuration = 'Release',

  [string][Alias('p')]
  [Parameter(HelpMessage='x86 or x64')]
  [ValidateSet('x86', 'x64', 'AnyCPU', 'Any CPU', IgnoreCase=$true)]
  $Platform = 'x86',

  [string[]][Alias('r')]
  [Parameter(HelpMessage='Root of one or more repositories, separated by commas', Mandatory=$true)]
  [ValidateScript({
    $exists = $true
    $_ | % { 
      if (-not (Test-Path $_)) {
        $exists = $false
        Write-Warning "$_ doesn't exist"
      }
    }

    $exists
  })]
  $RepoRoots, 

  [switch]
  [Parameter(HelpMessage="When this switch is specified, the staging files used to build the final zip will be deleted automatically")]
  $DeleteStagingFiles, 

  [Parameter(HelpMessage="When this switch is set, only the test-host layout is created, but the PATH variable is not exported")]
  [switch]
  $NoPath, 

  [switch]
  [Parameter(HelpMessage="When this switch is set, the privatized test-host is not zipped into an archive for sharing")]
  $NoZip,

  [string]
  [Parameter(HelpMessage="Directory where the test-host SDK is staged, defaults to %TEMP% direcotry")]
  [ValidateScript({ Test-Path -Path $_ -PathType Container })]
  $StagingRoot=[System.IO.Path]::GetTempPath(),

  [string]
  [Parameter(HelpMessage="Target file path with extesion '.zip'")]
  [ValidateScript({
    $file = $_
    if (Test-Path -Path $file) {
        Write-Warning "$file : File already exists"
        $false
    }

    if ([System.IO.Path]::GetExtension($file) -ine 'zip') {
        Write-Warning "$file should have 'zip' extension"
        $false
    }

    $true
  })]
  $DestinationPath=$null
)

# https://stackoverflow.com/posts/34559554/revisions
function New-TemporaryDirectory {
    if (Get-Variable -Name StagingRoot -Scope Script -ErrorAction SilentlyContinue) {
        New-Item -ItemType Directory -Path (Join-Path $StagingRoot ([System.Guid]::NewGuid()))
    } else {
        New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid()))
    }
}

Function Get-PSScriptLocationFullPath {
    if ($psISE -ne $null) {
        return (Get-Item (Split-Path -parent $psISE.CurrentFile.FullPath)).FullName
    }

    (Get-Item $PSScriptRoot).FullName
}

function Add-EnvPath {
    param(
        [string]$path, 
        [switch]$prepend = $false,
        [switch]$emitAzPipelineLogCommand = $false 
    )

    
    [string]$envPath = $env:Path.ToLowerInvariant()
    if (-not $path.EndsWith('\')) {
        $path += '\'
    }

    <# 
        Remove any previous instance of $path from 
        $env:Path 

        Try from longest to shortest possible combination
    #>
    if ($envPath.Contains("$path;")) {                                <# path\to\dir\; #>
        $envPath = $envPath.Replace("$path;", '')
    } elseif ($envPath.Contains($path)) {                             <# path\to\dir\  #>
        $envPath = $envPath.Replace($path, '')
    } elseif ($path.Contains($path.TrimEnd('\') + ";")) {             <# path\to\dir;  #>
        $envPath = $envPath.Replace($path.TrimEnd('\') + ";", '')
    } elseif ($path.Contains($path.TrimEnd('\'))) {                   <# path\to\dir   #>
        $envPath = $envPath.Replace($path.TrimEnd('\'), '')
    }

    if ($prepend) {
        $envPath = "$path;" + $envPath
    } else {
        $envPath += ";$path"
    }

    $env:Path = $envPath

    if ($emitAzPipelineLogCommand) {
        if ($prepend) {
            Write-Host "##vso[task.prependpath]$path"
        } else {
            Write-Host "##vso[task.setvariable variable=PATH]$envPath"
        }
    }

    Write-Verbose "Added $path to PATH variable"
}

<#
.SYNOPSIS
    Writes a string to the host; enables some words to have colorized foreground
.PARAMETER $text
    String to be printed to the host. Forground colors for individual words should be
    prefixed in square brackets (without any space). For e.g., To colorize the word 
    "World" in Yellow in the sentence "Hello World!", express it as "Hello [Yellow]World!". 
.EXAMPLE
    Write-Color "[Yellow]Hello [Cyan]World!"

    Prints the word "Hello" in Yellow, and "World!" in Cyan respectively. 
#>
Function Write-Color {
    param([string]$text)

    $m = [regex]::Match($text, "(?:(\s+|\S+))+")
    if ($m -and $m.Groups.Count -eq 2) {
        $m.Groups[1].Captures | % {
            $colorName = $null 

            [System.Text.RegularExpressions.Capture]$capture = $_
            $word = $text[$capture.Index..($capture.Index+$capture.Length-1)] -join ''
            if ($word -match '\[(.+)\](.*)') {
                $colorName = $Matches[1]
                $word = $Matches[2]
            }

            if ($colorName) {
                Write-Host -NoNewline $word -ForegroundColor $colorName
            } else {
                Write-Host -NoNewline $word
            }
        }
        
        Write-Host
    }
}

$ScriptLocation = Get-PSScriptLocationFullPath
Write-Verbose "Script Location: $ScriptLocation"

$dotnet_install = "$env:TEMP\dotnet-install.ps1"
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

Invoke-WebRequest https://dot.net/v1/dotnet-install.ps1 -OutFile $dotnet_install
Write-Verbose "Downloaded dotnet-install.ps1 to $dotnet_install"

$InstallDirBase = New-TemporaryDirectory
$InstallDir = Join-Path $InstallDirBase $Platform
Write-Verbose "Staging directory will be $InstallDir"

$DoNotExportPathEnv = $NoPath -or $DeleteStagingFiles

if ($NoZip -and $DeleteStagingFiles) {
    Write-Color "[Red]WARNING: Both [Cyan]-NoZip and [Cyan]-DeleteStagingFiles are specified: nothing to be done"
    Write-Color "[Red]WARNING: Exiting..."
    exit 
}

Try {
    & $dotnet_install -Version $BaseSdkVersion -NoPath:$DoNotExportPathEnv -Architecture $Platform -InstallDir $InstallDir | Out-Null
    Write-Verbose "Downloaded base SDK $BaseSdkVersion to the staging directory at $InstallDir"


    $getFrameworkVersions = Join-Path (Join-Path (Split-Path -parent $ScriptLocation) 'GetFrameworkVersions') 'Get-FrameworkVersions.ps1'
    if (-not (Test-Path $getFrameworkVersions -PathType Leaf)) {
        Write-Error "$getFrameworkVersions not found" -ErrorAction Stop
    }

    # Import the environment set by the script - we want the $FrameworkInfo variable set by hte script
    . $getFrameworkVersions -SdkVersion $BaseSdkVersion -Runtime windowsDesktop -DoNotLaunchUrls -DoNotFallbackToProgramFiles -SdkFolder $InstallDir -Platform $Platform | Out-Null
    $WindowsDesktopFrameworkVersion = $FrameworkInfo['Microsoft.WindowsDesktop.App']

    if ([string]::IsNullOrEmpty($WindowsDesktopFrameworkVersion)) {
        Write-Error "Could not identify WindowsDesktop.App shared framework version for $BaseSdkVersion" -ErrorAction Stop
    }

    $Destination = Join-Path (Join-path (Join-Path $InstallDir 'shared') 'Microsoft.WindowsDesktop.App') $WindowsDesktopFrameworkVersion
    Write-Verbose "Copying private binaries to $Destination..."

    $copyWpfBins = Join-Path (Join-Path (Split-Path -parent $ScriptLocation) 'CopyWpfBins') 'CopyWpfBins.ps1'
    if (-not (test-path -PathType Leaf -Path $copyWpfBins)) {
        Write-Error "CopyWpfBins.ps1 not found" -ErrorAction Stop
    }

    & $copyWpfBins -Configuration $Configuration -Platform $Platform -RepoRoot $RepoRoots -Destination $Destination

    # Copy InstallMe.ps1 to $InstallDir
    $InstallMeScript = Join-Path $ScriptLocation 'InstallMe.ps1'
    if (Test-Path -PathType Leaf -Path $InstallMeScript) {
        Copy-Item -Path $InstallMeScript -Destination $InstallDir -Force
        Write-Verbose "Copied $InstallMeScript to $InstallDir"
    }

    $RepoList = ($RepoRoots | % {'[Cyan]'+$_ }) -join ', '

    Write-Host 
    Write-Color "Test Host Created at [Yellow]$InstallDir from .NET Core [Yellow]$BaseSdkVersion [Yellow]$Platform SDK from $RepoList [Yellow]$Configuration binaries"
    Write-Host


    if (-not $NoZip) {
        $username = $env:USERNAME
        if ($DestinationPath) {
            $ArchiveName = $DestinationPath
        } else {
            $ArchiveName = Join-Path $InstallDirBase "$BaseSdkVersion.$Platform.private.$username.zip"
        }

        Write-Verbose "Creating archive $ArchiveName..."
        Compress-Archive -Path "$InstallDir\*" -DestinationPath $ArchiveName

        Write-Color "[Yellow]$ArchiveName Created"
    }

    if ($DoNotExportPathEnv) {
        $NoPathFlags = @()
        if ($NoPath) {
            $NoPathFlags += '-NoPath'
        }
        if ($DeleteStagingFiles) {
            $NoPathFlags += '-DeleteStagingFiles'
        }

        $NoPathMessage =  ($NoPathFlags -join ',') + " specified: PATH [Red]not exported"
        Write-Color $NoPathMessage
    }
    
    if ((-not $DoNotExportPathEnv) -and (-not $DeleteStagingFiles) -and (Test-Path -PathType Container -Path $InstallDir)) {
        Add-EnvPath -path $InstallDir -prepend -emitAzPipelineLogCommand

        <#
           Emit the right signals to Azure Pipelines about 
           updating env vars
        #>
        Write-Host "##vso[task.setvariable variable=DOTNET_MULTILEVEL_LOOKUP]0"
        Write-Host "##vso[task.setvariable variable=DOTNET_SKIP_FIRST_TIME_EXPERIENCE]1"

        $env:DOTNET_MULTILEVEL_LOOKUP = 0
        $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = 1
    }
}
Finally {
    if ($DeleteStagingFiles -and (Test-Path -Path $InstallDir -PathType Container)) {
        Write-Verbose "Deleting staging directory $InstallDir"
        Remove-Item -Recurse -Force $InstallDir
    }
}
