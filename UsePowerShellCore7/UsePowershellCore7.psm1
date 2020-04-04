


Function Get-PowershellCore {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [string]$Version
    )

    if ((Get-Variable -Name PowerShellCorePath -Scope Script -ErrorAction SilentlyContinue -ValueOnly) -and 
        (Get-Command -Name $script.PowerShellCorePath -ErrorAction SilentlyContinue)) {
        $script:PowerShellCorePath
    }

    $pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
    
    if ($Version -and $pwsh) {
        $pwsh = $pwsh | ? { 
            $_.Version -ge (New-Object System.Version $Version) 
        }
    }

    if ($pwsh) {
        $script:PowerShellCorePath = $pwsh.Source
        $script:PowerShellCorePath
        return
    }

    $tempPath = [System.IO.Path]::GetTempFileName()
    Remove-Item -Force $tempPath | Out-Null
    New-Item -Path $tempPath -ItemType Directory | Out-Null
    # Schedule the temp folder to be deleted upon script completion
    $appDomain = [System.AppDomain]::CurrentDomain
    Register-ObjectEvent  -EventName DomainUnload -InputObject $appDomain  -Action{
        Write-Verbose "Deleting $tempPath..."
        Remove-Item -Path $tempPath -Force -Recurse -ErrorAction SilentlyContinue
    } | Out-Null

    $pwshInstallCommand = "dotnet tool install --tool-path $tempPath PowerShell"
    if ($VerbosePreference -ieq 'SilentlyContinue') {
        $pwshInstallCommand += " --verbosity minimal"
    }

    if ($Version) {
        $pwshInstallCommand += " --version $Version"
    }

    Write-Verbose "`t$pwshInstallCommand"
    $pwshInstallOutput = Invoke-Expression -Command $pwshInstallCommand | Out-String
    Write-Verbose $pwshInstallOutput 
    if ($VerbosePreference -ine 'SilentlyContinue') {
        Write-Host $pwshInstallCommand
    }



    $pwsh = Get-Command -Name (Join-Path $tempPath 'pwsh.exe') 

    $script:PowerShellCorePath = $pwsh.Source
    $script:PowerShellCorePath
}

Function Use-PowershellCore7 {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [string]$args
    )
    if ($PSVersionTable.PSVersion -lt "7.0" -or $PSVersionTable.PSEdition -ine 'Core') {
        Write-Verbose "Getting Powershell 7.0"
        $pwsh = Get-PowershellCore -Version "7.0"


        [string[]]$arguments = @()
        $arguments += @('-ExecutionPolicy', 'ByPass', '-NoProfile', '-command')
        $arguments += $args

        Write-Verbose "& $pwsh $arguments"
        & $pwsh $arguments
        exit
    }
}

Export-ModuleMember -Function Use-PowershellCore7