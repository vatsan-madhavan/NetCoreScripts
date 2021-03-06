﻿[CmdletBinding(PositionalBinding=$false)]
param (
    [ValidateScript({$_ -ne $null})]
    [string[]]$BuildProcesses = @('msbuild', 'dotnet', 'vbcscompiler', 'mspdbsrv', 'git'),

    [ValidateScript({$_ -ne $null})]
    [string[]]$AdditionalBuildProcesses = @(), 

    [switch]$KillBuildProcesses, 

    [switch]$DryRun
)

Function Kill-ChildProcesses {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [int]$ProcessId,
        [string]$Tabs="",
        [switch]$DryRun
    )

    $processName = (Get-Process -Id $ProcessId).Name
    Write-Host "$Tabs[$processName] $ProcessId"

    if (-not $DryRun) {
        Get-Process -Id $processId -ErrorAction SilentlyContinue | % {
            try {
                $_.Kill($true)
            } catch {
                Write-Warning "Could not terminate $processName [$ProcessId] - likely part of current process tree"
                
            }
        }
    }
}

Function Kill-ChildProcessesByName {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [string]$ProcessName,
        [switch]$DryRun
    )

    $p = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue 
    if (-not $p) {
        Write-Verbose "Kill-ChildProcessesByName: Process $ProcessName not found - skipping"
    }
    else {
        $p | % {
            Kill-ChildProcesses -ProcessId $_.Id -DryRun:$DryRun
        }
    }
}


Function Get-PSScriptLocationFullPath {
    if ($psISE -ne $null) {
        return (Get-Item (Split-Path -parent $psISE.CurrentFile.FullPath)).FullName
    }

    (Get-Item $PSScriptRoot).FullName
}


Import-Module (Join-Path (Join-Path (Get-Item (Get-PSScriptLocationFullPath)).Parent.FullName 'UsePowerShellCore7') 'UsePowerShellCore7.psm1') -ErrorAction Stop
Use-PowershellCore7 -args $script:MyInvocation.Line -Verbose:$VerbosePreference


<#
Set GIT_ASK_YESNO=false to prevent interactive
Q&A from git like "Unlink of file '.vs/foo' failed. Should I try again? (y/n)"

GIT_ASK_YESNO is defined at 
https://github.com/git/git/blob/d62dad7a7dca3f6a65162bf0e52cdf6927958e78/compat/mingw.c#L188
No documentation as far as I can tell

Call to setlocal earlier would ensure that this setting is local to 
the lifetime of this batch-file's execution
#>
$env:GIT_ASK_YESNO = 'false'

if ($KillBuildProcesses) {
    ($BuildProcesses + $AdditionalBuildProcesses) | % {
        Kill-ChildProcessesByName -ProcessName $_ -DryRun:$DryRun
    }
}

$cleanCommand = "git clean -xdf"

if ($DryRun) {
    $cleanCommand += " --dry-run"
}

Write-Host "Cleaning git enlistment: $cleanCommand ..."

$gitOutput = Invoke-Expression -Command $cleanCommand | Out-String 
$gitOutput -split '\r?\n' | % {
    Write-Host "`t" -NoNewline
    Write-Host $_
}