<#
.SYNOPSIS
    Uninstalls Symantec Endpoint Protection (SEP) from local machine.
    
.DESCRIPTION
    Script Name: Uninstall-SEP.ps1
    Version: 1.0
    Creator: Nathan Hutchinson
    Website: natehutchinson.co.uk
    GitHub: https://github.com/NateHutch365
    
    This script automates the uninstallation of Symantec Endpoint Protection (SEP) and logs the results
    to a file. It can be deployed as a platform script in Microsoft Intune.
    
.NOTES
    Intune Deployment Configuration:
    - Run this script using logged on credentials: No
    - Enforce script signature check: No
    - Run script in 64 bit PowerShell Host: No
    
    Prerequisites:
    - Tamper Protection must be disabled via SEPM policy before deployment
    - Password Protection must be disabled via SEPM policy before deployment
#>

# Define the name of the product to uninstall
$productName = "Symantec Endpoint Protection"

# Get the local computer name
$computerName = $env:COMPUTERNAME

# Define the output file path
$outputFile = "C:\Temp\UninstallResults.txt"

# Ensure the directory exists
$outputDirectory = [System.IO.Path]::GetDirectoryName($outputFile)
if (!(Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Initialize the result message
$resultMessage = ""

# Attempt to find Symantec Endpoint Protection package(s) on the local computer
$sepPackages = Get-Package -Name $productName -ErrorAction SilentlyContinue

if ($sepPackages) {
    # Uninstall Symantec Endpoint Protection on the local computer
    foreach ($sepPackage in $sepPackages) {
        $uninstallResult = $sepPackage | Uninstall-Package -Force

        if ($uninstallResult) {
            $resultMessage = "$computerName - $productName - Successfully uninstalled"
        } else {
            $errorCode = $LASTEXITCODE

            if ($errorCode -eq 3010) {
                $resultMessage = "$computerName - $productName - Uninstallation completed with exit code 3010 (Reboot required)"
            } else {
                $resultMessage = "$computerName - $productName - Failed to uninstall with exit code $errorCode"
            }
        }

        # Write the result to the output file
        $resultMessage | Out-File -FilePath $outputFile -Append
    }
} else {
    $resultMessage = "$computerName - $productName - Not found"
    $resultMessage | Out-File -FilePath $outputFile -Append
}

# Notify the user
Write-Host "Uninstall results have been saved to $outputFile"