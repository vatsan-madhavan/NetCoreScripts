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
    
    PS C:\>Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -ReDownloadSdk -DoNotFallbackToProgramFiles
    
    dotnet-install: Downloading link: https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
           dotnet-install: Extracting zip from 
    https://dotnetcli.azureedge.net/dotnet/Sdk/3.1.100-preview3-014645/dotnet-sdk-3.1.100-preview3-014645-win-x64.zip
           dotnet-install: Installation finished
    
           Shared Framework                          Version               
           ----------------                          -------               
           Microsoft.AspNetCore.App                  3.1.0-preview3.19555.2
           Microsoft.NETCore.App                     3.1.0-preview3.19553.2
           Microsoft.WindowsDesktop.App              3.1.0-preview3.19553.2
           Microsoft.WindowsDesktop.App|WindowsForms 3.1.0-preview3.19553.2
           Microsoft.WindowsDesktop.App|WPF          3.1.0-preview3.19553.2
    
    
    
    
    -------------------------- EXAMPLE 5 --------------------------
    
    PS C:\>Get-FrameworkVersions.ps1 -SdkVersion 3.1.100-preview3-014645 -DoNotFallbackToProgramFiles
    
    dotnet-install: .NET Core SDK version 3.1.100-preview3-014645 is already installed.
        dotnet-install: Adding to current process PATH: "C:\Users\username\AppData\Local\Temp\dotnet-3.1.100-preview3-014645\". Note: This change will not 
    be visible if PowerShell was run as a child process.
    
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