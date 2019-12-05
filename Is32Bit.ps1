Add-Type -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true, CallingConvention = CallingConvention.Winapi)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool IsWow64Process(
    [In] System.IntPtr hProcess,
    [Out, MarshalAs(UnmanagedType.Bool)] out bool wow64Process);
'@ -Name NativeMethods -Namespace Kernel32


Function Is32BitProcess {
    [CmdletBinding(DefaultParameterSetName='ByProcessObject', PositionalBinding=$true)]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='ByProcessObject')]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory=$true, ParameterSetName='ByProcessId')]
        [int]$Id
    )

    if ($PSCmdlet.ParameterSetName -ieq 'ByProcessId') {
        $Process = Get-Process -Id $Id 
    }

    $is32Bit=[int]0 
    if ($Process.Handle -and [Kernel32.NativeMethods]::IsWow64Process($Process.Handle, [ref]$is32Bit)) { 
        return $is32Bit
    } 
    else {
        Write-Error "Is32BitProcess: IsWow64Process call failed"
    }
}

