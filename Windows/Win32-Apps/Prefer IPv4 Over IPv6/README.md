The Global Secure Access client does not currently support traffic acquisition for destinations with IPv6 addresses: https://learn.microsoft.com/en-us/entra/global-secure-access/troubleshoot-global-secure-access-client-diagnostics-health-check#ipv4-preferred

This script, deployed as a Win32 app will configure the client to prefer IPv4 over IPv6 via the following registry key:

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\ Name: DisabledComponents Type: REG_DWORD Value: 0x20 (Hex)

> [!IMPORTANT]
> A device reboot is required to finalise this configuration change. This script does not reboot the device. You may wish to amend the script or do using Intune.