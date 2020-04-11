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
    if ($psISE -ne $null) {
        return (Get-Item (Split-Path -parent $psISE.CurrentFile.FullPath)).FullName
    }

    (Get-Item $PSScriptRoot).FullName
}

function Add-EnvPath {
    param(
        [string]$path, 
        [switch]$prepend = $false,
        [switch]$emitAzPipelineLogCommand = $false, 
        [switch]$persist = $false
    )

	<# 
		Treat $env:PATH and Environment::GetEnvironmentVariable("Path" EnvironmentVariableTarget::User) as distinct namespaces,
		and process them independently
	#>
		
    $userEnvPath = ([Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)).ToLowerInvariant()
	$envPath = $env:Path 
	
	Write-Verbose "User Environment Path"
	$userEnvPath.Split(';') | % {
		Write-Verbose ("`t" + $_)
	}
	
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
	
	if ($userEnvPath.Contains("$path;")) {                                <# path\to\dir\; #>
        $userEnvPath = $userEnvPath.Replace("$path;", '')
    } elseif ($userEnvPath.Contains($path)) {                             <# path\to\dir\  #>
        $userEnvPath = $userEnvPath.Replace($path, '')
    } elseif ($path.Contains($path.TrimEnd('\') + ";")) {             <# path\to\dir;  #>
        $userEnvPath = $userEnvPath.Replace($path.TrimEnd('\') + ";", '')
    } elseif ($path.Contains($path.TrimEnd('\'))) {                   <# path\to\dir   #>
        $userEnvPath = $userEnvPath.Replace($path.TrimEnd('\'), '')
    }
	
	Write-Verbose "Sanitized Environment Paths"
	$userEnvPath.Split(';') | % {
		Write-Verbose ("`t" + $_)
	}

    if ($prepend) {
        $envPath = "$path;" + $envPath
		$userEnvPath = "$path;" + $userEnvPath
    } else {
        $envPath += ";$path"
		$userEnvPath += ";$path"
    }

    $env:Path = $envPath
    if ($persist) {
        Write-Verbose "Persisting update to PATH User environment variable"
		$userEnvPath.Split(';') | % {
			Write-Verbose ("`t" + $_)
		}
        [Environment]::SetEnvironmentVariable("Path", $userEnvPath, [System.EnvironmentVariableTarget]::User)
    }

    if ($emitAzPipelineLogCommand) {
        if ($prepend) {
            Write-Host "##vso[task.prependpath]$path"
        } else {
            Write-Host "##vso[task.setvariable variable=PATH]$userEnvPath"
        }
    }

    Write-Verbose "Added $path to PATH variable"
}

$ScriptRoot = Get-PSScriptLocationFullPath
Write-Verbose "Script Root is at $ScriptRoot"
if (-not $DestinationPath) {
    $TestHostLocation = $ScriptRoot
} else {
    # Copy the TestHost SDK over to the target location
    Write-Verbose "Copying TestHost to $DestinationPath"
    Get-ChildItem -Path $ScriptRoot -Exclude "InstallMe.ps1*" | % {
        Copy-Item -Recurse -Path $_ -Destination $DestinationPath -Container -Force
    }

    $TestHostLocation = $DestinationPath
}

Write-Verbose "TestHost Location: $TestHostLocation"

Add-EnvPath -path $TestHostLocation -prepend -emitAzPipelineLogCommand -persist:$PersistPathUpdate

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