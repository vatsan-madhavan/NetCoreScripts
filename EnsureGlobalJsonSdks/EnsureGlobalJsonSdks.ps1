#
# EnsureGlobalJsonSdks.ps1
#

[CmdletBinding(PositionalBinding=$false)]
param(
  [string][Alias('s')]
  [Parameter(HelpMessage='Path to settings.json')]
  $settings, 

  [string] [Alias('t')]
  [Parameter(HelpMessage='Installation Path')]
  $installPath, 

  [string] [Alias('a')]
  [Parameter(HelpMessage='Architecture')]
  $architecture=$env:PROCESSOR_ARCHITECTURE
)

# Use-RunAs function from TechNet Script Gallery
# https://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb
function Use-RunAs {    
    # Check if script is running as Adminstrator and if not use RunAs 
    # Use Check Switch to check if admin 
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { 
        return $IsAdmin 
    }     
    if ($MyInvocation.ScriptName -ne "") {  
        if (-not $IsAdmin) {  
            try {  
                $arg = "-file `"$($MyInvocation.ScriptName)`"" 
                
                Write-Verbose "Starting elevated process..."
                Write-Verbose '\t' "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
                
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch { 
                Write-Warning "Error - Failed to restart script with runas"  
                break               
            } 
            Exit # Quit this session of powershell 
        }  
    }  
    else {  
        Write-Warning "Error - Script must be saved as a .ps1 file first"  
        break  
    }  
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

Use-RunAs
if (Test-Path $settings) {
    $global_json = (Get-Content $settings | ConvertFrom-Json)
    $sdk_version = $global_json.sdk.version
    $additional_sdks = $global_json.'additional-sdks'.versions

    $sdks = @()

    if (-not [string]::IsNullOrEmpty($sdk_version))
    {
        $sdks += $sdk_version
    }

    $additional_sdks.ForEach({
        if (-not [string]::IsNullOrEmpty($_)) {
            $sdks += $_
        }
    })

    Write-Verbose "List of SDK's being installed:"
    $sdks | % { Write-Verbose ("`t.NET Core " + $_) } 

    <# Create $installPath if it doesn't already exist #> 
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force
    }

    $installPath = (Resolve-Path $installPath).Path.ToLowerInvariant()

    if ($sdks) {
        $dotnet_install = "$env:TEMP\dotnet-install.ps1"

        $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
        [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

        Invoke-WebRequest https://dot.net/v1/dotnet-install.ps1 -OutFile $dotnet_install
        Write-Verbose "Downloaded dotnet-install.ps1 to $dotnet_install"

        <# 
            Sort the SDK's in descending order - this ensures that the oldest SDK (smallest version number)
            is installed last. 
        #>
        $sdks | Sort-Object -Descending |  % {
            if (-not [string]::IsNullOrEmpty($_)) {
                .$dotnet_install -Channel $channel -Version $_ -Architecture $architecture -InstallDir $installPath
                Write-Verbose "Installed SDK Version=$_ Channel=$channel Architecture=$architecture to $installPath"
            }
        }
                
       
        Add-EnvPath -path $installPath -prepend -emitAzPipelineLogCommand

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