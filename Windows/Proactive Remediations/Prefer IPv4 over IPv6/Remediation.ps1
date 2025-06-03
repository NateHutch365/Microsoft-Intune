$Path = "HKLM:\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
$Name = "DisabledComponents"
$Type = "DWORD"
$Value = 0x20


New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -ErrorAction SilentlyContinue
Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -ErrorAction SilentlyContinue