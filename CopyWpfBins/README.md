```

NAME
    CopyWpfBins.ps1
    
SYNOPSIS
    Copies built binaries from a WPF repo to a specified destination.
    
    
SYNTAX
    CopyWpfBins.ps1 [[-Configuration] <String>] [[-Platform] <String>] [-RepoRoot] <String[]> [-Destination] 
    <String> [<CommonParameters>]
    
    
DESCRIPTION
    Copies built binaries from a WPF repo to a specified destination. 
    
    Supported WPF repos are:
        https://github.com/dotnet/wpf 
        https://dev.azure.com/dnceng/internal/_git/dotnet-wpf-int
    
    Before running this script, a clone of one of these repos must have been built using "build -pack" first.
    

PARAMETERS
    -Configuration <String>
        The build-configuration of the binaries to copy. 
        Valid values of 'Debug' (Default) and 'Release'.
        
    -Platform <String>
        The build-platform of the binaries to copy. 
        Valid values are 'x86' (Default) and 'x64'
        'AnyCPU' or 'Any CPU' can also be specified in lieu of 'x86'
        
    -RepoRoot <String[]>
        The root of the repository clone from which to copy binaries. This is typically specified in the form 'C:\src\repos\wpf', and the built binaries are 
        expected to be found under 'artifacts\packaging' folder. More than one repository can be specified by separating it with commas
        
    -Destination <String>
        The destination folder where the binaries are to be copied. This will be created if it doesn't exist.
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS>> CopyWpfBins.ps1 -RepoRoot C:\src\repos\wpf -Destination C:\temp\wpfbins
    
    Copies Debug/x86 binaries from C:\src\repos\wpf\ to C:\temp\wpfbins. The binaries will be searched for under two locations - 
        i. C:\src\repos\wpf\artifacts\packaging\Debug\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        ii. C:\src\repos\wpf\artifacts\packaging\Debug\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x86\native
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS>> CopyWpfBins.ps1 -RepoRoot C:\src\repos\wpf -Destination C:\temp\wpfbins -Configuration Release -Platform x64
    
    Copies Release/x64 binaries from C:\src\repos\wpf\ to C:\temp\wpfbins. The binaries will be searched for under two locations - 
        i. C:\src\repos\wpf\artifacts\packaging\Release\x64\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        ii. C:\src\repos\wpf\artifacts\packaging\Release\x64\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x64\native
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS>> CopyWpfBins.ps1 -RepoRoot C:\src\repos\wpf,C:\src\repos\dotnet-wpf-int -Destination C:\temp\wpfbins -Platform x64
    
    Copies Debug/x64 binaries from two repos, C:\src\repos\wpf\ and C:\src\repos\dotnet-wpf-int, into C:\temp\wpfbins. The binaries will be searched for 
    under the following locations - 
        i.   C:\src\repos\wpf\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        ii.  C:\src\repos\wpf\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x64\native
        iii. C:\src\repos\dotnet-wpf-int\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        iv.  C:\src\repos\dotnet-wpf-int\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x64\native
    
    
    
    
REMARKS
    To see the examples, type: "get-help CopyWpfBins.ps1 -examples".
    For more information, type: "get-help CopyWpfBins.ps1 -detailed".
    For technical information, type: "get-help CopyWpfBins.ps1 -full".
```