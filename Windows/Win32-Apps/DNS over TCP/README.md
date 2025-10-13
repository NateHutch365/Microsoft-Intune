The Globa Secure Access client does not currently support DNS port 53 TCP in the browser: https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations?tabs=windows-client 

This script, dpeloyed as a Win32 app will disable the broswers DNS client via registry values:

Microsoft Edge
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge] "BuiltInDnsClientEnabled"=dword:00000000
Chrome
[HKEY_CURRENT_USER\Software\Policies\Google\Chrome] "BuiltInDnsClientEnabled"=dword:00000000