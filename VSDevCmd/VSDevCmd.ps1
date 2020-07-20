<#
.SYNOPSIS
    Runs a Build Command in VS Developer Command Prompt environment
.DESCRIPTION
    Runs a commands in VS Developer Command Prompt Environment

    To see tool help, call with '/?' (not '-?'). Also see examples.
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
    $Arguments, 

    [switch]
    [CmdletBinding(PositionalBinding=$false)]
    $Interactive
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

vsdevcmd $Command $Arguments -Interactive:$Interactive
