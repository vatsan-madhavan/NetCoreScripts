<#
.SYNOPSIS
	Gets versions of shared frameworks like dotnet (Microsoft.NetCore.App), aspnetcore (Microsoft.AspNetCore.App), windowsdesktop (Microsoft.WindowsDesktop.App) associated with a .NET Core SDK. 
.DESCRIPTION
    Gets versions of shared frameworks like dotnet (Microsoft.NetCore.App), aspnetcore (Microsoft.AspNetCore.App), windowsdesktop (Microsoft.WindowsDesktop.App) associated with a .NET Core SDK. 

    Looks for SDK's installed under $env:ProgramFiles or {$env:ProgramFiles(x86)}. If the SDK is not found, it downloads and installs the SDK under $env:TEMP, and uses that copy to identify the shared framework versions. 
.PARAMETER Platform
    The platform of the SDK to use. Defaults to x64. 
    Supported values are x86 and x64. 
    AnyCPU and 'Any CPU' are treated as equivalent to x86
.PARAMETER SdkVersion
    The version of the SDK to analyze. This is the only mandatory parameter.
.PARAMETER Runtime 
    The name of the shared runtime whose version is being queried. 
    Valid values are 'dotnet' (Microsoft.NetCore.App), 'aspnet'(Microsoft.AspNetCore.App), 'windowsdesktop' (Microsoft.WindowsDesktop.App) and 'all' (all 3 runtimeS). 
    The default value is 'all'. 
.PARAMETER SdkFolder
    The script normally looks for SDK's under '$env:ProgramFiles\dotnet' (or {$env:ProgramFiles(x86)}\dotnet). It can be targeted to look look for SDK's in a different location by overriding this parameter. 
    This is an advanced parameter and should not be normally used. 
.PARAMETER WindowsDesktopExtendedInfo
    Shows extended version information about WindwosDesktop shared framework. 
    Setting this switch implicitly implies "-Runtime windowsdesktop"
.PARAMETER ReDownloadSdk
    When this switch is enabled, the SDK under $SdkFolder will be deleted and re-downloaded. 
    SDK's under $env:ProgramFiles or $env:ProgramFiles(x86) will not be normally deleted and re-downloaded, unless it is specified as a value for $SdkFolder. 
.PARAMETER DoNotFallbackToProgramFiles
    When this switch is enabled, search for SDK's under $env:ProgramFiles/$env:ProgramFiles(x86) is skipped. This allows the user to download a fresh copy of the SDK. 
.EXAMPLE
    Get-FrameworkVersions.ps1 -SdkVersion 3.0.100

        Shared Framework                          Version
        ----------------                          -------
        Microsoft.AspNetCore.App                  3.0.0  
        Microsoft.NETCore.App                     3.0.0  
        Microsoft.WindowsDesktop.App              3.0.0  
        Microsoft.WindowsDesktop.App|WindowsForms 3.0.0  
        Microsoft.WindowsDesktop.App|WPF          3.0.0  
.EXAMPLE	
    Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 

    Shared Framework                          Version               
    ----------------                          -------               
    Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
    Microsoft.NETCore.App                     3.1.0-preview3.19553.2
    Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
    Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
    Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2

.EXAMPLE
    Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -DoNotFallbackToProgramFiles -WindowsDesktopExtendedInfo
        dotnet-install: .NET Core SDK version 3.1.100-preview3-014645 is already installed.

        Shared Framework                          Version               
        ----------------                          -------               
        Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
        Microsoft.NETCore.App                     3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2



        WindowsDesktop.App Repo                                   Extended Version                                               
        -----------------------                                   ----------------                                               
        https://github.com/dotnet/wpf                             4.8.1-preview2.19553.1+3dfee2019cb6e2294cdfed441f1ac0e6026ceff7
        https://dev.azure.com/dnceng/internal/_git/dotnet-wpf-int 4.800.119.55302+90e4d4d634d385b0213347e8c1e43a8ca0a002c2    

.EXAMPLE
	Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -ReDownloadSdk -DoNotFallbackToProgramFiles

        dotnet-install: Downloading link: https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
        dotnet-install: Extracting zip from https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
        dotnet-install: Installation finished

        Shared Framework                          Version               
        ----------------                          -------               
        Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
        Microsoft.NETCore.App                     3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2

.EXAMPLE 
    Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -DoNotFallbackToProgramFiles

        dotnet-install: .NET Core SDK version 3.1.100-preview3-014645 is already installed.
        dotnet-install: Adding to current process PATH: "C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\". Note: This change will not be visible if PowerShell was run as a child process.

        Shared Framework                          Version
        ----------------                          -------
        Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
        Microsoft.NETCore.App                     3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2


#>
param(   
  [string][Alias('p')]
  [Parameter(HelpMessage='x86 or x64; AnyCPU and "Any CPU" are equivalent to "X86"')]
  [ValidateSet('x86', 'x64', 'AnyCPU', 'Any CPU', IgnoreCase=$true)]
  $Platform = 'x64',

  [string][Alias('v')][Alias('s')]
  [Parameter(HelpMessage='Destination Directory', Mandatory=$true)]
  $SdkVersion, 

  [string][Alias('r')]
  [Parameter(HelpMessage='Shared Runtime')]
  [ValidateSet('aspnet', 'dotnet', 'windowsdesktop', 'all')]
  $Runtime='all', 

  [string][Alias('d')]
  [Parameter(HelpMessage='Folder to downloading and extracting/installing the SDK')]
  $SdkFolder=(Join-Path $env:Temp "dotnet-$SdkVersion"),

  [Parameter(HelpMessage='Shows extended version info about WindowsDesktop Shared Framework')]
  [switch] $WindowsDesktopExtendedInfo,

  [Parameter(HelpMessage='Scorch and re-download the SDK even if it already exists in the destination folder')]
  [switch] $ReDownloadSdk,

  [Parameter(HelpMessage='If the SDK is found in Program Files, that will be normally used unless this switch is set')]
  [switch] $DoNotFallbackToProgramFiles
)

Function IIf($If, $Then, $Else) {
    If ($If -IsNot "Boolean") {$_ = $If}
    If ($If) {If ($Then -is "ScriptBlock") {&$Then} Else {$Then}}
    Else {If ($Else -is "ScriptBlock") {&$Else} Else {$Else}}
}

Function Fixup-AnyCPU {
    param(
        [string]$Platform
    )
    if ($Platform -ieq 'AnyCPU' -or $Platform -ieq 'Any CPU') {
        Write-Verbose "Platform:$Platform specified. Treating as x86"
        return 'x86'
    }

    return $Platform
}

Function Ensure-Path {
    param(
        [string]$path, 
        [switch]$recreate
    )


    if ($recreate -and (test-path $path)) {
        Write-Verbose "$path exists; recreation requested - deleting..."
        remove-item -Force -Recurse $path | out-null
    }

    
    if (-not (test-path $path)) {
        Write-Verbose "Creating $path..."
        new-item -ItemType Directory -Path $path | Out-Null
    }

    Write-Verbose "Ensure-Path: $path - Done"
}

Function Get-Tfm {
    param(
        [string]$SdkVersion
    )

    $WellKnownTFMs = @(
        'netcoreapp1.0',
        'netcoreapp1.1',
        'netcoreapp2.0',
        'netcoreapp2.1',
        'netcoreapp2.2',
        'netcoreapp3.0',
        'netcoreapp3.1',
        'netcoreapp5.0'
    )

    $tfm = ('netcoreapp' + $SdkVersion.Substring(0,3)).Trim().ToLowerInvariant()

    return IIf ($WellKnownTFMs -icontains $tfm) $tfm ""
}

Function Install-NetCore {
    param(
        [string]$SdkVersion,
        [string]$Platform,
        [string]$SdkFolder,
        [switch]$ReDownloadSdk
    )

    $dotnet_install = "$env:TEMP\dotnet-install.ps1"

    if ($ReDownloadSdk) {
        Ensure-Path -path $SdkFolder -recreate 
    } else {
        Ensure-Path -path $SdkFolder
    }

    $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

    Invoke-WebRequest https://dot.net/v1/dotnet-install.ps1 -OutFile $dotnet_install
    Write-Verbose "Downloaded dotnet-install.ps1 to $dotnet_install"

    & $dotnet_install -Version $SdkVersion -Architecture $Platform -InstallDir $SdkFolder
}

Function Get-Runtimes {
    param(
     [string]$Runtime,
     [switch]$WindowsDesktopExtendedInfo
    )

    $runtimes = @()
    if ($Runtime -ieq 'aspnet' -or $Runtime -ieq 'all') {
        $runtimes += 'Microsoft.AspNetCore.App'
    }
    if ($Runtime -ieq 'dotnet' -or $Runtime -ieq 'all') {
        $runtimes += 'Microsoft.NetCore.App' 
    }
    if ($Runtime -ieq 'windowsdesktop' -or $Runtime -ieq 'all' -or $WindowsDesktopExtendedInfo) {
        $runtimes += 'Microsoft.WindowsDesktop.App'
    }

    Write-Verbose "Identified Runtimes..."
    $runtimes | %{
        Write-Verbose `t$_
    }

    return $runtimes
}

Function Get-ProgramFilesDir {
    param(
     [ValidateSet('x86', 'x64', IgnoreCase=$true)]
     [string]$Platform
    )

    $ProgramFilesDir = Join-Path $env:ProgramFiles 'dotnet'

    if ([System.Environment]::Is64BitOperatingSystem -and $Platform -ieq 'x86') {
        $ProgramFilesDir = join-path ${env:ProgramFiles(x86)} 'dotnet'
    }

    Write-Verbose "Program Files Directory: $ProgramFilesDir"

    return $ProgramFilesDir
}

Function Search-ProgramFiles {
    param(
     [ValidateSet('x86', 'x64', IgnoreCase=$true)]
     [string]$Platform,
     [string]$SdkVersion
    )

    $ProgramFilesDir = Get-ProgramFilesDir -Platform $Platform

    $dotnet = join-path $ProgramFilesDir 'dotnet.exe' 

    if (-not (Test-Path $dotnet)) {
        Write-Verbose "SDK not found: dotnet.exe not found in $ProgramFilesDir"
        return $false 
    }

    $sdks = & $dotnet  --list-sdks | ? {
        $_ -ilike "*$SdkVersion *" -and $_ -ilike  "*$ProgramFilesDir*"
    } 

    if ($sdks -ne $null) {
        Write-Verbose "Found .NET Core SDK $SdkVersion in Program Files"
    }
    $sdks | % {
        $item = $_
        Write-Verbose "`t $item"
    }

    return ($sdks -ne $null)
}

Function Get-WindowsDesktopInfo {
    param(
        [hashtable]$RuntimesFolders
    )
    
    $RuntimesFolders.Keys | %{
        $framework = $_ 
        $frameworkPath = $RuntimesFolders[$_]
        if (-not (Test-Path $RuntimesFolders[$_])) {
            Write-Verbose "`tPath not found: $framework`: $frameworkPath"
        } else {
            Write-Verbose "`tPath found: $framework`: $frameworkPath"
        }
    }

    if ($RuntimesFolders.Keys -inotcontains 'Microsoft.WindowsDesktop.App') {
        Write-Verbose "`tMicrosoft.WindowsDesktop.App info not found"
        return
    }

    $wdHome = $RuntimesFolders['Microsoft.WindowsDesktop.App']

    $windowsBaseVersion = Get-ChildItem -Path $wdHome -Filter '*dll' | ? {
        $_.Name -ilike 'WindowsBase*.dll'
    } | % { 

        [string]$productVersion = $_.VersionInfo.ProductVersion
        <#
            These are the two possible formats
                4,800,19,46238 @Commit: c6a86389475b7d71a073433e3b2746f10b448ecb
                4.8.0-rc2.19462.14+3e99215204ccf7ae18e7c654ebdd77c91b7140e2 
        #>
        $productVersion.Replace(' @Commit: ', '+').Replace(',', '.')
    }

    
    $presentationNativeVersion = Get-ChildItem -Path $wdHome -Filter '*dll' | ? {
        $_.Name -ilike 'PresentationNative*.dll'
    } | % { 

        [string]$productVersion = $_.VersionInfo.ProductVersion
        <#
            These are the two possible formats
                4,800,19,46238 @Commit: c6a86389475b7d71a073433e3b2746f10b448ecb
                4.8.0-rc2.19462.14+3e99215204ccf7ae18e7c654ebdd77c91b7140e2 
        #>
        $productVersion.Replace(' @Commit: ', '+').Replace(',', '.')
    }

    if (-not $windowsBaseVersion) {
        Write-Warning "Could not find WindowsBase version information" 
    }
    
    if (-not $presentationNativeVersion) {
        Write-Warning "Could not find PresentationNative version information" 
    }
    
    Write-Verbose "`tInferring WindowsDesktop.App extended versions from WindowsBase.dll and PresentationNative*.dll"
    
    return @{
        'https://github.com/dotnet/wpf' = $windowsBaseVersion;
        'https://dev.azure.com/dnceng/internal/_git/dotnet-wpf-int' = $presentationNativeVersion
    }
}

<#https://stackoverflow.com/a/38981379#>
Function Format-Hashtable {
    param(
      [Parameter(Mandatory,ValueFromPipeline)]
      [hashtable]$Hashtable,

      [ValidateNotNullOrEmpty()]
      [string]$KeyHeader = 'Name',

      [ValidateNotNullOrEmpty()]
      [string]$ValueHeader = 'Value'
    )

    $Hashtable.GetEnumerator() |Select-Object @{Label=$KeyHeader;Expression={$_.Key}},@{Label=$ValueHeader;Expression={$_.Value}}

}

$Platform = Fixup-AnyCPU -Platform $Platform
$SdkVersion = $SdkVersion.Trim()

$NeedsNetCoreInstall = $true 
if (-not $DoNotFallbackToProgramFiles) {
    if (Search-ProgramFiles -Platform $Platform -SdkVersion $SdkVersion) {
        Write-Verbose ".NET Core SDK $SDKVersion found in Program Files - using that"
        $SdkFolder = Get-ProgramFilesDir -Platform $Platform 
        $ReDownloadSdk = $false 
        $NeedsNetCoreInstall = $false 
    }
}

if ($NeedsNetCoreInstall) {
    if ($ReDownloadSdk) {
        Install-NetCore -SdkVersion $SdkVersion -Platform $Platform -SdkFolder $SdkFolder -ReDownloadSdk
    } else {
        Install-NetCore $SdkVersion $Platform $SdkFolder
    }
}

if ($WindowsDesktopExtendedInfo) {
    $runtimes = Get-Runtimes $Runtime -WindowsDesktopExtendedInfo
} else {
    $runtimes = Get-Runtimes $Runtime
}

$sdkPropsFolder = join-path (join-path $SdkFolder 'sdk') $SdkVersion
$bundledVersionsPropsFile = join-path $sdkPropsFolder 'Microsoft.NETCoreSdk.BundledVersions.props'
Write-Verbose "Found $bundledVersionsPropsFile"

$tfm = Get-Tfm $SdkVersion
Write-Verbose "TFM: $tfm"


$knownFrameworkReferences = Select-Xml -Path $bundledVersionsPropsFile -XPath "/Project/ItemGroup/KnownFrameworkReference[@TargetFramework='$tfm']"

$runtimesFolders = @{}
$frameworkInfo = @{}
$knownFrameworkReferences | % {
    $frameworkName = $_.Node.RuntimeFrameworkName
    if ($runtimes -icontains $frameworkName) {
        $frameworkVersion = $_.Node.DefaultRuntimeFrameworkVersion 

        if ($_.Node.Attributes["Profile"] -ne $null) {
            $profileName = $_.Node.Attributes["Profile"].Value
            $frameworkName += "|$profileName"
        } else {
            $runtimesFolders[$frameworkName] = join-path (join-path (join-path $SdkFolder 'shared') $frameworkName) $frameworkVersion
        }

        $frameworkInfo[$frameworkName] = $frameworkVersion
    }
}

$frameworkInfo | Format-Hashtable -KeyHeader 'Shared Framework' -ValueHeader 'Version' | sort -Property 'Shared Framework' | ft -AutoSize

if ($WindowsDesktopExtendedInfo) {
    Get-WindowsDesktopInfo $runtimesFolders | Format-Hashtable -KeyHeader 'WindowsDesktop.App Repo' -ValueHeader 'Extended Version'| ft -AutoSize 
}


