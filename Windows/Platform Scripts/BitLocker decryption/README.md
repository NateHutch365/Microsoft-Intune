# BitLocker Decryption Script

## Version: 1.0

## Creator: Nathan Hutchinson
- Website: [natehutchinson.co.uk](https://natehutchinson.co.uk)
- GitHub: [NateHutch365](https://github.com/NateHutch365)

## Description

This PowerShell script is designed to decrypt all BitLocker-encrypted drives on a Windows system. It automates the process of identifying encrypted volumes and initiating their decryption. Useful if switching from one Intune encrpytion policy to another where changes to encryption type/method have been updated.

## Features

- Identifies all BitLocker-encrypted volumes on the system
- Attempts to decrypt fully encrypted or encrypting drives
- Provides feedback on the decryption process for each drive

## Warning

**CAUTION**: This script will attempt to decrypt all BitLocker-encrypted drives on the system. Use with extreme caution as it may compromise the security of sensitive data if used inappropriately.

## Prerequisites

- Windows operating system
- PowerShell
- Administrative privileges (required to manage BitLocker)

## Usage (local)

1. Open PowerShell as an Administrator
2. Navigate to the directory containing the script
3. Run the script:
   ```
   .\BitLockerDecryptionScript.ps1
   ```

## Usage (Intune)

1. Create new Windows platform script
2. Upload BitLockerDecryption.ps1
3. Script settings should be:
- Run this script using the logged on credentials: No
- Enforce script signature check: No
- Run script in 64 bit PowerShell Host: No
4. Assign to device group

## How It Works

1. The script uses `Get-BitLockerVolume` to retrieve information about all BitLocker volumes on the system.
2. It iterates through each drive:
   - If a drive is fully encrypted or in the process of being encrypted, the script attempts to decrypt it using `Disable-BitLocker`.
   - The script provides feedback on whether decryption was initiated successfully or if any errors occurred.
   - For drives that are not encrypted, it simply notes their status.
3. After attempting to decrypt all drives, it outputs a completion message.

## Output

The script will output messages to the console indicating:
- Which drives are being decrypted
- Any errors encountered during the decryption process
- Drives that are not encrypted
- A completion message when the process is finished

## Disclaimer

This script is provided as-is, without any warranties or guarantees. The creator is not responsible for any data loss or security breaches that may occur as a result of using this script. Always ensure you have proper backups and authorization before modifying the encryption status of any drives.

## License

[Specify the license here, e.g., MIT, GPL, etc.]

## Contributing

If you'd like to contribute to this project, please fork the repository and submit a pull request.