
# RuleForge

## Overview

`RuleForge.ps1` is a PowerShell script designed to streamline the management of Windows Defender firewall rules for Microsoft Intune. It captures firewall rules from a reference machine, compares them to identify changes (e.g., new rules from app installations), and exports them in JSON or CSV format. This tool is ideal for endpoint security admins hardening devices via Intune, ensuring a single source of truth by disabling local policy merges and managing rules centrally.

- **Version**: 1.0
- **Author**: Nathan Hutchinson
- **Website**: [natehutchinson.co.uk](https://natehutchinson.co.uk)
- **GitHub**: [github.com/NateHutch365](https://github.com/NateHutch365)

## Purpose

When hardening endpoints with Intune, local policy merge settings are often disabled to enforce Intune as the sole policy source. This prevents apps from automatically adding firewall rules locally, requiring admins to manage rules manually. `RuleForge.ps1` simplifies this by:
1. Capturing a baseline of rules from an unmanaged reference machine.
2. Capturing rules after installing apps.
3. Comparing the two to identify new rules for Intune deployment.

## Requirements

- **Operating System**: Windows (tested on Windows 10/11).
- **PowerShell**: Version 5.1 or later (uses `NetSecurity` module cmdlets like `Get-NetFirewallRule`).
- **Permissions**: Must be run as a Local Administrator to access firewall rules.
- **Environment**: Use on an unmanaged reference machine (no Intune/GPO) with a local admin account.

## Usage

Run the script in PowerShell with administrative privileges. It supports two modes: `-Capture` and `-Compare`.

### Modes

#### Capture Mode
Captures all current firewall rules and saves them to a file.

```powershell
.\RuleForge.ps1 -Capture -CaptureType <Type> -Output <FilePath> [Options]

#### Compare Mode
Compares two captured rule sets (baseline and post-install) and outputs the differences.

```powershell
.\RuleForge.ps1 -Compare -BaselineFile <BaselinePath> -PostInstallFile <PostInstallPath> -OutputFile <OutputPath> [Options]