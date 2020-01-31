Function Kill-ChildProcesses {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [int]$ProcessId,
        [string]$Tabs="",
        [switch]$DryRun
    )

    $processName = (Get-Process -Id $ProcessId).Name
    Write-Host "$Tabs[$processName] $ProcessId"

    Get-CimInstance Win32_Process | ? {
        $_.ParentProcessId -eq $ProcessId
    } | % {
        Kill-ChildProcesses -ProcessId $_.ProcessId -Tabs ($Tabs + "`t") -DryRun:$DryRun
    }

    if (-not $DryRun) {
        Stop-Process -Force -Id $processId
    }
}

Function Kill-ChildProcessesByName {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [string]$ProcessName,
        [switch]$DryRun
    )

    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | % {
        Kill-ChildProcesses -ProcessId $_.Id -DryRun:$DryRun
    }
}

[string[]]$processesToKill = @('msbuild', 'dotnet', 'vbcscompiler', 'nuget')

$processesToKill | % {
    Kill-ChildProcessesByName -ProcessName
}