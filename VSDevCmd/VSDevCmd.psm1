class VsDevCmd {
    hidden [System.Collections.Generic.Dictionary[string, string]]$SavedEnv = @{}
    static hidden [string] $vswhere = [VsDevCmd]::Initialize_VsWhere()

    static [string] hidden Initialize_VsWhere() {
        return [VsDevCmd]::Initialize_VsWhere($env:TEMP)
    }
    
    static [string] hidden Initialize_VsWhere([string] $InstallDir) {
        # Look for vswhere in these locations: 
        # - ${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe
        # -  $InstallDir\
        # -  $env:TEMP\
        # -  Anywhere in $env:PATH
        # If found, do not re-download. 

        [string]$vswhereExe = 'vswhere.exe'
        [string]$visualStudioIntallerPath = Join-Path "${env:ProgramFiles(x86)}\\Microsoft Visual Studio\\Installer\" $vswhereExe
        [string]$downloadPath = Join-path $InstallDir $vswhereExe
        [string]$VsWhereTempPath = Join-Path $env:TEMP $vswhereExe
        
        # Look under VS Installer Path 
        if (Test-Path $visualStudioIntallerPath -PathType Leaf) {
            return $visualStudioIntallerPath
        }

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
        $installationPath = . "$([VsDevCmd]::vswhere)" -prerelease -latest -property installationPath
        
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

            $cmdObject = Get-Command $Command -ErrorAction SilentlyContinue -CommandType Application
            if (-not $cmdObject) {
                throw New-Object System.ArgumentException 'Application Not Found', $Command
            }

            [string] $cmd = if ($cmdObject -is [array]) { $cmdObject[0].Source } else { $cmdObject.Source }
            Write-Verbose "$cmd"
            $result = . "$cmd" "$mergedArgs"
            return $result
        }
        finally {
            $this.Restore_Environment()
        }
    }
}


function Invoke-VsBuildCommand {
    param (
        [Parameter(Mandatory=$true, Position = 0, HelpMessage='Application or Commadn to Run')]
        [string]
        $Command, 
    
        [Parameter(Position=1, ValueFromRemainingArguments, HelpMessage='List of arguments')]
        [string[]]
        $Arguments
    )
   
    [VsDevCmd]::new().Start_BuildCommand($Command, $Arguments)

    <#
    .SYNOPSIS
        Runs an application/command in the VS Developer Command Prompt environment
    .DESCRIPTION
        Runs an application/command in the VS Developer Command Prompt environment
    .EXAMPLE
        PS C:\> Invoke-VsBuildCommand msbuild /?
        Runs 'msbuild /?'
    .INPUTS
        None. You cannot pipe objects to Invoke-VsBuildCommand
    .OUTPUTS
        System.String[]. Invoke-VsBuildCommand returns an array of strings that rerpesents the output of executing the application/command
        with the given arguments
    .PARAMETER Command
        Application/Command to execute in the VS Developer Command Prompt Environment
    .PARAMETER Arguments
        Arguments to pass to Application/Command being executed
    #>
}

Set-Alias -Name ivc -Value Invoke-VsBuildCommand

function Invoke-MsBuild {
    param (    
        [Parameter(Position=0, ValueFromRemainingArguments, HelpMessage='List of arguments')]
        [string[]]
        $Arguments
    )

    Invoke-VsBuildCommand 'msbuild' $Arguments

    <#
    .SYNOPSIS
        Runs MSBuild in the VS Developer Command Prompt environment
    .DESCRIPTION
        Runs MSBuild in the VS Developer Command Prompt environment
    .EXAMPLE
        PS C:\> Invoke-MsBuild /?
        Runs 'msbuild /?'
    .INPUTS
        None. You cannot pipe objects to Invoke-VsBuildCommand
    .OUTPUTS
        System.String[]. Invoke-MsBuild returns an array of strings that rerpesents the output of executing MSBuild
        with the given arguments
    .PARAMETER Arguments
        Arguments to pass to MSBuild
    #>
}

Set-Alias -Name imb -Value Invoke-MsBuild
Set-Alias -Name msbuild -Value Invoke-MsBuild



Export-ModuleMember Invoke-VsBuildCommand
Export-ModuleMember -Alias ivc

Export-ModuleMember Invoke-MsBuild
Export-ModuleMember -Alias imb
Export-ModuleMember -Alias msbuild