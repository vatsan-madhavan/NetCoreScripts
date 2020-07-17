<#
.SYNOPSIS
    Runs a Build Command in VS Developer Command Prompt environment
.DESCRIPTION
    Runs a commands in VS Developer Command Prompt Environment
.PARAMETER Command
   Command to run
.EXAMPLE
    PS C:\> .\VSBuild.ps1 msbuild /?
    
    Runs 'msbuild /?' 
#>
param (
    [Parameter(Mandatory=$true, Position = 0)]
    [string]
    $Command, 

    [Parameter(Position=1, ValueFromRemainingArguments)]
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

Start-VsBuildCommand $Command $Arguments
