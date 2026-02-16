# Compiling RuleForge to an Executable (.exe)

This guide walks you through compiling the RuleForge PowerShell scripts into standalone Windows executables (.exe) using **PS2EXE**, the most widely used PowerShell-to-EXE compiler.

---

## Prerequisites

- **Windows** operating system
- **PowerShell 5.1** or **PowerShell 7.x**
- **Internet access** to install the PS2EXE module (one-time setup)

---

## Step 1: Install PS2EXE

Open PowerShell **as Administrator** and run:

```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
```

> If prompted to install from an untrusted repository, type **Y** to confirm.

Verify installation:

```powershell
Get-Module -Name ps2exe -ListAvailable
```

---

## Step 2: Navigate to the RuleForge Directory

```powershell
cd "C:\Path\To\Microsoft-Intune\Tools\RuleForge"
```

Replace the path with the actual location where you downloaded or cloned the repository.

---

## Step 3: Compile the GUI Version

```powershell
Invoke-PS2EXE -InputFile .\RuleForge-GUI.ps1 `
              -OutputFile .\RuleForge-GUI.exe `
              -NoConsole `
              -Title "RuleForge" `
              -Description "RuleForge GUI - Firewall Rule Manager for Microsoft Intune" `
              -Version "2.0.0" `
              -Company "RuleForge" `
              -Product "RuleForge GUI" `
              -Copyright "(c) 2025 Nathan Hutchinson" `
              -RequireAdmin
```

### Parameter Explanation

| Parameter | Purpose |
|-----------|---------|
| `-InputFile` | The PowerShell script to compile |
| `-OutputFile` | The resulting .exe file |
| `-NoConsole` | Hides the console window (important for GUI apps) |
| `-Title` | Window title / executable metadata |
| `-Description` | File description shown in Properties |
| `-Version` | Version number in file metadata |
| `-RequireAdmin` | Prompts for admin elevation when launched (required for firewall access) |

---

## Step 4: Compile the CLI Version (Optional)

If you also want the CLI version as an .exe:

```powershell
Invoke-PS2EXE -InputFile .\RuleForge.ps1 `
              -OutputFile .\RuleForge-CLI.exe `
              -Title "RuleForge CLI" `
              -Description "RuleForge CLI - Firewall Rule Manager for Microsoft Intune" `
              -Version "1.2.1" `
              -Company "RuleForge" `
              -Product "RuleForge CLI" `
              -Copyright "(c) 2025 Nathan Hutchinson" `
              -RequireAdmin
```

> **Note:** Do **not** use `-NoConsole` for the CLI version, as it needs the console window for interactive menu display and output.

---

## Step 5: Verify the Executable

1. Right-click the generated `.exe` file and select **Properties** to confirm the metadata.
2. Run the executable:
   - **GUI:** Double-click `RuleForge-GUI.exe` (UAC prompt will appear for admin elevation).
   - **CLI:** Open a terminal and run `.\RuleForge-CLI.exe` with desired switches, or double-click for menu mode.

---

## Distributing the Executable

When distributing the compiled `.exe`, include the following alongside it:

| File | Required | Notes |
|------|----------|-------|
| `RuleForge-GUI.exe` or `RuleForge-CLI.exe` | Yes | The compiled executable |
| `DefaultRules-Win11-24H2.json` | Optional | Sample default rules (rename to `DefaultRules.json` to use) |

The executable is self-contained and does not require PowerShell 7 to be installed on the target machine (PS2EXE embeds the necessary runtime).

---

## Troubleshooting

### "Script is not digitally signed"
The compiled `.exe` bypasses execution policy restrictions, so this error does not apply.

### Antivirus False Positives
Some antivirus software may flag PS2EXE-compiled executables as suspicious. This is a known issue with script-to-exe compilers. You can:
- Add an exception in your antivirus software.
- Sign the executable with a code signing certificate.

### Missing .NET Framework
PS2EXE requires .NET Framework 4.x on the target machine. Windows 10/11 includes this by default.

### GUI Not Displaying
Ensure you used the `-NoConsole` flag when compiling the GUI version. Without it, the WPF window may not display correctly.

---

## Advanced: Code Signing

To sign your compiled executable with a code signing certificate:

```powershell
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
Set-AuthenticodeSignature -FilePath .\RuleForge-GUI.exe -Certificate $cert -TimestampServer "http://timestamp.digicert.com"
```

This removes "Unknown Publisher" warnings and prevents SmartScreen blocks.

---

## Alternative Compilation Methods

### Win-PS2EXE (GUI Wrapper)
For a graphical interface to PS2EXE:

```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Win-PS2EXE
```

This opens a GUI where you can browse for your script file, set options, and compile.

### NSIS (Nullsoft Scriptable Install System)
For creating a full installer package, use NSIS with a PowerShell launcher script. This is more complex but allows bundling additional files.
