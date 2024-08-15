# Script to Check and Restore Original Digital License for Windows
# This script checks if a Windows system is activated with a Generic Volume License Key (GVLK).
# If so, it retrieves and installs the original digital license from the system's firmware.
# Source: https://sccmentor.com/2022/09/14/we-cant-activate-windows-on-this-device-an-intune-solution-to-windows-not-activated/

$CheckForGVLK = Get-WmiObject SoftwareLicensingProduct -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f' and LicenseStatus = '5'"
$CheckForGVLK = $CheckForGVLK.ProductKeyChannel

if ($CheckForGVLK -eq 'Volume:GVLK'){
    $GetDigitalLicence = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
    cscript c:\windows\system32\slmgr.vbs -ipk $GetDigitalLicence
}
