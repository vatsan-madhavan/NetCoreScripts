[CmdletBinding(PositionalBinding=$false)]
param(
  [bool]
  [Parameter(HelpMessage="Overwrite target directory if it already exists; defaults to true")]
  $OverWrite = $true,

  [string]
  [Parameter(HelpMessage="Target path where the test host will be 'installed'")]
  [ValidateScript({
    [string]$directory = $_
    if ($directory) {
        if (Test-Path -PathType Container -Path $directory) {
            if ($OverWrite) {
                Write-Warning "$directory : Directory exists and contents will be overwritten"
            } else {
                Write-Error "$directory : Directory exists and cannot be overwritten"
            }
        } else {
            Write-Verbose "Creating directory $directory"
            New-Item -ItemType Directory -Path $directory
        }
    }

    ($directory -eq $null) -or (Test-Path -PathType Container -Path $directory)
  })]
  $DestinationPath=$null,

  [switch]
  [Parameter(HelpMessage="Persist updates to PATH User Environment variable")]
  $PersistPathUpdate
)
Function Get-PSScriptLocationFullPath {
    if ($null -ne $psISE) {
        return (Get-Item (Split-Path -parent $psISE.CurrentFile.FullPath)).FullName
    }

    (Get-Item $PSScriptRoot).FullName
}


function Update-EnvPath {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [switch]$Persist
    )

    $Path = $Path.TrimEnd('\')

    # Always remove $Path from the environment first
    @($Path, $Path + '\') | ForEach-Object { 
        $pathToRemove = $_
        @('Session', 'User', 'Machine') | ForEach-Object {
            $container = $_
            try {
                Remove-EnvPath `
                -Path $pathToRemove `
                -Container $container
            }
            catch {
                Write-Verbose "Failed to remove $pathToRemove from $container\PATH" 
            }
        }
    }
    
    # Adding $Path only to Session container is normally sufficient
    # When $Persist is specified, also add to User container
    $containers = @('Session')
    if ($Persist) { $containers += 'User' }

    $containers | ForEach-Object {
        Add-EnvPath `
            -Path $Path `
            -Container $_ `
            -Prepend
    }

    # Emit Azure Pipline Log Command to prepend $Path to PATH environment variable
    Write-Host "##vso[task.prependpath]$Path" 
}


####################################### Script Body ########################

$ScriptRoot = Get-PSScriptLocationFullPath
Write-Verbose "Script Root is at $ScriptRoot"

# Import Module EnvPaths\EnvPaths.psm1
Import-Module (Join-Path $ScriptRoot 'EnvPaths\EnvPaths.psm1')

if (-not $DestinationPath) {
    $TestHostLocation = $ScriptRoot
} else {
    # Copy the TestHost SDK over to the target location
    Write-Verbose "Copying TestHost to $DestinationPath"
    Get-ChildItem -Path $ScriptRoot | ForEach-Object {
        Copy-Item -Recurse -Path $_ -Destination $DestinationPath -Container -Force
    }

    $TestHostLocation = $DestinationPath
}

Write-Verbose "TestHost Location: $TestHostLocation"
Update-EnvPath -Path $TestHostLocation -Persist:$PersistPathUpdate

# Set up a new NuGet cache
$runtimePacksCache = Join-Path $TestHostLocation '.runtimepacks'
if (test-path -PathType Container -Path $runtimePacksCache) {
    $nugetCache = Join-Path $TestHostLocation '.nuget'
    $nugetHttpCache = Join-Path $nugetCache 'v3-cache'
    $nugetPluginsCache = Join-Path $nugetCache 'plugins-cache'
    if (Test-Path $nugetCache) {
        Write-Verbose "$nugetCache Exists - Removing..."
        Remove-Item -Path $nugetCache -Force -Recurse
    }
    New-Item -ItemType Directory -Path $nugetCache | Out-Null
    New-Item -ItemType Directory -Path $nugetHttpCache
    New-Item -ItemType Directory -Path $nugetPluginsCache

    Write-Verbose "Populating NuGet Packages Source/Cache at $nugetCache from $runtimePacksCache.."
    Copy-Item -Path "$runtimePacksCache\*" -Destination "$TestHostLocation\.nuget\" -Recurse

    # Set up the env variable and emit the Azure Pipelines Log Command to redirect NuGet cache
    $env:NUGET_PACKAGES=$nugetCache
    $env:NUGET_HTTP_CACHE_PATH=$nugetHttpCache
    $env:NUGET_PLUGINS_CACHE_PATH=$nugetPluginsCache

    Write-Host "##vso[task.setvariable variable=NUGET_PACKAGES]$nugetCache"
    Write-Host "##vso[task.setvariable variable=NUGET_HTTP_CACHE_PATH]$nugetHttpCache"
    Write-Host "##vso[task.setvariable variable=NUGET_PLUGINS_CACHE_PATH]$nugetPluginsCache"
}

<#
    Emit the right signals to Azure Pipelines about 
    updating env vars
#>
Write-Host "##vso[task.setvariable variable=DOTNET_MULTILEVEL_LOOKUP]0"
Write-Host "##vso[task.setvariable variable=DOTNET_SKIP_FIRST_TIME_EXPERIENCE]1"
Write-Host "##vso[task.setvariable variable=DOTNET_ROOT]$TestHostLocation"

$env:DOTNET_MULTILEVEL_LOOKUP = 0
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = 1
$env:DOTNET_ROOT=$TestHostLocation

