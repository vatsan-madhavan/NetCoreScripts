class VsDevCmd {
    hidden [System.Collections.Generic.Dictionary[string, string]]$SavedEnv = @{}
    static hidden [string] $vswhere = [VsDevCmd]::Initialize_VsWhere()

    static [string] hidden Initialize_VsWhere() {
        return [VsDevCmd]::Initialize_VsWhere($env:TEMP)
    }
    
    static [string] hidden Initialize_VsWhere([string] $InstallDir) {
        if (-not (Test-Path -Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir | Out-Null
        } 

        if (-not (Test-Path -Path $InstallDir -PathType Container)) {
            throw New-Object System.ArgumentException -ArgumentList 'Directory could not be created', 'InstallDir'
        }

        $vsWhereUri = 'https://github.com/microsoft/vswhere/releases/download/2.8.4/vswhere.exe'
        $path = Join-path $InstallDir 'vswhere.exe'

        if (-not (Test-Path -Path $path -PathType Leaf)) {
            Invoke-WebRequest -Uri $vsWhereUri -OutFile (Join-Path $InstallDir 'vswhere.exe')
        }

        if (-not (Test-Path -Path $path -PathType Leaf)) {
            Write-Error "$path could not not be provisioned" -ErrorAction Stop
        }

        return $path
    }
    
    [void] hidden Update_EnvironmentVariable ([string] $Name, [string] $Value) {
        if (-not ($this.SavedEnv.ContainsKey($Name))) {
            $oldValue = [System.Environment]::GetEnvironmentVariable($Name, [System.EnvironmentVariableTarget]::Process)
            $this.SavedEnv[$Name] = $oldValue
        }
    
        Write-Verbose "Updating env[$name] = $value"
        [System.Environment]::SetEnvironmentVariable("$name", "$value", [System.EnvironmentVariableTarget]::Process)
    }

    [void] hidden Restore_Environment() {
        $this.SavedEnv.Keys | ForEach-Object {
            $name = $_
            $value = $this.SavedEnv[$name]
            if (-not $value) {
                $value = [string]::Empty
            }
            [System.Environment]::SetEnvironmentVariable("$name", "$value", [System.EnvironmentVariableTarget]::Process)
        }
        $this.SavedEnv.Clear()
    }

    [void] hidden Start_VsDevCmd() {
        $installationPath = Invoke-Expression "$([VsDevCmd]::vswhere) -prerelease -latest -property installationPath"
        
        if (-not $installationPath) {
            Write-Error "Visual Studio Installation Path Not Found" - -ErrorAction Stop
        }
    
        if (-not (test-path "$installationPath\Common7\Tools\vsdevcmd.bat")) {
            Write-Error "$installationPath\Common7\Tools\vsdevcmd.bat not found" -ErrorAction Stop
        }
    
        Write-Verbose "Found: $installationPath\Common7\Tools\vsdevcmd.bat"
        [string[]]$envVars = . "${env:COMSPEC}" /s /c "`"$installationPath\Common7\Tools\vsdevcmd.bat`" -no_logo && set"
        foreach ($envVar in $envVars) {
            [string]$name, [string]$value = $envVar -split '=', 2
            Write-Verbose "Setting env:$name=$value"
            if ($name -and $value) {
                $this.Update_EnvironmentVariable($name, $value)
            }
       }
    }

    [string[]] Start_BuildCommand ([string]$Command, [string[]]$Arguments) {
        [string] $mergedArgs = ($Arguments -join ' ').Trim()
        [string] $cmd = if ($mergedArgs) { $Command + ' ' + $mergedArgs} else { $Command } 

        try {
            $this.Start_VsDevCmd()
            Write-Verbose "$cmd"
            return Invoke-Expression "$cmd"
        }
        finally {
            $this.Restore_Environment()
        }
    }
}


function Start-VsBuildCommand {
    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [string]
        $Command, 
    
        [Parameter(Position=1, ValueFromRemainingArguments)]
        [string[]]
        $Arguments
    )

    [string[]] $result = [string]::Empty
    
    try {
        [VsDevCmd]$vsDevCmd = [VsDevCmd]::new()
        $result = $vsDevCmd.Start_BuildCommand($Command, $Arguments)
    } catch {
        Write-Error $_.Exception.StackTrace -ErrorAction Continue
        Write-Error -Exception $_.Exception -ErrorAction Stop
    }

    $result
}

Export-ModuleMember Start-VsBuildCommand