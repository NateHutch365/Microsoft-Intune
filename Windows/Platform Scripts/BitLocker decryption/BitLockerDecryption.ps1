# BitLocker Decryption Script
# Version: 1.0
# Creator: Nathan Hutchinson
# Website: natehutchinson.co.uk
# GitHub: https://github.com/NateHutch365

# Description: This script decrypts all BitLocker encrypted drives on the system.
# It iterates through each drive, checks its encryption status, and attempts to
# decrypt any fully encrypted or encrypting drives. The script provides feedback
# on the decryption process for each drive.

# WARNING: This script will attempt to decrypt all BitLocker-encrypted drives on the system.
# Use with caution as it may compromise the security of sensitive data if used inappropriately.

# This script will decrypt all BitLocker encrypted drives on the system

# Check for BitLocker status and decrypt drives
$drives = Get-BitLockerVolume

foreach ($drive in $drives) {
    if ($drive.VolumeStatus -eq 'FullyEncrypted' -or $drive.VolumeStatus -eq 'EncryptionInProgress') {
        Try {
            Write-Output "Decrypting drive $($drive.MountPoint)"
            Disable-BitLocker -MountPoint $drive.MountPoint -ErrorAction Stop
        } Catch {
            Write-Output "Could not initiate decryption on drive $($drive.MountPoint). It may not be encrypted or another error occurred."
        }
    } else {
        Write-Output "Drive $($drive.MountPoint) is not encrypted."
    }
}

Write-Output "Decryption process completed for all BitLocker encrypted drives."