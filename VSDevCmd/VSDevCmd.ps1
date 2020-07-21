<#PSScriptInfo

.VERSION 0.0.1

.GUID d86f9801-fccc-44e0-93f3-ac8b7f44d896

.AUTHOR Vatsan Madhavan

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#> 


<#
.SYNOPSIS
    Runs a Build Command in VS Developer Command Prompt environment
.DESCRIPTION
    Runs a commands in VS Developer Command Prompt Environment

    To see tool help, call with '/?' (not '-?'). Also see examples.
.PARAMETER Command
    Application/Command to execute in the VS Developer Command Prompt Environment
.PARAMETER Arguments
    Arguments to pass to Application/Command being executed
.PARAMETER VisualStudioEdition
    Selects Visual Studio Development Environment based on Edition (Community, Professional, Enterprise, etc.)
.PARAMETER VisualStudioVersion
    Selects Visual Studio Development Environment based on Version (2015, 2017, 2019 etc.)
.PARAMETER VisualStudioCodename
    Selects Visual Studio Development Environment based on Version CodeName (Dev14, Dev15, Dev16 etc.)
.PARAMETER VisualStudioBuildVersion
    Selects Visual Studio Development Environment based on Build Version (e.g., "15.9.25", "16.8.0").
    A prefix is sufficient (e.g., "15", "15.9", "16" etc.)
.PARAMETER Interactive
    Runs in interactive mode. Useful for running programs like cmd.exe, pwsh.exe, powershell.exe or csi.exe in the Visual Studio Developer Command Prompt Environment
.EXAMPLE
    PS C:\> .\VsDevCmd.ps1 msbuild /?
    Runs 'msbuild /?'
.EXAMPLE
    PS C:\> .\VsDevCmd.ps1 cmd -Interactive
    Starts a cmd prompt interactively in Visual Studio Developer Command Prompt Environment
    All the applications normally avaialble in the Visual Studio Developer Command Prompt Environment will be available in this cmd.exe session
#>
[CmdletBinding(DefaultParameterSetName='Default')]
param (
    [Parameter(ParameterSetName = 'Default', Position=0 ,Mandatory=$true, HelpMessage='Application or Command to Run')]
    [Parameter(ParameterSetName = 'CodeName', Position=0 ,Mandatory=$true, HelpMessage='Application or Command to Run')]
    [string]
    $Command,

    [Parameter(ParameterSetName = 'Default', Position=1, ValueFromRemainingArguments, HelpMessage='List of arguments')]
    [Parameter(ParameterSetName = 'CodeName', Position=1, ValueFromRemainingArguments, HelpMessage='List of arguments')]
    [string[]]
    $Arguments,

    [Parameter(ParameterSetName='Default', Mandatory = $false, HelpMessage='Selects Visual Studio Development Environment based on Edition (Community, Professional, Enterprise, etc.)')]
    [Parameter(ParameterSetName='CodeName', Mandatory = $false, HelpMessage='Selects Visual Studio Development Environment based on Edition (Community, Professional, Enterprise, etc.)')]
    [CmdletBinding(PositionalBinding=$false)]
    [Alias('Edition')]
    [ValidateSet('Community', 'Professional', 'Enteprise', $null)]
    [string]
    $VisualStudioEdition = $null,

    [Parameter(ParameterSetName='Default', Mandatory = $false, HelpMessage='Selects Visual Studio Development Environment based on Version (2015, 2017, 2019 etc.)')]
    [CmdletBinding(PositionalBinding=$false)]
    [Alias('Version')]
    [ValidateSet('2015', '2017', '2019', $null)]
    [string]
    $VisualStudioVersion = $null,

    [Parameter(ParameterSetName='CodeName', Mandatory = $false, HelpMessage='Selects Visual Studio Development Environment based on Version CodeName (Dev14, Dev15, Dev16 etc.)')]
    [CmdletBinding(PositionalBinding=$false)]
    [Alias('CodeName')]
    [ValidateSet('Dev14', 'Dev15', 'Dev16', $null)]
    [string]
    $VisualStudioCodeName=$null,

    [Parameter(ParameterSetName='Default', Mandatory = $false, HelpMessage='Selects Visual Studio Development Environment based on Build Version (e.g., "15.9.25", "16.8.0"). A prefix is sufficient (e.g., "15", "15.9", "16" etc.)')]
    [Parameter(ParameterSetName='CodeName', Mandatory = $false, HelpMessage='Selects Visual Studio Development Environment based on Build Version (e.g., "15.9.25", "16.8.0"). A prefix is sufficient (e.g., "15", "15.9", "16" etc.)')]
    [Alias('BuildVersion')]
    [CmdletBinding(PositionalBinding=$false)]
    [string]
    $VisualStudioBuildVersion = $null,

    [Parameter(ParameterSetName='Default', HelpMessage='Runs in interactive mode. Useful for running programs like cmd.exe, pwsh.exe, powershell.exe or csi.exe in the Visual Studio Developer Command Prompt Environment')]
    [Parameter(ParameterSetName='CodeName', HelpMessage='Runs in interactive mode. Useful for running programs like cmd.exe, pwsh.exe, powershell.exe or csi.exe in the Visual Studio Developer Command Prompt Environment')]
    [CmdletBinding(PositionalBinding=$false)]
    [switch]
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

switch ($PSCmdlet.ParameterSetName) {
    'CodeName' {
        # Call using VisualStudioCodeName; Do not pass $VisualStudioVersion
        Invoke-VsDevCommand $Command -Arguments $Arguments -VisualStudioEdition $VisualStudioEdition -VisualStudioCodeName $VisualStudioCodeName -VisualStudioBuildVersion $VisualStudioBuildVersion -Interactive:$Interactive
        Break;
    }

    Default {
        # Call using $VisualStudioVersion; Do not pass $VisualStudioCodeName
        Invoke-VsDevCommand $Command -Arguments $Arguments -VisualStudioEdition $VisualStudioEdition -VisualStudioVersion $VisualStudioVersion -VisualStudioBuildVersion $VisualStudioBuildVersion -Interactive:$Interactive
        Break;
    }
}
