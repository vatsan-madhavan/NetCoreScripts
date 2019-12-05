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

Use-RunAs

Invoke-Expression "reg.exe ADD HKCU\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f"
Invoke-Expression "reg.exe ADD HKU\.DEFAULT\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f"

$wpfDlls = & listdlls -d 'wpfgfx_v0400.dll' 

$wpfDlls