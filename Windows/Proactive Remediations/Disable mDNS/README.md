While mDNS is useful for local network environments, it poses potential security risks due to its lack of authentication and encryption. On Windows devices, mDNS can be susceptible to spoofing, information leakage, and DoS attacks, particularly if an attacker has access to the local network. If mDNS is not required, disabling it is generally recommended. However, if it must be used, it’s important to secure the network through segmentation, firewall policies, and regular patching to mitigate these risks.

Source: https://cloudbymoe.com/f/add-extra-layers-of-security-to-your-endpoint-using-intune
Source: https://f20.be/blog/mdns

Run this script using the logged-on credentials: No
Enforce script signature check: No
Run script in 64-bit PowerShell: No