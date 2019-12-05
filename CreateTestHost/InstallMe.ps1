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

$TestHostLocation = Get-PSScriptLocationFullPath
Write-Verbose "TestHost Location: $TestHostLocation"

Add-EnvPath -path $TestHostLocation -prepend -emitAzPipelineLogCommand

<#
    Emit the right signals to Azure Pipelines about 
    updating env vars
#>
Write-Host "##vso[task.setvariable variable=DOTNET_MULTILEVEL_LOOKUP]0"
Write-Host "##vso[task.setvariable variable=DOTNET_SKIP_FIRST_TIME_EXPERIENCE]1"

$env:DOTNET_MULTILEVEL_LOOKUP = 0
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = 1