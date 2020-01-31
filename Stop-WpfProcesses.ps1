# Use-RunAs function from TechNet Script Gallery
# https://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb
function Use-RunAs {    
    # Check if script is running as Adminstrator and if not use RunAs 
    # Use Check Switch to check if admin 
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { 
		return $IsAdmin 
	}     
    if ($MyInvocation.ScriptName -ne "") {  
        if (-not $IsAdmin) {  
            try {  
				$arg = "-file `"$($MyInvocation.ScriptName)`"" 
				
				Write-Verbose "Starting elevated process..."
				Write-Verbose ("`\t $psHome\powershell.exe -Verb Runas -ArgumentList $arg -ErrorAction 'stop'")
				
                Start-Process -FilePath "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'
            } 
            catch { 
                Write-Warning "Error - Failed to restart script with runas"  
                break               
            } 
            Exit # Quit this session of powershell 
        }  
    }  
    else {  
        Write-Warning "Error - Script must be saved as a .ps1 file first"  
        break  
    }  
} 

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

Use-RunAs

$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

Invoke-Expression "reg.exe ADD HKCU\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f" | Out-Null
Invoke-Expression "reg.exe ADD HKU\.DEFAULT\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f" | Out-Null

$listDLLs = join-path $env:TEMP "listDlls.exe"
if (-not (test-path -PathType Leaf $listDlls)) {
    Kill-ChildProcessesByName -ProcessName ListDlls
    Remove-Item -Path $listDlls -Force
}

Invoke-WebRequest "https://live.sysinternals.com/listdlls.exe" -OutFile $listDlls 

$wpfDlls = & $listDlls -d wpfgfx_v0400.dll

$processIDs = New-Object System.Collections.Generic.HashSet[int]
$wpfDlls | % {
    #[System.Text.RegularExpressions.MatchCollection]$matches = [regex]::Matches($_, "[\w\.]+\s+pid\:\s+(\d+)")
    if ($_ -match "[\w\.]+\s+pid\:\s+(\d+)") {
        [void]$processIDs.Add($Matches[1])
    }
}

$processIDs | % {
     Kill-ChildProcesses -ProcessId $_
}