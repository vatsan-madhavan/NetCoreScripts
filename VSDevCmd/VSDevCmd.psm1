class VsDevCmd {
    hidden [System.Collections.Generic.Dictionary[string, string]]$SavedEnv = @{}
    static hidden [string] $vswhere = [VsDevCmd]::Initialize_VsWhere()

    static [string] hidden Initialize_VsWhere() {
        return [VsDevCmd]::Initialize_VsWhere($env:TEMP)
    }
    
    static [string] hidden Initialize_VsWhere([string] $InstallDir) {
        # Look for vswhere in these locations: 
        # -  $InstallDir\
        # -  $env:TEMP\
        # -  Anywhere in $env:PATH
        # If found, do not re-download. 

        [string]$vswhereExe = 'vswhere.exe'
        [string]$downloadPath = Join-path $InstallDir $vswhereExe
        [string]$VsWhereTempPath = Join-Path $env:TEMP $vswhereExe
        
        # Look under $InstallDir
        if (Test-Path $downloadPath -PathType Leaf) {
            return $downloadPath
        }

        # Look under $env:TEMP
        if (Test-Path $VsWhereTempPath -PathType Leaf) {
            return $VsWhereTempPath
        }

        # Search $env:PATH
        $vsWhereCmd = Get-Command $vswhereExe -ErrorAction SilentlyContinue
        if ($vsWhereCmd -and $vsWhereCmd.Source -and (Test-Path $vsWhereCmd.Source)) {
            return $vsWhereCmd.Source
        }

        # Short-circuit logic didn't work - prepare to download a new copy of vswhere
        if (-not (Test-Path -Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir | Out-Null
        } 

        if (-not (Test-Path -Path $InstallDir -PathType Container)) {
            throw New-Object System.ArgumentException -ArgumentList 'Directory could not be created', 'InstallDir'
        }

        $vsWhereUri = 'https://github.com/microsoft/vswhere/releases/download/2.8.4/vswhere.exe'

        if (-not (Test-Path -Path $downloadPath -PathType Leaf)) {
            Invoke-WebRequest -Uri $vsWhereUri -OutFile (Join-Path $InstallDir 'vswhere.exe')
        }

        if (-not (Test-Path -Path $downloadPath -PathType Leaf)) {
            Write-Error "$downloadPath could not not be provisioned" -ErrorAction Stop
        }

        return $downloadPath
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
        try {
            $this.Start_VsDevCmd()

            $cmdObject = Get-Command $Command -ErrorAction SilentlyContinue
            if (-not $cmdObject) {
                throw New-Object System.ArgumentException 'Application Not Found', $Command
            }

            [string] $cmd = $cmdObject.Source

            Write-Verbose "$cmd"
            $result = . "$cmd" "$mergedArgs"
            return $result
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
   
    [VsDevCmd]::new().Start_BuildCommand($Command, $Arguments)
}

function Start-MsBuild {
    param (    
        [Parameter(Position=0, ValueFromRemainingArguments)]
        [string[]]
        $Arguments
    )

    Start-VsBuildCommand 'msbuild' $Arguments
}

Export-ModuleMember Start-VsBuildCommand
Export-ModuleMember Start-MsBuild