<# 
.SYNOPSIS 
   Allows you to set the backgroup on a Windows 10 device that isn't just Windows 10 Enterprise using Microsoft Intune
 
.DESCRIPTION 
   This script set background image using Microsoft Intune SideCar/Client PowerShell feature.
   
   For what every reason Microsoft has restricted the Microsoft Intune CSP setting "DesktopImageUrl"
   to Windows 10 Enterprise. The setting was introduced as part of the Personalization CSP in Windows 10 version 1703.
   Several of my customers have enterprise edition but I also have some that only have Windows 10 Pro.

   Some of the customers that have Windows 10 Enterprise, but upgrades from Windows 10 Pro as part of the Windows 10 Enterprise E3
   license see that the background policy doesn't apply as expected or sporadic. I'm not sure whether this is 
   caused by a conflict or the fact that the "DesktopImageUrl" setting doesn't get re-applied after the upgrade 
   I am not sure. It does not seems to work as the customers expect, which should be the goal of this property.

   For more information about the Windows 10 personalization CSP policy see this article: 
   https://docs.microsoft.com/da-dk/windows/client-management/mdm/personalization-csp
        
.NOTES 
    Author: Peter Selch Dahl from APENTO ApS 
    Website: http://www.APENTO.com
    Last Updated: 11/17/2018
    Version 1.0

    #DISCLAIMER
    The script is provided AS IS without warranty of any kind.

#> 

#Open the folder en Windows Explorer under C:\Users\USERNAME\AppData\Roaming\CustomerXXXX
########################################################################################
$path = [Environment]::GetFolderPath('ApplicationData') + "\CustomerXXXX"

If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}
########################################################################################


#Download the image from ImGur to user profile
########################################################################################
$url = "https://i.imgur.com/DdaILj9.png"
$output = $path + "\CustomerBackground.png"
Start-BitsTransfer -Source $url -Destination $output

########################################################################################



# Update the background of the desktop
########################################################################################
Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value $output

rundll32.exe user32.dll, UpdatePerUserSystemParameters


########################################################################################
