A malicious actor can exploit the default IPv6 setup to establish their IP address as the default IPv6 server, respond to DHCPv6 broadcasts from domain hosts, and assign IPv6 configurations. Consequently, DNS requests are directed to the attacker’s machine. This enables the attacker to intercept traffic, seize hashes, and/or relay the captured data to susceptible SMB servers. This setup can be combined with older protocols like LLMNR/NetBIOS to generate extra traffic and seize confidential data, including password hashes. Microsoft recommend preferring IPv4 over IPv6 rather than disabling IPv6 due to some Windows components depending on it.

Source: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows
Source: https://cloudbymoe.com/f/add-extra-layers-of-security-to-your-endpoint-using-intune

Run this script using the logged-on credentials: No
Enforce script signature check: No
Run script in 64-bit PowerShell: No