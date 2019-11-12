```

NAME
    Install-Latest-DotnetCore.ps1
    
SYNOPSIS
    Installs .NET Core SDK to $env:ProgramFiles\dotnet and $env:ProgramFiles(x86)\dotnet
    
    
SYNTAX
    Install-Latest-DotnetCore.ps1 [-version <String>] [-channel <String>] [-elevate <Boolean>] 
    [<CommonParameters>]
    
    
DESCRIPTION
    Installs x86 and x64 versions of the .NET Core SDK to $env:ProgramFiles\dotnet and $env:ProgramFiles(x86)\dotnet
    respectively.
    
    To customize install location and other aspects of this script, download dotnet-install.ps1 
    from https://dot.net/v1/dotnet-install.ps1. See documentation at 
    https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script
    

PARAMETERS
    -version <String>
        Version number of the core-sdk build to install, defaults to "latest". Latest version
        number can be found at https://github.com/dotnet/core-sdk and https://dotnet.microsoft.com/download
        
    -channel <String>
        "channel" to install from, defaults to "master"
        Valid values for -channel are:
        	Current - Most current release
        	LTS - Long-Term Support channel (most current supported release)
        	Two-part version in X.Y format representing a specific release (for example, 2.0, or 1.0)
        	https://github.com/dotnet/core-sdk branch name (case-sensitive); for example, 
        		release/3.0.1xx, or master (for nightly releases)
        
    -elevate <Boolean>
        Runs this script elevated (defaults to "$true")
        Setting this to $false should almost never be required.
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS>Install-Latest-DotnetCore3.ps1
    
    Installs latest .NET Core SDK from 'master'
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS>Install-Latest-DotnetCore3.ps1 -version 3.0.100-preview7-012331
    
    Installs version 3.0.100-preview7-012331 of the .NET Core SDK
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS>Install-Latest-DotnetCore3.ps1 -version 3.0.100-preview6-012264 -channel Release
    
    Installs version 3.0.100-preview6-012264 of the core-sdk. Usually ignores the value 
    specified in -channel
    
    
    
    
    -------------------------- EXAMPLE 4 --------------------------
    
    PS>Install-Latest-DotnetCore3.ps1 -channel release/3.0.1xx
    
    Installs the latest build from release/3.0.1xx branch from https://github.com/dotnet/core-sdk
    
    
    
    
    -------------------------- EXAMPLE 5 --------------------------
    
    PS>Install-Latest-DotnetCore3.ps1 -elevate $false
    
    Installs the latest build from 'master'; will not attempt to elevate if the script
    is running without administrator priviliges (will fail if the script is running without 
    admin priviliges)
    
    
    
    
REMARKS
    To see the examples, type: "get-help Install-Latest-DotnetCore.ps1 -examples".
    For more information, type: "get-help Install-Latest-DotnetCore.ps1 -detailed".
    For technical information, type: "get-help Install-Latest-DotnetCore.ps1 -full".

```