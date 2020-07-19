<#
.SYNOPSIS
    Launches msbuild
.DESCRIPTION
    Queries the environment for installed versions of Visual Studio, and dynamically launches msbuild within a VS Developer Command Prompt like environment with the supplied arguments
    
    To see help for msbuild, call with '/?' (not '-?'). Also see examples.
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

$moduleName= 'VSDevCmd.psm1'
$modulePath = Join-Path (Get-PSScriptLocationFullPath) $moduleName
Import-Module $modulePath


msbuild $Arguments