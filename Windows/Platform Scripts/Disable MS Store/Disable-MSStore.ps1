## The options to disable the Microsoft Store in Intune are limited to Windows Enterprise. This script will allow you to disable the Microsoft Store on Windows 10 Pro/Business.

Write-Host "Requiring Private Store Only"

$store = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"

If (!(Test-Path $store)) {

New-Item $store

}

Set-ItemProperty $store RequirePrivateStoreOnly -Value 1