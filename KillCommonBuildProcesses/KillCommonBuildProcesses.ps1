[CmdletBinding(PositionalBinding=$false)]
param (
    [ValidateScript({$_ -ne $null})]
    [string[]]$BuildProcesses = @('msbuild', 'dotnet', 'vbcscompiler', 'mspdbsrv', 'git'),

    [ValidateScript({$_ -ne $null})]
    [string[]]$AdditionalBuildProcesses = @(), 

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


($BuildProcesses + $AdditionalBuildProcesses) | % {
	Kill-ChildProcessesByName -ProcessName $_ -DryRun:$DryRun
}
