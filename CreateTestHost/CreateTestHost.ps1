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
.PARAMETER NoZip
    When specified, a zip file is not created
.PARAMETER StagingRoot
    This is the root-folder where a subfolder is created to build the test-host. Defaults to %TEMP%.
.PARAMETER DestinationPath
    This is the path of the final zip file. When not specified, a path under $StagingRoot is automatically chosen. 
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
    $false -ne ($_ | Test-Path | Where-Object { -not $_} | Select-Object -First 1)
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
    if ($null -ne $psISE) {
        return (Get-Item (Split-Path -parent $psISE.CurrentFile.FullPath)).FullName
    }

    (Get-Item $PSScriptRoot).FullName
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
        $m.Groups[1].Captures | ForEach-Object {
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

Function Get-RuntimePacks {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $BaseSdkVersion,
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            Test-Path -PathType Leaf (Join-Path $_ 'dotnet.exe')
        })]
        [string]$InstallDir,
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            New-Item -Force -ItemType Directory $_ | Out-Null
            Test-Path -Pathtype Container -Path $_
        })]
        [string]$RuntimePacksDir
    )
 
    $temp = Join-Path $InstallDir '.temp'
    New-Item -Force -ItemType Directory $temp 

    $oldNugetCache = $env:NUGET_PACKAGES
    $env:NUGET_PACKAGES = $RuntimePacksDir 
    try {
        $dotnet = Join-Path $InstallDir 'dotnet.exe'
        $globalJson = Join-Path $temp 'global.json'
        $proj = Join-Path $temp 'wpf.csproj'

        Write-Verbose "$dotnet new globaljson --force --output $globalJson"
        . $dotnet new globaljson --force --sdk-version $BaseSdkVersion --output $globalJson

        Write-Verbose "$dotnet new wpf --force --output $proj"
        . $dotnet new wpf --force --output $proj

        Write-Verbose "$dotnet publish --runtime win-x64 $proj"
        . $dotnet publish --runtime win-x64 $proj

        Write-Verbose "$dotnet publish --runtime win-x86 $proj"
        . $dotnet publish --runtime win-x86 $proj
    }
    finally {
        $env:NUGET_PACKAGES = $oldNugetCache
        Remove-Item -Recurse -Force $temp
    }
}

function Update-RuntimePacksCache {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateSet('Debug', 'Release')]
        $Configuration,

        [Parameter(Mandatory=$true)]
        [ValidateSet('x86', 'x64')]
        [string]
        $Platform,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            $paths = $_
            $false -ne ($paths | Test-Path | Where-Object { -not $_ } | Select-Object -First 1)
        })]
        [string[]]
        $RepoRoots,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -PathType Container -Path $_})]
        [string]
        $RuntimePacksDir
    )
    
    $RuntimeIdentifier = "win-$Platform"
    $DestinationRoot = Join-Path $RuntimePacksDir "microsoft.windowsdesktop.app.runtime.$RuntimeIdentifier"
    $frameworkCount = Get-ChildItem -Path $DestinationRoot | Measure-Object 
    if ($frameworkCount.Count -ne 1) {
        Write-Error "Too many frameworks" -ErrorAction Stop
    }
    $DestinationRoot = Join-Path $DestinationRoot (Get-ChildItem $DestinationRoot)[0].Name
    $DestinationRoot = Join-Path $DestinationRoot 'runtimes'
    $DestinationRoot = Join-Path $DestinationRoot $RuntimeIdentifier

    Write-Verbose "Destination Root: $DestinationRoot"

    $targetTfm = (Get-ChildItem (Join-Path $DestinationRoot 'lib') 'netcoreapp*')[0].Name
    Write-Verbose "Destination TFM: $targetTfm"

    $RepoRoots | ForEach-Object {
        $RepoRoot = $_
        
        $Source = Join-Path $RepoRoot -ChildPath "artifacts\packaging\$Configuration"
        if ($Platform -ieq 'x64') {
            $Source = Join-path $Source $Platform
        }

        # Try each of the possible transport-package names
        $TransportPackageNames = @(
            'Microsoft.DotNet.Wpf.GitHub', 
            'Microsoft.DotNet.Wpf.GitHub.Debug', 
            'Microsoft.DotNet.Wpf.DncEng', 
            'Microsoft.DotNet.Wpf.DncEng.Debug' )

        $TransportPackageNames | ForEach-Object {
            $TransportPackageName = $_
            $PackageRoot = Join-path $Source $TransportPackageName
            Write-Verbose "Trying Transport Package Location $PackageRoot..."
            if (-not (Test-Path -PathType Container $PackageRoot)) {
                Write-Verbose "`t$PackageRoot not found..."
                return # continue enclosing ForEach-Object loop
            }
            $sourceTfm = (Get-ChildItem (Join-Path $PackageRoot 'lib') 'netcoreapp*')[0].Name
            Write-Verbose "Source TFM is $sourceTfm"
            if ($sourceTfm -ieq $targetTfm) {
                Write-Verbose "`tCopying.."
                Write-Verbose "`t $PackageRoot\lib -> $DestinationRoot\lib"
                Copy-Item `
                    -Recurse `
                    -Force `
                    -Path (Join-path $PackageRoot 'lib\*') `
                    -Destination (Join-Path $DestinationRoot 'lib')
                Write-Verbose "`t$PackageRoot\runtimes\$RuntimeIdentifier\native -> $DestinationRoot\native"
                Copy-Item `
                    -Recurse `
                    -Force `
                    -Path (Join-Path $PackageRoot "runtimes\$RuntimeIdentifier\native\*")`
                    -Destination (Join-path $DestinationRoot "native")
            }
        }
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

    & $copyWpfBins -Configuration $Configuration -Platform $Platform -RepoRoot $RepoRoots -Destination $Destination -BaseSdkVersion $BaseSdkVersion -Verbose:$Verbose

    $RuntimePacksDir = Join-Path $InstallDir '.runtimepacks'

    Get-RuntimePacks `
        -BaseSdkVersion $BaseSdkVersion `
        -InstallDir $InstallDir `
        -RuntimePacksDir $RuntimePacksDir

    @('x86', 'x64') | ForEach-Object {
        Write-Verbose ("Updating Runtime Packs Cache for Platform " + $_)
        Update-RuntimePacksCache `
        -Configuration $Configuration `
        -Platform $_ `
        -RepoRoots $RepoRoots `
        -RuntimePacksDir $RuntimePacksDir
    }

    # TODO: Update InstallMe.ps1 and local updater scripts to redirect nuget cache

    # Copy InstallMe.ps1 to $InstallDir
    $InstallMeScript = Join-Path $ScriptLocation 'InstallMe.ps1'
    if (Test-Path -PathType Leaf -Path $InstallMeScript) {
        Copy-Item -Path $InstallMeScript -Destination $InstallDir -Force
        Write-Verbose "Copied $InstallMeScript to $InstallDir"
    }

    # Copy EnvPaths\EnvPaths.psm1 to $InsallDir\EnvPaths
    $EnvPathsModule = Join-Path (Get-Item $ScriptLocation).Parent.FullName 'EnvPaths\EnvPaths.psm1'
    if (Test-Path -PathType Leaf -Path $EnvPathsModule) {
        if (-not (Test-Path (Join-Path $InstallDir 'EnvPaths'))) {
            New-Item -Path (Join-Path $InstallDir 'EnvPaths') -ItemType Directory -Force
        }
        Copy-Item -Path $EnvPathsModule -Destination (Join-Path $InstallDir 'EnvPaths') -Force
        Write-Verbose "Copied $EnvPathsModule to $InstallDir\EnvPaths"
    }

    $RepoList = ($RepoRoots | ForEach-Object {'[Cyan]'+ $_ }) -join ', '

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
        . $InstallMeScript
    }
}
Finally {
    if ($DeleteStagingFiles -and (Test-Path -Path $InstallDir -PathType Container)) {
        Write-Verbose "Deleting staging directory $InstallDir"
        Remove-Item -Recurse -Force $InstallDir
    }
}
