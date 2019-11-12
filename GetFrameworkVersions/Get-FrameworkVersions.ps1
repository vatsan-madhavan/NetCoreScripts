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
.PARAMETER ReDownloadSdk
    When this switch is enabled, the SDK under $SdkFolder will be deleted and re-downloaded. 
    SDK's under $env:ProgramFiles or $env:ProgramFiles(x86) will not be normally deleted and re-downloaded, unless it is specified as a value for $SdkFolder. 
.PARAMETER DoNotFallbackToProgramFiles
    When this switch is enabled, search for SDK's under $env:ProgramFiles/$env:ProgramFiles(x86) is skipped. This allows the user to download a fresh copy of the SDK. 
.EXAMPLE
    Get-FrameworkVersions.ps1 -SdkVersion 3.0.100
        Microsoft.NETCore.App: 3.0.0
        Microsoft.WindowsDesktop.App: 3.0.0
        Microsoft.WindowsDesktop.App|WPF: 3.0.0
        Microsoft.WindowsDesktop.App|WindowsForms: 3.0.0
        Microsoft.AspNetCore.App: 3.0.0
.EXAMPLE	
    Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 
        dotnet-install: .NET Core SDK version 3.1.100-preview3-014645 is already installed.
        Microsoft.NETCore.App: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WPF: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WindowsForms: 3.1.0-preview3.19553.2
        Microsoft.AspNetCore.App: 3.1.0-preview3.19555.2
.EXAMPLE
	Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -ReDownloadSdk -DoNotFallbackToProgramFiles -Verbose
        VERBOSE: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645 exists; recreation requested - deleting...
        VERBOSE: Creating C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645...
        VERBOSE: Ensure-Path: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645 - Done
        VERBOSE: GET https://dot.net/v1/dotnet-install.ps1 with 0-byte payload
        VERBOSE: received 25202-byte response of content type application/octet-stream
        VERBOSE: Downloaded dotnet-install.ps1 to C:\Users\username\AppData\Local\Temp\dotnet-install.ps1
        VERBOSE: dotnet-install: Get-CLIArchitecture-From-Architecture -Architecture "x64"
        VERBOSE: dotnet-install: Get-Specific-Version-From-Version -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -Channel "LTS" -Version "3.1.100-preview3-014645" -JSonFile ""
        VERBOSE: dotnet-install: Get-Download-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" -CLIArchitecture "x64"
        VERBOSE: dotnet-install: Constructed primary named payload URL: https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
        VERBOSE: dotnet-install: Get-LegacyDownload-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" -CLIArchitecture "x64"
        VERBOSE: dotnet-install: Constructed legacy named payload URL: https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-dev-win-x64.3.1.100-preview3-014645.zip
        VERBOSE: dotnet-install: Resolve-Installation-Path -InstallDir "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
        VERBOSE: dotnet-install: InstallRoot: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed -InstallRoot "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645" -RelativePathToPackage "sdk" -SpecificVersion "3.1.100-preview3-014645"
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed: Path to a package: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645
        VERBOSE: Perform operation 'Query CimInstances' with following parameters, ''queryExpression' = SELECT * FROM Win32_LogicalDisk WHERE DeviceId='C:','queryDialect' = WQL,'namespaceName' = root\cimv2'.
        VERBOSE: Operation 'Query CimInstances' complete.
        VERBOSE: dotnet-install: Zip path: C:\Users\username\AppData\Local\Temp\qdsgbwaw.isr
        dotnet-install: Downloading link: https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
        dotnet-install: Extracting zip from https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
        VERBOSE: dotnet-install: Extract-Dotnet-Package -ZipPath "C:\Users\username\AppData\Local\Temp\qdsgbwaw.isr" -OutPath "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
        VERBOSE: dotnet-install: Get-List-Of-Directories-And-Versions-To-Unpack-From-Dotnet-Package -Zip "System.IO.Compression.ZipArchive" -OutPath "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
        VERBOSE: dotnet-install: Directories to unpack: host/fxr/3.1.0-preview3.19553.2/;packs/Microsoft.AspNetCore.App.Ref/3.1.0-preview3.19555.2/;packs/Microsoft.NETCore.App.Host.win-arm/3.1.0-preview3.19553.2/;packs/Microsoft.NETCore.App.Host.win-arm64/3.1.0
        -preview3.19553.2/;packs/Microsoft.NETCore.App.Host.win-x64/3.1.0-preview3.19553.2/;packs/Microsoft.NETCore.App.Host.win-x86/3.1.0-preview3.19553.2/;packs/Microsoft.NETCore.App.Ref/3.1.0-preview3.19553.2/;packs/Microsoft.WindowsDesktop.App.Ref/3.1.0-pre
        view3.19553.2/;packs/NETStandard.Library.Ref/2.1.0/;sdk/3.1.100-preview3-014645/;shared/Microsoft.AspNetCore.App/3.1.0-preview3.19555.2/;shared/Microsoft.NETCore.App/3.1.0-preview3.19553.2/;shared/Microsoft.WindowsDesktop.App/3.1.0-preview3.19553.2/;tem
        plates/3.1.0-preview3-014645/
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed -InstallRoot "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645" -RelativePathToPackage "sdk" -SpecificVersion "3.1.100-preview3-014645"
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed: Path to a package: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645
        VERBOSE: dotnet-install: Current process PATH already contains "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\"
        dotnet-install: Installation finished
        VERBOSE: Identified Runtimes...
        VERBOSE: 	Microsoft.AspNetCore.App
        VERBOSE: 	Microsoft.NetCore.App
        VERBOSE: 	Microsoft.WindowsDesktop.App
        VERBOSE: Found C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645\Microsoft.NETCoreSdk.BundledVersions.props
        VERBOSE: TFM: netcoreapp3.1
        Microsoft.NETCore.App: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WPF: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WindowsForms: 3.1.0-preview3.19553.2
        Microsoft.AspNetCore.App: 3.1.0-preview3.19555.2
.EXAMPLE 
    Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -DoNotFallbackToProgramFiles -Verbose
        VERBOSE: Ensure-Path: C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645 - Done
        VERBOSE: GET https://dot.net/v1/dotnet-install.ps1 with 0-byte payload
        VERBOSE: received 25202-byte response of content type application/octet-stream
        VERBOSE: Downloaded dotnet-install.ps1 to C:\Users\srivatsm\AppData\Local\Temp\dotnet-install.ps1
        VERBOSE: dotnet-install: Get-CLIArchitecture-From-Architecture -Architecture "x64"
        VERBOSE: dotnet-install: Get-Specific-Version-From-Version -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -Channel "LTS" -Version "3.1.100-preview3-014645" -JSonFile ""
        VERBOSE: dotnet-install: Get-Download-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" -CLIArchitecture "x64"
        VERBOSE: dotnet-install: Constructed primary named payload URL: https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
        VERBOSE: dotnet-install: Get-LegacyDownload-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" -CLIArchitecture "x64"
        VERBOSE: dotnet-install: Constructed legacy named payload URL: https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-dev-win-x64.3.1.100-preview3-014645.zip
        VERBOSE: dotnet-install: Resolve-Installation-Path -InstallDir "C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
        VERBOSE: dotnet-install: InstallRoot: C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed -InstallRoot "C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645" -RelativePathToPackage "sdk" -SpecificVersion "3.1.100-preview3-014645"
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed: Path to a package: C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645
        dotnet-install: .NET Core SDK version 3.1.100-preview3-014645 is already installed.
        VERBOSE: dotnet-install: Current process PATH already contains "C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\"
        VERBOSE: Identified Runtimes...
        VERBOSE: 	Microsoft.AspNetCore.App
        VERBOSE: 	Microsoft.NetCore.App
        VERBOSE: 	Microsoft.WindowsDesktop.App
        VERBOSE: Found C:\Users\srivatsm\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645\Microsoft.NETCoreSdk.BundledVersions.props
        VERBOSE: TFM: netcoreapp3.1
        Microsoft.NETCore.App: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WPF: 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WindowsForms: 3.1.0-preview3.19553.2
        Microsoft.AspNetCore.App: 3.1.0-preview3.19555.2
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
     [string]$Runtime
    )

    $runtimes = @()
    if ($Runtime -ieq 'aspnet' -or $Runtime -ieq 'all') {
        $runtimes += 'Microsoft.AspNetCore.App'
    }
    if ($Runtime -ieq 'dotnet' -or $Runtime -ieq 'all') {
        $runtimes += 'Microsoft.NetCore.App' 
    }
    if ($Runtime -ieq 'windowsdesktop' -or $Runtime -ieq 'all') {
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

    $sdks = & dotnet  --list-sdks | ? {
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

$Platform = Fixup-AnyCPU -Platform $Platform
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

$runtimesFolder = join-path $SdkFolder 'shared' 
$runtimes = Get-Runtimes $Runtime

$sdkPropsFolder = join-path (join-path $SdkFolder 'sdk') $SdkVersion
$bundledVersionsPropsFile = join-path $sdkPropsFolder 'Microsoft.NETCoreSdk.BundledVersions.props'
Write-Verbose "Found $bundledVersionsPropsFile"

$tfm = Get-Tfm $SdkVersion
Write-Verbose "TFM: $tfm"


$knownFrameworkReferences = Select-Xml -Path $bundledVersionsPropsFile -XPath "/Project/ItemGroup/KnownFrameworkReference[@TargetFramework='$tfm']"

$knownFrameworkReferences | % {
    $frameworkName = $_.Node.RuntimeFrameworkName
    if ($runtimes -icontains $frameworkName) {
        $frameworkVersion = $_.Node.DefaultRuntimeFrameworkVersion 

        if ($_.Node.Attributes["Profile"] -ne $null) {
            $profileName = $_.Node.Attributes["Profile"].Value
            $frameworkName += "|$profileName"
        }

        Write-Host "$frameworkName`: $frameworkVersion"
    }
}
