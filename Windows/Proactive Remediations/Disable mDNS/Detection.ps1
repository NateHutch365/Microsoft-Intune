$Reg = Get-ItemProperty -Path 'HKLM:\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name "EnableMDNS" -ErrorAction SilentlyContinue
if ($Reg -eq $Null){

    Write-host "IPv6 prefix reg is not identified "
    Exit 1
}
else {
    Write-Host "IPv6 prefix is identified"
    Exit 0
}