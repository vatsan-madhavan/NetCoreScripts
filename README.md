# .NET Core Helper Scripts

Assortment of useful scripts for use with .NET Core SDK 

## EnsureGlobalJsonSDKs 
[EnsureGlobalJsonSdks.ps1](EnsureGlobalJsonSdks/) is a powershell script that can download and install a .NET Core SDK specified in global.json. 

This is useful in Azure Pipelines to ensure that the right version of .NET Core is avaialble for builds. 

Ths is better than the ['Use .NET Core' task](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/tool/dotnet-core-tool-installer?view=azure-devops) because it supports daily builds from [dotnet/core-sdk](https://github.com/dotnet/core-sdk)

## GetFrameworkVersions

[Get-FrameworkVersions.ps1](GetFrameworkVersions/) gets the versions of shared-frameworks (Microsoft.NetCore.App, Microsoft.AspNetCore.App, Microsoft.WindowsDeskto.App) associated with a .NET Core SDK. 

## Install-Latest-DotNetCore

[Install-Latest-DotnetCore.ps1](InstallLatestDotnetCore/) is a wrapper around [dotnet-install.ps1](https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script) and makes it easy to install the "latest" daily .NET Core builds or a specific version of .NET Core to Program Files folder without leaving crumbs behing in ARP (Add-Remove Programs) in Windows. 

## CopyWpfBins

[CopyWpfBins.ps1](CopyWpfBins/) is a handy script used to copy locally built WPF binaries from a clone/enlistment of https://github.com/dotnet/wpf to any target folder. 

This is especially useful for updating a copy of the WindowsDesktop shared-framework with privately built WPF binaries, or updating a self-contained application used for testing with priate binaries. 