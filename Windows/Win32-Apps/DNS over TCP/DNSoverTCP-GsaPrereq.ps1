<#
.SYNOPSIS
  Disable browser DNS clients to avoid DNS-over-TCP (port 53) with GSA.

.DESCRIPTION
Sets the following registry values:
                 * Edge (HKLM):  HKLM:\SOFTWARE\Policies\Microsoft\Edge\BuiltInDnsClientEnabled = 0 (DWORD)
                 * Chrome (HKCU): HKCU:\Software\Policies\Google\Chrome\BuiltInDnsClientEnabled = 0 (DWORD)
               (Chrome HKCU is applied to all loaded user hives under HKEY_USERS\<SID>.)

  -Install command: %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\DNSoverTCP-GsaPrereq.ps1 -Install
  -Uninstall command: %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\DNSoverTCP-GsaPrereq.ps1 -Uninstall
  -Detectection Rule Type: File
  -Detection Path: %ProgramData%\Microsoft\IntuneManagementExtension\Logs\
  -Detection File or Folder: App-DNSoverTCP.log
  -Detection Method: File or folder exists
  -Associated with 32-bit: No 

LOGGING
  Appends a transcript to:
    %ProgramData%\Microsoft\IntuneManagementExtension\Logs\App-DNSoverTCP.log
  Final line includes: RESULT: SUCCESS | FAILURE with a reason.

NOTES
  - This script intentionally only touches the two keys requested.
  - When running as SYSTEM, HKCU refers to the SYSTEM profile; per-user is set via HKEY_USERS\<SID>.
#>

[CmdletBinding()]
param(
  [switch]$Install,
  [switch]$Uninstall,
  [switch]$Detect
)

# --- Constants & Paths ---
$LogsFolder = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs'
$MainLog    = Join-Path $LogsFolder 'App-DNSoverTCP.log'

# Edge (machine-wide) policy
$EdgePolicyPathHKLM = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
$EdgeDnsValueName   = 'BuiltInDnsClientEnabled'
$DisableDnsDword    = [uint32]0

# Chrome (per-user HKCU), written under each loaded user at HKU\<SID>
$ChromePolicyPathHKUFormat = 'Registry::HKEY_USERS\{0}\Software\Policies\Google\Chrome'
$ChromeDnsValueName        = 'BuiltInDnsClientEnabled'

# --- Ensure log folder exists ---
if (-not (Test-Path -LiteralPath $LogsFolder)) {
  New-Item -Path $LogsFolder -ItemType Directory -Force | Out-Null
}

# --- Start transcript (append for cumulative history) ---
try {
  Start-Transcript -Path $MainLog -Append -ErrorAction Stop
  Write-Host "[DNSoverTCP-Prereq] $(Get-Date -Format u) - Starting"
} catch {
  Write-Warning "Transcript start failed: $($_.Exception.Message)"
}

function Write-Info([string]$Message) { Write-Host    "[INFO]  $Message" }
function Write-Warn([string]$Message) { Write-Warning "[WARN]  $Message" }
function Write-Err ([string]$Message) { Write-Error   "[ERROR] $Message" }

# ---------- Helpers ----------
function Get-UserSids {
  # User SIDs under HKU that look like real profiles (skip .DEFAULT and *_Classes)
  Get-ChildItem -Path 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'HKEY_USERS\\S-1-5-21-' -and $_.Name -notmatch '_Classes$' } |
    Select-Object -ExpandProperty PSChildName
}

function Set-EdgeDnsPolicy {
  try {
    if (-not (Test-Path -Path $EdgePolicyPathHKLM)) {
      New-Item -Path $EdgePolicyPathHKLM -Force | Out-Null
    }
    New-ItemProperty -Path $EdgePolicyPathHKLM -Name $EdgeDnsValueName -PropertyType DWord -Value $DisableDnsDword -Force | Out-Null
    Write-Info "Edge policy set: $EdgePolicyPathHKLM\$EdgeDnsValueName = 0"
    return $true
  } catch {
    Write-Err "Failed to set Edge DNS policy: $($_.Exception.Message)"
    return $false
  }
}

function Remove-EdgeDnsPolicy {
  try {
    if (Test-Path -Path $EdgePolicyPathHKLM) {
      Remove-ItemProperty -Path $EdgePolicyPathHKLM -Name $EdgeDnsValueName -ErrorAction SilentlyContinue
      Write-Info "Edge policy removed: $EdgePolicyPathHKLM\$EdgeDnsValueName"
    }
    return $true
  } catch {
    Write-Err "Failed to remove Edge DNS policy: $($_.Exception.Message)"
    return $false
  }
}

function Set-ChromeDnsPolicyPerUser {
  $ok = $true
  $sids = Get-UserSids
  if (-not $sids -or $sids.Count -eq 0) {
    Write-Warn "No user hives found under HKU to stamp Chrome HKCU policy."
    return $true  # not fatal; device may be pre-user
  }
  foreach ($sid in $sids) {
    try {
      $path = [string]::Format($ChromePolicyPathHKUFormat, $sid)
      if (-not (Test-Path -Path $path)) { New-Item -Path $path -Force | Out-Null }
      New-ItemProperty -Path $path -Name $ChromeDnsValueName -PropertyType DWord -Value $DisableDnsDword -Force | Out-Null
      Write-Info "Chrome per-user policy set for SID $($sid): $path\$ChromeDnsValueName = 0"
    } catch {
      Write-Err "Failed to set Chrome per-user DNS policy for SID $($sid): $($_.Exception.Message)"
      $ok = $false
    }
  }
  return $ok
}

function Remove-ChromeDnsPolicyPerUser {
  $ok = $true
  $sids = Get-UserSids
  foreach ($sid in $sids) {
    try {
      $path = [string]::Format($ChromePolicyPathHKUFormat, $sid)
      if (Test-Path -Path $path) {
        Remove-ItemProperty -Path $path -Name $ChromeDnsValueName -ErrorAction SilentlyContinue
        Write-Info "Chrome per-user policy removed for SID $($sid): $path\$ChromeDnsValueName"
      }
    } catch {
      Write-Err "Failed to remove Chrome per-user DNS policy for SID $($sid): $($_.Exception.Message)"
      $ok = $false
    }
  }
  return $ok
}

function Test-EdgeDnsPolicy {
  try {
    $val = (Get-ItemProperty -Path $EdgePolicyPathHKLM -Name $EdgeDnsValueName -ErrorAction SilentlyContinue).$EdgeDnsValueName
    return ($val -eq 0)
  } catch { return $false }
}

function Test-ChromeDnsPolicyPerUser {
  $sids = Get-UserSids
  if (-not $sids -or $sids.Count -eq 0) { return $true } # treat as compliant when no user hives yet
  foreach ($sid in $sids) {
    $path = [string]::Format($ChromePolicyPathHKUFormat, $sid)
    try {
      $val = (Get-ItemProperty -Path $path -Name $ChromeDnsValueName -ErrorAction SilentlyContinue).$ChromeDnsValueName
      if ($val -ne 0) { return $false }
    } catch { return $false }
  }
  return $true
}

# ---------- Flow ----------
$exitCode = 1

try {
  if ($Detect) {
    $edgeOK = Test-EdgeDnsPolicy
    $chrOK  = Test-ChromeDnsPolicyPerUser
    if ($edgeOK -and $chrOK) {
      Write-Info "DETECT: Edge=OK, Chrome per-user=OK"
      Write-Host "RESULT: SUCCESS - All required values present."
      $exitCode = 0
    } else {
      if (-not $edgeOK) { Write-Warn "DETECT: Edge policy not set to 0." }
      if (-not $chrOK ) { Write-Warn "DETECT: One or more user hives missing Chrome policy or not 0." }
      Write-Host "RESULT: FAILURE - One or more required values missing."
      $exitCode = 1
    }
  }
  elseif ($Install) {
    Write-Info "INSTALL: Apply Edge (HKLM) and Chrome (HKCU via HKU\<SID>) DNS policy values."
    $edgeOk = Set-EdgeDnsPolicy
    $chrOk  = Set-ChromeDnsPolicyPerUser
    if ($edgeOk -and $chrOk) {
      Write-Host "RESULT: SUCCESS - DNS over TCP mitigations applied."
      $exitCode = 0
    } else {
      Write-Host "RESULT: FAILURE - One or more policy writes failed."
      $exitCode = 1
    }
  }
  elseif ($Uninstall) {
    Write-Info "UNINSTALL: Remove Edge and Chrome DNS policy values."
    $edgeOk = Remove-EdgeDnsPolicy
    $chrOk  = Remove-ChromeDnsPolicyPerUser
    if ($edgeOk -and $chrOk) {
      Write-Host "RESULT: SUCCESS - DNS over TCP mitigations removed."
      $exitCode = 0
    } else {
      Write-Host "RESULT: FAILURE - One or more removals failed."
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
