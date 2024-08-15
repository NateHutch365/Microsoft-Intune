# Restore Original Digital License for Windows Script

## Overview
This PowerShell script is designed to help restore the original digital license on Windows machines that were incorrectly activated using a Generic Volume License Key (GVLK). It is particularly useful in environments where machines were initially activated with a digital license but later reactivated using volume licensing.

## Usage
The script checks if the Windows activation uses a GVLK. If it does, the script retrieves the original digital license key embedded in the system's firmware and reactivates Windows using this original key.

### Prerequisites
- PowerShell 5.0 or higher
- Administrative rights on the system

### Intune
1. Create new Windows platform script
2. Upload RestoreOriginalDigitalLicense.ps1
3. Script settings should be:
- Run this script using the logged on credentials: No
- Enforce script signature check: No
- Run script in 64 bit PowerShell Host: No
4. Assign to device group

### Running the Script
1. Open PowerShell as an Administrator.
2. Navigate to the directory containing the script.
3. Run the script by entering:
   ```powershell
   .\RestoreOriginalDigitalLicense.ps1
