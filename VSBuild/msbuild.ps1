<#
.SYNOPSIS
    Launches msbuild
.DESCRIPTION
    Queries the environment for installed versions of Visual Studio, and dynamically launches msbuild within a VS Developer Command Prompt like environment with the supplied arguments
.PARAMETER Arguments
    List of arguments to pass to msbuild
.EXAMPLE
    .\msbuild.ps1 Foo.proj /bl
    Builds project 'Foo.proj' and produces and binary-log 
.EXAMPLE 
    .\msbuild.ps1 /?
    Shows commandline help for msbuild.exe
#>
param (
    [Parameter(Position=0, ValueFromRemainingArguments)]
    [string[]]
    $Arguments
)

Function Get-PSScriptLocationFullPath {
    if ($null -ne $psISE) {
        return (Get-Item (Split-Path -parent $psISE.CurrentFile.FullPath)).FullName
    }

    (Get-Item $PSScriptRoot).FullName
}

$startBuildComandScriptName = 'VSBuild.ps1'
$startBuildCommandScript = Join-Path (Get-PSScriptLocationFullPath) $startBuildComandScriptName
if (-not (Test-Path -PathType Leaf -Path $startBuildCommandScript)) {
    Write-Error "$startBuildComandScriptName not found" -ErrorAction Stop
}

[string]$msbuildCommand = 'msbuild'

try {
    . $startBuildCommandScript -Command $msbuildCommand -Arguments $Arguments
} catch {
    Write-Error -Exception $_.Exception -ErrorAction Stop
}