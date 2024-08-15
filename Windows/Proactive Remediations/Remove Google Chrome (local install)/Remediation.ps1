# Google Chrome AppData install detection and removal script

# For the remediation script settings, run this script using the logged-on credentials = True / Enforce script sig check = False / Run script in 64-bit PowerShell = False

# $Chrome = Get-ChildItem -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match $($AppName)}
# $Chrome.UninstallString

$chromeInstalled = (Get-Item (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue).'(Default)').VersionInfo
$ChromeVersion = $chromeInstalled.ProductVersion

$Installer = "$env:LOCALAPPDATA\Google\Chrome\Application\$ChromeVersion\Installer\setup.exe"
$Arguements = "--uninstall --force-uninstall"

# Debug output
Write-Output $chromeInstalled
Write-Output $ChromeVersion
Write-Output $Installer
Write-Output $Arguements

# Execute
Start-Process $Installer $Arguements -Wait