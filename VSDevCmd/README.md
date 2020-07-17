# Visual Studio Developer Commmnd Prompt Launchers

## Overview

`VSDevCmd.ps1` (and `VSDevCmd.cmd`) can launch arbitrary programs that are usually only available inside the *Visual Studio Developer Command Prompt* Environment. 

These are inspired by `powershell -Command` functionality that enables any powershell command or script to be invoked directly without having to enter the PowerShell CLI environment. 

`MSBuild.ps1` (and `msbuild.cmd`) are special purpose wrappers around `VSDevCmd.ps1` intended to launch `msbuild.exe`. 

All the logic is in the reusable `VSDevCmd.psm1` module.

## VSDevCmd.ps1

```
NAME
    VSDevCmd.ps1
    
SYNOPSIS
    Runs a Build Command in VS Developer Command Prompt environment
    
    
SYNTAX
    VSDevCmd.ps1 [-Command] <String> [[-Arguments] <String[]>] [<CommonParameters>]
    
    
DESCRIPTION
    Runs a commands in VS Developer Command Prompt Environment
    

PARAMETERS
    -Command <String>
        Command to run

    -Arguments <String[]>

    -------------------------- EXAMPLE 1 --------------------------

    PS C:\>.\VSDevCmd.ps1 msbuild /?

    Runs 'msbuild /?'
```

## MSBuild.ps1

```

NAME
    msbuild.ps1
    
SYNOPSIS
    Launches msbuild
    
    
SYNTAX
    msbuild.ps1 [[-Arguments] <String[]>] [<CommonParameters>]
    
    
DESCRIPTION
    Queries the environment for installed versions of Visual Studio, and dynamically launches msbuild within a VS Developer Command Prompt-like environment with the supplied arguments


PARAMETERS
    -Arguments <String[]>
        List of arguments to pass to msbuild

    -------------------------- EXAMPLE 1 --------------------------

    PS > .\msbuild.ps1 Foo.proj /bl
    Builds project 'Foo.proj' and produces and binary-log

    -------------------------- EXAMPLE 2 --------------------------

    PS > .\msbuild.ps1 /?
    Shows commandline help for msbuild.exe
```