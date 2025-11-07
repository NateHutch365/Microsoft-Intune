The Global Secure Access client does not currently support DNS port 53 TCP in the browser: https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations?tabs=windows-client 

This script, dpeloyed as a Win32 app will disable the broswers DNS client via registry values:

Microsoft Edge
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge] "BuiltInDnsClientEnabled"=dword:00000000
Chrome
[HKEY_CURRENT_USER\Software\Policies\Google\Chrome] "BuiltInDnsClientEnabled"=dword:00000000

The Global Secure Access client does not currently support traffic acquisition for destinations with IPv6 addresses: https://learn.microsoft.com/en-us/entra/global-secure-access/troubleshoot-global-secure-access-client-diagnostics-health-check#ipv4-preferred

This script, deployed as a Win32 app will configure the client to prefer IPv4 over IPv6 via the following registry key:

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\ Name: DisabledComponents Type: REG_DWORD Value: 0x20 (Hex)

> [!IMPORTANT]
> A device reboot is required to finalise this configuration change. This script does not reboot the device. You may wish to amend the script or do using Intune.

Administrators can prevent nonprivileged users on the Windows device from disabling or enabling the client by setting the following registry key:

HKEY_LOCAL_MACHINE\Software\Microsoft\Global Secure Access Client
RestrictNonPrivilegedUsers REG_DWORD
Value: 1

More info: https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-install-windows-client#restrict-nonprivileged-users 