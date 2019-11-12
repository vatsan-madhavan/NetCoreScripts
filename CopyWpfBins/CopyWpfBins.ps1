<#
.SYNOPSIS
    Copies built binaries from a WPF repo to a specified destination. 
.DESCRIPTION
    Copies built binaries from a WPF repo to a specified destination. 
    
    Supported WPF repos are:
        https://github.com/dotnet/wpf 
        https://dev.azure.com/dnceng/internal/_git/dotnet-wpf-int
    
    Before running this script, a clone of one of these repos must have been built using "build -pack" first. 
.PARAMETER Configuration
    The build-configuration of the binaries to copy. 
    Valid values of 'Debug' (Default) and 'Release'. 
.PARAMETER Platform
    The build-platform of the binaries to copy. 
    Valid values are 'x86' (Default) and 'x64'
    'AnyCPU' or 'Any CPU' can also be specified in lieu of 'x86'
.PARAMETER RepoRoot
    The root of the repository clone from which to copy binaries. This is typically specified in the form 'C:\src\repos\wpf', and the built binaries are expected to be found under 'artifacts\packaging' folder. More than one repository can be specified by separating it with commas
.PARAMETER Destination
    The destination folder where the binaries are to be copied. This will be created if it doesn't exist. 
.EXAMPLE
    PS>> CopyWpfBins.ps1 -RepoRoot C:\src\repos\wpf -Destination C:\temp\wpfbins
    
    Copies Debug/x86 binaries from C:\src\repos\wpf\ to C:\temp\wpfbins. The binaries will be searched for under two locations - 
        i. C:\src\repos\wpf\artifacts\packaging\Debug\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        ii. C:\src\repos\wpf\artifacts\packaging\Debug\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x86\native 
.EXAMPLE
    PS>> CopyWpfBins.ps1 -RepoRoot C:\src\repos\wpf -Destination C:\temp\wpfbins -Configuration Release -Platform x64
    
    Copies Release/x64 binaries from C:\src\repos\wpf\ to C:\temp\wpfbins. The binaries will be searched for under two locations - 
        i. C:\src\repos\wpf\artifacts\packaging\Release\x64\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        ii. C:\src\repos\wpf\artifacts\packaging\Release\x64\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x64\native
.EXAMPLE
    PS>> CopyWpfBins.ps1 -RepoRoot C:\src\repos\wpf,C:\src\repos\dotnet-wpf-int -Destination C:\temp\wpfbins -Platform x64
    
    Copies Debug/x64 binaries from two repos, C:\src\repos\wpf\ and C:\src\repos\dotnet-wpf-int, into C:\temp\wpfbins. The binaries will be searched for under the following locations - 
        i.   C:\src\repos\wpf\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        ii.  C:\src\repos\wpf\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x64\native
        iii. C:\src\repos\dotnet-wpf-int\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.GitHub\lib\netcoreapp*
        iv.  C:\src\repos\dotnet-wpf-int\artifacts\packaging\Debug\x64\Microsoft.DotNet.Wpf.DncEng\runtimes\win-x64\native
#>
param(
  [string][Alias('c')]
  [Parameter(HelpMessage='Release or Debug')]
  [ValidateSet('Release', 'Debug', IgnoreCase=$true)]
  $Configuration = 'Debug',
  
  [string][Alias('p')]
  [Parameter(HelpMessage='x86 or x64')]
  [ValidateSet('x86', 'x64', 'AnyCPU', 'Any CPU', IgnoreCase=$true)]
  $Platform = 'x86',
   
  [string[]][Alias('r')]
  [Parameter(HelpMessage='Root of one or more repositories, separated by commas', Mandatory=$true)]
  [ValidateScript({
    $exists = $true
    $_ | % { 
      if (-not (Test-Path $_)) {
        $exists = $false
        Write-Warning "$_ doesn't exist"
      }
    }

    $exists
  })]
  $RepoRoot,

  [string][Alias('d')]
  [Parameter(HelpMessage='Destination Directory', Mandatory=$true)]
  [ValidateScript({
    if (-not (Test-Path $_)) {
        Write-Verbose "$_ doesn't exist - creating..."
        New-Item -ItemType Directory -Path $_
    }

    Test-Path $_
  })]
  $Destination
)

Function Write-ErrorMessage {
      [CmdletBinding(DefaultParameterSetName='ErrorMessage')]
      param(
           [Parameter(Position=0,ParameterSetName='ErrorMessage',ValueFromPipeline,Mandatory)][string]$errorMessage
           ,[Parameter(ParameterSetName='ErrorRecord',ValueFromPipeline)][System.Management.Automation.ErrorRecord]$errorRecord
           ,[Parameter(ParameterSetName='Exception',ValueFromPipeline)][Exception]$exception
      )

      switch($PsCmdlet.ParameterSetName) {
          'ErrorMessage' {
               if (-not $errorMessage.StartsWith("ERROR: ")) {
                $errorMessage = "ERROR: "  + $errorMessage
               }
               $err = $errorMessage
          }
          'ErrorRecord' {
               $errorMessage = @($error)[0]
               $err = $errorRecord
          }
          'Exception'   {
               $errorMessage = $exception.Message
               $err = $exception
          }
      }

      Write-Error -Message $err -ErrorAction SilentlyContinue
      $Host.UI.WriteErrorLine($errorMessage)
}


Function Copy-Binaries {
    param(
        [string]$RepoRoot,
        [string]$Destination,
        [string]$Configuration,
        [string]$Platform
    )
    Write-Verbose "Repo Root: $RepoRoot"
    $basePath = Join-Path $RepoRoot "artifacts\packaging\$Configuration"
    if ($Platform -eq 'x64') {
        $basePath = Join-Path $basePath $Platform
    }

    Write-Verbose "Source: $basePath"

    if (-not (Test-Path $basePath)) {
        Write-ErrorMessage "$basePath doesn't exist - cannot copy files"
        exit
    }

    [bool]$success = $false 

    Get-ChildItem -Directory -Filter Microsoft.DotNet.Wpf.* -Path $basePath | Where-Object {
        $_.Name -ieq 'Microsoft.DotNet.Wpf.GitHub' -or $_.Name -ieq 'Microsoft.DotNet.Wpf.DncEng'
    } | % {
        Get-ChildItem -Directory $_.FullName
    } | ? {
        $_.Name -ieq 'lib' -or $_.Name -ieq 'runtimes'
    } | % {
        Get-ChildItem -Directory $_.FullName
    } | ? {
        $_.Name -ieq "win-$Platform" -or $_.Name -ilike "netcoreapp*"
    } | % {
        if ($_.Name -ilike "netcoreapp*") {
            Get-ChildItem -Path $_.FullName | % {
                $source = $_.FullName
                Write-Verbose "Copy-Item $source $Destination -Recurse -Force"
                Copy-Item $source $Destination -Recurse -Force
                $success = $true 
            }
        } else { 
            <# win-$Platform$#>
            Get-ChildItem -Directory $_.FullName | ? {
                $_.Name -ieq "native"
            } | % {
                Get-ChildItem -Path $_.FullName | % {
                    $source = $_.FullName
                    Write-Verbose "Copy-Item $source $Destination -Recurse -Force"
                    Copy-Item $source $Destination -Recurse -Force
                    $success = $true 
                }
            }
        }
    }

    if (-not $success) {
        Write-Warning "Failed to copy any files - no files were found"
    }
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

Write-Verbose "Destination: $Destination"
$Platform = Fixup-AnyCPU -Platform $Platform

$RepoRoot | % {
    Copy-Binaries -RepoRoot $_ -Destination $Destination -Configuration $Configuration -Platform $Platform
}
