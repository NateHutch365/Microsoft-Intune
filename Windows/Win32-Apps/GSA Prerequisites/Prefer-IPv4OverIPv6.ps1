<#
.SYNOPSIS
  Prefer IPv4 over IPv6 (sets the 0x20 bit on DisabledComponents).

.DESCRIPTION
  -Install command: %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\Prefer-IPv4OverIPv6.ps1 -Install
  -Uninstall command: %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\Prefer-IPv4OverIPv6.ps1 -Uninstall
  -Detectection Rule Type: File
  -Detection Path: %ProgramData%\Microsoft\IntuneManagementExtension\Logs\
  -Detection File or Folder: App-PreferIPv4OverIPv4.log
  -Detection Method: File or folder exists
  -Associated with 32-bit: No 

  Logs to: %ProgramData%\Microsoft\IntuneManagementExtension\Logs\App-PreferIPv4OverIPv4.log
  Final line includes: RESULT: SUCCESS | FAILURE with reason.

.NOTES
  A reboot is generally required for full effect.
#>

[CmdletBinding()]
param(
  [switch]$Install,
  [switch]$Uninstall,
  [switch]$Detect
)

# --- Constants & Paths ---
$LogsFolder = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs'
$MainLog    = Join-Path $LogsFolder 'App-PreferIPv4OverIPv4.log'

# Registry info
$RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
$RegName = 'DisabledComponents'
# Prefer IPv4 bit (per Microsoft doc): 0x20 (decimal 32)
$PreferIPv4Bit = 0x20

# --- Ensure log folder exists ---
if (-not (Test-Path -LiteralPath $LogsFolder)) {
  New-Item -Path $LogsFolder -ItemType Directory -Force | Out-Null
}

# --- Start transcript (append for cumulative history) ---
try {
  Start-Transcript -Path $MainLog -Append -ErrorAction Stop
  Write-Host "[Prefer-IPv4OverIPv6] $(Get-Date -Format u) - Starting"
} catch {
  Write-Warning "Transcript start failed: $($_.Exception.Message)"
}

function Write-Info([string]$Message) { Write-Host "[INFO]  $Message" }
function Write-Warn([string]$Message) { Write-Warning "[WARN]  $Message" }
function Write-Err ([string]$Message) { Write-Error   "[ERROR] $Message" }

function Get-DisabledComponentsValue {
  try {
    $item = Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue
    if ($null -ne $item) { return [uint32]$item.$RegName }
    return $null
  } catch {
    Write-Err "Read failure $RegPath\${RegName}: $($_.Exception.Message)"
    return $null
  }
}

function Test-PreferIPv4 {
  $val = Get-DisabledComponentsValue
  if ($null -eq $val) { return $false }
  return ( ($val -band $PreferIPv4Bit) -eq $PreferIPv4Bit )
}

function Test-RegistryPath {
  return Test-Path -Path $RegPath -PathType Container
}

function New-RegistryPath {
  if (-not (Test-RegistryPath)) {
    New-Item -Path $RegPath -Force | Out-Null
    Write-Info "Created registry path: $RegPath"
  }
}

function Set-PreferIPv4 {
  try {
    New-RegistryPath

    $current = Get-DisabledComponentsValue
    if ($null -eq $current) {
      $newValue = [uint32]$PreferIPv4Bit
      New-ItemProperty -Path $RegPath -Name $RegName -PropertyType DWord -Value $newValue -Force | Out-Null
      Write-Info ("Created {0} with 0x{1:X} ({2})" -f $RegName, $newValue, $newValue)
      Write-Host "RESULT: SUCCESS - Prefer IPv4 set (new value)."
      return $true
    } else {
      if ( ($current -band $PreferIPv4Bit) -eq $PreferIPv4Bit ) {
        Write-Info ("Prefer IPv4 already set (DisabledComponents = 0x{0:X})" -f $current)
        Write-Host "RESULT: SUCCESS - Already set."
        return $true
      }
      $newValue = [uint32]($current -bor $PreferIPv4Bit)
      # Set-ItemProperty: do NOT specify -Type/-PropertyType here
      Set-ItemProperty -Path $RegPath -Name $RegName -Value $newValue -Force
      Write-Info ("Updated {0} from 0x{1:X} to 0x{2:X}" -f $RegName, $current, $newValue)
      Write-Host "RESULT: SUCCESS - Prefer IPv4 bit added."
      return $true
    }
  } catch {
    Write-Err "Failed to set IPv4 preference: $($_.Exception.Message)"
    Write-Host "RESULT: FAILURE - Error setting value."
    return $false
  } finally {
    Write-Info "A reboot may be required for full effect."
  }
}

function Remove-PreferIPv4 {
  try {
    $current = Get-DisabledComponentsValue
    if ($null -eq $current) {
      Write-Info "$RegName not present; nothing to remove."
      Write-Host "RESULT: SUCCESS - Nothing to remove."
      return $true
    }

    if ( ($current -band $PreferIPv4Bit) -ne $PreferIPv4Bit ) {
      Write-Info ("Prefer IPv4 bit (0x20) not set; current 0x{0:X} left intact." -f $current)
      Write-Host "RESULT: SUCCESS - Bit not set."
      return $true
    }

    $newValue = [uint32]($current -band (-bnot $PreferIPv4Bit))
    if ($newValue -eq 0) {
      Remove-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue
      Write-Info ("Removed {0} entirely (was 0x{1:X})." -f $RegName, $current)
    } else {
      Set-ItemProperty -Path $RegPath -Name $RegName -Value $newValue -Force
      Write-Info ("Cleared prefer-IPv4 bit; {0} changed 0x{1:X} -> 0x{2:X}." -f $RegName, $current, $newValue)
    }

    Write-Host "RESULT: SUCCESS - Prefer IPv4 bit removed."
    return $true
  } catch {
    Write-Err "Failed to remove IPv4 preference: $($_.Exception.Message)"
    Write-Host "RESULT: FAILURE - Error removing bit."
    return $false
  } finally {
    Write-Info "A reboot may be required for full effect."
  }
}

# --- Flow control ---
$exitCode = 1

try {
  if ($Detect) {
    if (Test-PreferIPv4) {
      Write-Info "DETECT: Prefer IPv4 bit present (0x20)."
      Write-Host "RESULT: SUCCESS - Detect found bit."
      $exitCode = 0
    } else {
      Write-Warn "DETECT: Prefer IPv4 bit NOT present."
      Write-Host "RESULT: FAILURE - Detect did not find bit."
      $exitCode = 1
    }
  }
  elseif ($Install) {
    Write-Info "INSTALL: Set 'Prefer IPv4 over IPv6' (0x20)."
    $exitCode = if (Set-PreferIPv4) { 0 } else { 1 }
  }
  elseif ($Uninstall) {
    Write-Info "UNINSTALL: Clear 'Prefer IPv4 over IPv6' bit (0x20) only."
    $exitCode = if (Remove-PreferIPv4) { 0 } else { 1 }
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
