```

NAME
    Get-FrameworkVersions.ps1
    
SYNOPSIS
    Gets versions of shared frameworks like dotnet (Microsoft.NetCore.App), aspnetcore (Microsoft.AspNetCore.App), windowsdesktop 
    (Microsoft.WindowsDesktop.App) associated with a .NET Core SDK.
    
    
SYNTAX
    Get-FrameworkVersions.ps1 [[-Platform] <String>] [-SdkVersion] <String> [[-Runtime] <String>] 
    [[-SdkFolder] <String>] [-WindowsDesktopExtendedInfo] [-ReDownloadSdk] [-DoNotFallbackToProgramFiles] [<CommonParameters>]
    
    
DESCRIPTION
    Gets versions of shared frameworks like dotnet (Microsoft.NetCore.App), aspnetcore (Microsoft.AspNetCore.App), windowsdesktop 
    (Microsoft.WindowsDesktop.App) associated with a .NET Core SDK. 
    
    Looks for SDK's installed under $env:ProgramFiles or {$env:ProgramFiles(x86)}. If the SDK is not found, it downloads and installs the SDK under 
    $env:TEMP, and uses that copy to identify the shared framework versions.
    

PARAMETERS
    -Platform <String>
        The platform of the SDK to use. Defaults to x64. 
        Supported values are x86 and x64. 
        AnyCPU and 'Any CPU' are treated as equivalent to x86
        
    -SdkVersion <String>
        The version of the SDK to analyze. This is the only mandatory parameter.
        
    -Runtime <String>
        The name of the shared runtime whose version is being queried. 
        Valid values are 'dotnet' (Microsoft.NetCore.App), 'aspnet'(Microsoft.AspNetCore.App), 'windowsdesktop' (Microsoft.WindowsDesktop.App) and 'all' 
        (all 3 runtimeS). 
        The default value is 'all'.
        
    -SdkFolder <String>
        The script normally looks for SDK's under '$env:ProgramFiles\dotnet' (or {$env:ProgramFiles(x86)}\dotnet). It can be targeted to look look for SDK's 
        in a different location by overriding this parameter. 
        This is an advanced parameter and should not be normally used.
        
    -WindowsDesktopExtendedInfo [<SwitchParameter>]
        Shows extended version information about WindwosDesktop shared framework. 
        Setting this switch implicitly implies "-Runtime windowsdesktop"
        
    -ReDownloadSdk [<SwitchParameter>]
        When this switch is enabled, the SDK under $SdkFolder will be deleted and re-downloaded. 
        SDK's under $env:ProgramFiles or $env:ProgramFiles(x86) will not be normally deleted and re-downloaded, unless it is specified as a value for 
        $SdkFolder.
        
    -DoNotFallbackToProgramFiles [<SwitchParameter>]
        When this switch is enabled, search for SDK's under $env:ProgramFiles/$env:ProgramFiles(x86) is skipped. This allows the user to download a fresh 
        copy of the SDK.
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Get-FrameworkVersions.ps1 -SdkVersion 3.0.100
    
    Shared Framework                          Version
        ----------------                          -------
        Microsoft.AspNetCore.App                  3.0.0  
        Microsoft.NETCore.App                     3.0.0  
        Microsoft.WindowsDesktop.App              3.0.0  
        Microsoft.WindowsDesktop.App|WindowsForms 3.0.0  
        Microsoft.WindowsDesktop.App|WPF          3.0.0
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645
    
    Shared Framework                          Version               
    ----------------                          -------               
    Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
    Microsoft.NETCore.App                     3.1.0-preview3.19553.2
    Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
    Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
    Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -DoNotFallbackToProgramFiles -WindowsDesktopExtendedInfo
    
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
    
    
    
    
    -------------------------- EXAMPLE 4 --------------------------
    
    PS C:\>Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -ReDownloadSdk -DoNotFallbackToProgramFiles -Verbose
    
    VERBOSE: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645 exists; recreation requested - deleting...
           VERBOSE: Creating C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645...
           VERBOSE: Ensure-Path: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645 - Done
           VERBOSE: GET https://dot.net/v1/dotnet-install.ps1 with 0-byte payload
           VERBOSE: received 25202-byte response of content type application/octet-stream
           VERBOSE: Downloaded dotnet-install.ps1 to C:\Users\username\AppData\Local\Temp\dotnet-install.ps1
           VERBOSE: dotnet-install: Get-CLIArchitecture-From-Architecture -Architecture "x64"
           VERBOSE: dotnet-install: Get-Specific-Version-From-Version -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -Channel "LTS" -Version 
    "3.1.100-preview3-014645" -JSonFile ""
           VERBOSE: dotnet-install: Get-Download-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" 
    -CLIArchitecture "x64"
           VERBOSE: dotnet-install: Constructed primary named payload URL: 
    https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
           VERBOSE: dotnet-install: Get-LegacyDownload-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" 
    -CLIArchitecture "x64"
           VERBOSE: dotnet-install: Constructed legacy named payload URL: 
    https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-dev-win-x64.3.1.100-preview3-014645.zip
           VERBOSE: dotnet-install: Resolve-Installation-Path -InstallDir "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
           VERBOSE: dotnet-install: InstallRoot: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645
           VERBOSE: dotnet-install: Is-Dotnet-Package-Installed -InstallRoot "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645" 
    -RelativePathToPackage "sdk" -SpecificVersion "3.1.100-preview3-014645"
           VERBOSE: dotnet-install: Is-Dotnet-Package-Installed: Path to a package: 
    C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645
           VERBOSE: Perform operation 'Query CimInstances' with following parameters, ''queryExpression' = SELECT * FROM Win32_LogicalDisk WHERE 
    DeviceId='C:','queryDialect' = WQL,'namespaceName' = root\cimv2'.
           VERBOSE: Operation 'Query CimInstances' complete.
           VERBOSE: dotnet-install: Zip path: C:\Users\username\AppData\Local\Temp\l3xirqom.myx
           dotnet-install: Downloading link: 
    https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
           dotnet-install: Extracting zip from 
    https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
           VERBOSE: dotnet-install: Extract-Dotnet-Package -ZipPath "C:\Users\username\AppData\Local\Temp\l3xirqom.myx" -OutPath 
    "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
           VERBOSE: dotnet-install: Get-List-Of-Directories-And-Versions-To-Unpack-From-Dotnet-Package -Zip "System.IO.Compression.ZipArchive" -OutPath 
    "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
           VERBOSE: dotnet-install: Directories to unpack: host/fxr/3.1.0-preview3.19553.2/;packs/Microsoft.AspNetCore.App.Ref/3.1.0-preview3.19555.2/;packs/
    Microsoft.NETCore.App.Host.win-arm/3.1.0-preview3.19553.2/;packs/Microsoft.NETCore.App.Host.win-arm64/3.1.0
           -preview3.19553.2/;packs/Microsoft.NETCore.App.Host.win-x64/3.1.0-preview3.19553.2/;packs/Microsoft.NETCore.App.Host.win-x86/3.1.0-preview3.19553.
    2/;packs/Microsoft.NETCore.App.Ref/3.1.0-preview3.19553.2/;packs/Microsoft.WindowsDesktop.App.Ref/3.1.0-pre
           view3.19553.2/;packs/NETStandard.Library.Ref/2.1.0/;sdk/3.1.100-preview3-014645/;shared/Microsoft.AspNetCore.App/3.1.0-preview3.19555.2/;shared/Mi
    crosoft.NETCore.App/3.1.0-preview3.19553.2/;shared/Microsoft.WindowsDesktop.App/3.1.0-preview3.19553.2/;tem
           plates/3.1.0-preview3-014645/
           VERBOSE: dotnet-install: Is-Dotnet-Package-Installed -InstallRoot "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645" 
    -RelativePathToPackage "sdk" -SpecificVersion "3.1.100-preview3-014645"
           VERBOSE: dotnet-install: Is-Dotnet-Package-Installed: Path to a package: 
    C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645
           VERBOSE: dotnet-install: Current process PATH already contains "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\"
           dotnet-install: Installation finished
           VERBOSE: Identified Runtimes...
           VERBOSE: 	Microsoft.AspNetCore.App
           VERBOSE: 	Microsoft.NetCore.App
           VERBOSE: 	Microsoft.WindowsDesktop.App
           VERBOSE: Found 
    C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645\Microsoft.NETCoreSdk.BundledVersions.props
           VERBOSE: TFM: netcoreapp3.1
    
           Shared Framework                          Version               
           ----------------                          -------               
           Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
           Microsoft.NETCore.App                     3.1.0-preview3.19553.2
           Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
           Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
           Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2
    
    
    
    
    -------------------------- EXAMPLE 5 --------------------------
    
    PS C:\>Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -DoNotFallbackToProgramFiles -Verbose
    
    VERBOSE: Ensure-Path: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645 - Done
        VERBOSE: GET https://dot.net/v1/dotnet-install.ps1 with 0-byte payload
        VERBOSE: received 25202-byte response of content type application/octet-stream
        VERBOSE: Downloaded dotnet-install.ps1 to C:\Users\username\AppData\Local\Temp\dotnet-install.ps1
        VERBOSE: dotnet-install: Get-CLIArchitecture-From-Architecture -Architecture "x64"
        VERBOSE: dotnet-install: Get-Specific-Version-From-Version -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -Channel "LTS" -Version 
    "3.1.100-preview3-014645" -JSonFile ""
        VERBOSE: dotnet-install: Get-Download-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" 
    -CLIArchitecture "x64"
        VERBOSE: dotnet-install: Constructed primary named payload URL: 
    https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
        VERBOSE: dotnet-install: Get-LegacyDownload-Link -AzureFeed "https://dotnetcli.azureedge.net/dotnet" -SpecificVersion "3.1.100-preview3-014645" 
    -CLIArchitecture "x64"
        VERBOSE: dotnet-install: Constructed legacy named payload URL: 
    https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-dev-win-x64.3.1.100-preview3-014645.zip
        VERBOSE: dotnet-install: Resolve-Installation-Path -InstallDir "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645"
        VERBOSE: dotnet-install: InstallRoot: C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed -InstallRoot "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645" 
    -RelativePathToPackage "sdk" -SpecificVersion "3.1.100-preview3-014645"
        VERBOSE: dotnet-install: Is-Dotnet-Package-Installed: Path to a package: 
    C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645
        dotnet-install: .NET Core SDK version 3.1.100-preview3-014645 is already installed.
        VERBOSE: dotnet-install: Current process PATH already contains "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\"
        VERBOSE: Identified Runtimes...
        VERBOSE: 	Microsoft.AspNetCore.App
        VERBOSE: 	Microsoft.NetCore.App
        VERBOSE: 	Microsoft.WindowsDesktop.App
        VERBOSE: Found 
    C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\sdk\3.1.100-preview3-014645\Microsoft.NETCoreSdk.BundledVersions.props
        VERBOSE: TFM: netcoreapp3.1
    
        Shared Framework                          Version               
        ----------------                          -------               
        Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
        Microsoft.NETCore.App                     3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
        Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2
    
    
    
    
REMARKS
    To see the examples, type: "get-help Get-FrameworkVersions.ps1 -examples".
    For more information, type: "get-help Get-FrameworkVersions.ps1 -detailed".
    For technical information, type: "get-help Get-FrameworkVersions.ps1 -full".
```