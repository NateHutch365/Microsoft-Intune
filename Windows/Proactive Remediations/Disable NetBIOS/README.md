Legacy DNS protocols such as Link-Local Multicast Name Resolution (LLMNR) and NBT-NS (NetBIOS) broadcast name resolution requests across the entire subnet to locate resources. These queries do not perform any integrity checks on the responses, which makes them susceptible to adversary-in-the-middle  LLMNR/NetBIOS poisoning and SMB relay. To protect endpoints from this attack vector, these legacy protocols should be disabled.

Source: https://cloudbymoe.com/f/add-extra-layers-of-security-to-your-endpoint-using-intune

Run this script using the logged-on credentials: No
Enforce script signature check: No
Run script in 64-bit PowerShell: No