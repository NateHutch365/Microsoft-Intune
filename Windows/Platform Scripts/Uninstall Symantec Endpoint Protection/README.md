# Uninstall-SEP.ps1

A PowerShell script to automate the uninstallation of Symantec Endpoint Protection (SEP) from local machines. This script can be deployed via Microsoft Intune as a platform script.

## Author
- **Created by:** Nathan Hutchinson
- **Website:** [natehutchinson.co.uk](https://natehutchinson.co.uk)
- **GitHub:** [github.com/NateHutch365](https://github.com/NateHutch365)

## Version
1.0

## Description
This script automates the process of uninstalling Symantec Endpoint Protection from local machines. It includes logging functionality to track the success or failure of the uninstallation process.

## Prerequisites
Before deploying this script, ensure the following conditions are met:
- Tamper Protection must be disabled via SEPM policy
- Password Protection must be disabled via SEPM policy

## Intune Deployment Configuration
Configure the following settings when deploying as a platform script in Intune:
- Run this script using logged on credentials: No
- Enforce script signature check: No
- Run script in 64 bit PowerShell Host: No

## Features
- Automatically detects and uninstalls Symantec Endpoint Protection
- Creates detailed logs in C:\Temp\UninstallResults.txt
- Handles multiple instances of SEP if present
- Provides status messages for successful uninstallation, pending reboots, and failures

## Log File
The script creates a log file at `C:\Temp\UninstallResults.txt` containing:
- Computer name
- Uninstallation status
- Error codes (if any)

## Exit Codes
- Success: Indicated in log file
- 3010: Uninstallation successful, reboot required
- Other: Uninstallation failed with specific error code

## Support
For issues, questions, or contributions, please visit the GitHub repository at [github.com/NateHutch365](https://github.com/NateHutch365)