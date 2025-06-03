$Path = "HKLM:\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
$Name = "EnableMDNS"
$Type = "DWORD"
$Value = 0


New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -ErrorAction SilentlyContinue

Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -ErrorAction SilentlyContinue