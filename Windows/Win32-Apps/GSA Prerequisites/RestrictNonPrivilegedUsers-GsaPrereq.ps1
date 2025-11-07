<#
.SYNOPSIS
  Sets or removes the RestrictNonPrivilegedUsers registry value for the Global Secure Access Client.

.DESCRIPTION
Creates or sets the following registry value:
                 HKLM\Software\Microsoft\Global Secure Access Client
                 RestrictNonPrivilegedUsers (DWORD) = 1
-Install command: %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\RestrictNonPrivilegedUsers-GsaPrereq.ps1 -Install
  -Uninstall command: %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\RestrictNonPrivilegedUsers-GsaPrereq.ps1 -Uninstall
  -Detectection Rule Type: File
  -Detection Path: %ProgramData%\Microsoft\IntuneManagementExtension\Logs\
  -Detection File or Folder: App-RestrictNonPrivilgedUsers-GSA.log
  -Detection Method: File or folder exists
  -Associated with 32-bit: No 

LOGGING
  Appends transcript to:
    %ProgramData%\Microsoft\IntuneManagementExtension\Logs\App-RestrictNonPrivilgedUsers-GSA.log
  Final line includes: RESULT: SUCCESS | FAILURE with a reason.

.NOTES
  Author: Nate Hutchinson
  Version: 1.0
  Release Date: 13/10/2025
#>

[CmdletBinding()]
param(
  [switch]$Install,
  [switch]$Uninstall,
  [switch]$Detect
)

# --- Constants & Paths ---
$LogsFolder = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs'
$MainLog    = Join-Path $LogsFolder 'App-RestrictNonPrivilgedUsers-GSA.log'

# Registry info
$RegPath  = 'HKLM:\Software\Microsoft\Global Secure Access Client'
$RegName  = 'RestrictNonPrivilegedUsers'
$RegValue = [uint32]1

# --- Ensure log folder exists ---
if (-not (Test-Path -LiteralPath $LogsFolder)) {
  New-Item -Path $LogsFolder -ItemType Directory -Force | Out-Null
}

# --- Start transcript ---
try {
  Start-Transcript -Path $MainLog -Append -ErrorAction Stop
  Write-Host "[RestrictNonPrivilegedUsers-GSA] $(Get-Date -Format u) - Starting"
} catch {
  Write-Warning "Transcript start failed: $($_.Exception.Message)"
}

function Write-Info([string]$Message) { Write-Host    "[INFO]  $Message" }
function Write-Warn([string]$Message) { Write-Warning "[WARN]  $Message" }
function Write-Err ([string]$Message) { Write-Error   "[ERROR] $Message" }

# ---------- Registry Helpers ----------
function Test-RestrictValue {
  try {
    $val = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue).$RegName
    return ($val -eq $RegValue)
  } catch { return $false }
}

function Set-RestrictValue {
  try {
    if (-not (Test-Path -Path $RegPath)) {
      New-Item -Path $RegPath -Force | Out-Null
      Write-Info "Created registry path: $RegPath"
    }
    New-ItemProperty -Path $RegPath -Name $RegName -PropertyType DWord -Value $RegValue -Force | Out-Null
    Write-Info "$RegPath\$RegName set to $RegValue"
    return $true
  } catch {
    Write-Err "Failed to set registry value: $($_.Exception.Message)"
    return $false
  }
}

function Remove-RestrictValue {
  try {
    if (Test-Path -Path $RegPath) {
      Remove-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue
      Write-Info "$RegPath\$RegName removed"
    }
    return $true
  } catch {
    Write-Err "Failed to remove registry value: $($_.Exception.Message)"
    return $false
  }
}

# ---------- Flow ----------
$exitCode = 1

try {
  if ($Detect) {
    if (Test-RestrictValue) {
      Write-Info "DETECT: RestrictNonPrivilegedUsers = 1"
      Write-Host "RESULT: SUCCESS - Value exists and equals 1."
      $exitCode = 0
    } else {
      Write-Warn "DETECT: Value missing or not 1."
      Write-Host "RESULT: FAILURE - Value missing or incorrect."
      $exitCode = 1
    }
  }
  elseif ($Install) {
    Write-Info "INSTALL: Setting RestrictNonPrivilegedUsers = 1"
    if (Set-RestrictValue) {
      Write-Host "RESULT: SUCCESS - Value applied."
      $exitCode = 0
    } else {
      Write-Host "RESULT: FAILURE - Unable to set value."
      $exitCode = 1
    }
  }
  elseif ($Uninstall) {
    Write-Info "UNINSTALL: Removing RestrictNonPrivilegedUsers"
    if (Remove-RestrictValue) {
      Write-Host "RESULT: SUCCESS - Value removed."
      $exitCode = 0
    } else {
      Write-Host "RESULT: FAILURE - Unable to remove value."
      $exitCode = 1
    }
  }
  else {
    Write-Warn "No switch provided. Use -Install, -Uninstall, or -Detect."
    Write-Host "RESULT: FAILURE - No action specified."
    $exitCode = 1
  }
}
catch {
  Write-Err "Unhandled exception: $($_.Exception.Message)"
  Write-Host "RESULT: FAILURE - Unhandled exception."
  $exitCode = 1
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
  if ($exitCode -eq 0) { Write-Host "SUCCESS: Operation complete." }
  else { Write-Host "FAILURE: Operation failed." }
  exit $exitCode
}
