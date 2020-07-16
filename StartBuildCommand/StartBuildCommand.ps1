<#
.SYNOPSIS
    Runs a Build Command in VS Developer Command Prompt environment
.DESCRIPTION
    Runs a commands in VS Developer Command Prompt Environment
.PARAMETER Command
   Command to run
.EXAMPLE
    PS C:\> StartBuildCommand -Command msbuild /?
    
    Runs 'msbuild /?' 
#>
param (
    [Parameter(Mandatory=$true, Position = 0)]
    [string]
    $Command, 

    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string[]]
    $Arguments
)

$script:SavedEnv = @{}

Function Initialize-VsWhere {
    param (
        [ValidateScript({
            if (-not (Test-Path -Path $_)) {
                New-Item -ItemType Directory -Path $_
            }
            Test-Path -PathType Container -Path $_
        })]
        [string] $InstallDir=$env:TEMP
    )

    $vsWhereUri = 'https://github.com/microsoft/vswhere/releases/download/2.8.4/vswhere.exe'
    $vswhere = Join-path $InstallDir 'vswhere.exe'

    if (-not (Test-Path -Path $vswhere -PathType Leaf)) {
        Invoke-WebRequest -Uri $vsWhereUri -OutFile (Join-Path $InstallDir 'vswhere.exe')
    }

    if (-not (Test-Path -Path $vswhere -PathType Leaf)) {
        Write-Error "$vswhere could not not be provisioned" -ErrorAction Stop
    }

    $vswhere
}

Function Update-EnvironmentVariable {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        [Parameter(Mandatory=$true)]
        [string]
        $Value
    )

    if (-not ($script:SavedEnv.ContainsKey("$name"))) {
        $oldValue = [System.Environment]::GetEnvironmentVariable("$name", [System.EnvironmentVariableTarget]::Process)
        $script:SavedEnv["$name"] = $oldValue
    }

    [System.Environment]::SetEnvironmentVariable("$name", "$value", [System.EnvironmentVariableTarget]::Process)
}

Function Restore-Environment {
    $script:SavedEnv.Keys | ForEach-Object {
        $name = $_
        $value = $script:SavedEnv[$name]
        if (-not $value) {
            $value = [string]::Empty
        }
        [System.Environment]::SetEnvironmentVariable("$name", "$value", [System.EnvironmentVariableTarget]::Process)
    }
    $script:SavedEnv.Clear()
}

Function Start-VsDevCmd {
    $VsWhere = Initialize-VsWhere
    $installationPath = Invoke-Expression "$VsWhere -prerelease -latest -property installationPath"
    
    if (-not $installationPath) {
        Write-Error "Visual Studio Installation Path Not Found" - -ErrorAction Stop
    }

    if (-not (test-path "$installationPath\Common7\Tools\vsdevcmd.bat")) {
        Write-Error "$installationPath\Common7\Tools\vsdevcmd.bat not found" -ErrorAction Stop
    }

    Write-Verbose "Found: $installationPath\Common7\Tools\vsdevcmd.bat"

    . "${env:COMSPEC}" /s /c "`"$installationPath\Common7\Tools\vsdevcmd.bat`" -no_logo && set" | foreach-object {
        $name, $value = $_ -split '=', 2
        Write-Verbose "Setting env:$name=$value"
        if ($name -and $value) {
            # set-content env:\"$name" "$value"
            Update-EnvironmentVariable -Name "$name" -Value "$value"
            # [System.Environment]::SetEnvironmentVariable("$name", "$value", [System.EnvironmentVariableTarget]::Process)
        }
    }
}

Function Start-BuildCommand {
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    
    Initialize-VsWhere | Out-Null
    try {
        Start-VsDevCmd
        Invoke-Command -ScriptBlock $ScriptBlock
    }
    finally {
        Restore-Environment
    }
}

[string]$arguments = ($Arguments -join ' ').Trim()
if ($arguments) {
    $arguments = ' ' + $arguments
}

$cmd = $Command + $arguments

Start-BuildCommand {
    Write-Verbose "$cmd..."
    Invoke-Expression $cmd
}