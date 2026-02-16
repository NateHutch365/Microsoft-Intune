# Compiling RuleForge-GUI to Standalone Executable

This guide explains how to compile `RuleForge-GUI.ps1` into a standalone Windows executable (`.exe`) that can be run without directly invoking PowerShell.

## Overview

Converting the PowerShell GUI script to an executable offers several benefits:
- Easier distribution to users unfamiliar with PowerShell
- No need to explain execution policies or script unblocking
- Professional appearance with standard Windows application behavior
- Can be pinned to Start Menu or Taskbar like any other application

## Prerequisites

- Windows 10/11 or Windows Server
- PowerShell 7.0 or later
- Administrator privileges (for running the compiled executable)
- PS2EXE module or alternative compilation tool

## Method 1: Using PS2EXE (Recommended)

PS2EXE is a popular PowerShell module that converts PowerShell scripts to executables.

### Installation

```powershell
# Install PS2EXE from PowerShell Gallery
Install-Module -Name ps2exe -Scope CurrentUser

# Verify installation
Get-Command Invoke-PS2EXE
```

### Basic Compilation

```powershell
# Navigate to the RuleForge directory
cd "C:\Path\To\Tools\RuleForge"

# Compile with basic options
Invoke-PS2EXE -InputFile "RuleForge-GUI.ps1" -OutputFile "RuleForge.exe" -NoConsole -RequireAdmin
```

### Recommended Compilation Command

For the best user experience, use these options:

```powershell
Invoke-PS2EXE `
    -InputFile "RuleForge-GUI.ps1" `
    -OutputFile "RuleForge.exe" `
    -NoConsole `
    -RequireAdmin `
    -Title "RuleForge v2.0" `
    -Description "Windows Firewall Rule Manager for Microsoft Intune" `
    -Company "Nathan Hutchinson" `
    -Product "RuleForge" `
    -Version "2.0.0.0" `
    -Copyright "2026" `
    -NoError `
    -NoOutput
```

### Parameter Explanations

| Parameter | Description |
|-----------|-------------|
| `-InputFile` | Path to the PowerShell script to compile |
| `-OutputFile` | Path for the generated executable |
| `-NoConsole` | Hides the PowerShell console window (GUI mode) |
| `-RequireAdmin` | Forces the executable to run with admin privileges |
| `-Title` | Window title shown in Task Manager |
| `-Description` | Description shown in file properties |
| `-Company` | Company name in file properties |
| `-Product` | Product name in file properties |
| `-Version` | Version number in file properties |
| `-Copyright` | Copyright text in file properties |
| `-NoError` | Don't display errors in console |
| `-NoOutput` | Don't display output in console |

### Adding an Icon (Optional)

To add a custom icon to your executable:

```powershell
# Prepare a .ico file (e.g., forge-icon.ico)
Invoke-PS2EXE `
    -InputFile "RuleForge-GUI.ps1" `
    -OutputFile "RuleForge.exe" `
    -IconFile "forge-icon.ico" `
    -NoConsole `
    -RequireAdmin `
    -Title "RuleForge v2.0" `
    -Version "2.0.0.0"
```

**Note:** The icon file must be in `.ico` format. You can convert PNG/JPG to ICO using online tools or image editors.

## Method 2: Using PS2EXE-GUI

PS2EXE also includes a graphical interface for easier compilation.

### Launch PS2EXE-GUI

```powershell
# After installing PS2EXE module
Win-PS2EXE
```

### GUI Steps

1. **Source File**: Browse and select `RuleForge-GUI.ps1`
2. **Target File**: Choose output location (e.g., `RuleForge.exe`)
3. **Options**:
   - ✅ Check "No Console"
   - ✅ Check "Require Admin"
   - Fill in Title, Description, Company, Product fields
4. Click **Compile** button
5. Wait for compilation to complete

## Method 3: Using IExpress (Windows Built-in)

For a native Windows solution without installing modules:

### Steps

1. Run `iexpress.exe` as Administrator
2. Select "Create new Self Extraction Directive file"
3. Choose "Extract files and run an installation command"
4. Set package title: "RuleForge v2.0"
5. No prompt for user
6. Do not display license
7. Add `RuleForge-GUI.ps1` and any required files
8. Install program: `powershell.exe -ExecutionPolicy Bypass -File RuleForge-GUI.ps1`
9. Show window: Hidden
10. No message after extraction
11. Save SED file for future use
12. Create package

**Note:** IExpress creates a self-extracting archive, not a true executable conversion. The user experience may be less polished.

## Post-Compilation Testing

After compiling, test the executable thoroughly:

### 1. Check Administrator Privileges

```powershell
# Right-click RuleForge.exe → Properties → Compatibility
# Verify "Run this program as an administrator" is NOT needed
# (PS2EXE's -RequireAdmin handles this automatically)
```

### 2. Test on Clean System

- Copy `RuleForge.exe` to a test machine
- Double-click to run (UAC prompt should appear)
- Verify all three tabs function correctly
- Test Capture operation
- Test Compare operation with sample files
- Verify file dialogs work properly

### 3. Verify File Dependencies

The compiled executable should work standalone, but note:
- **DefaultRules.json** must be in the same directory if "Skip default Windows rules" is used
- Output files are created in the executable's working directory

## Distribution

### Single File Distribution

```
📁 RuleForge-Portable/
  ├── RuleForge.exe                    (Required)
  ├── DefaultRules-Win11-24H2.json     (Optional, for reference)
  └── README.txt                       (Optional, usage instructions)
```

### What to Include

1. **RuleForge.exe** - The compiled executable (Required)
2. **DefaultRules-Win11-24H2.json** - Sample default rules (Optional)
3. **README.txt** - Brief usage instructions (Optional)

### Distribution Checklist

- [ ] Test executable on clean Windows 10/11 system
- [ ] Verify admin privilege prompt appears
- [ ] Test all major features (Capture, Compare, Browse)
- [ ] Include sample DefaultRules.json if distributing
- [ ] Provide usage instructions for end users
- [ ] Consider code signing for production distribution (optional)

## Troubleshooting

### Issue: "This app has been blocked for your protection"

**Cause:** Windows SmartScreen blocking unsigned executable

**Solution:**
- Click "More info" → "Run anyway"
- OR: Code sign the executable with a trusted certificate

### Issue: GUI doesn't appear, just console window

**Cause:** Missing `-NoConsole` parameter

**Solution:** Recompile with `-NoConsole` flag

### Issue: "Access Denied" errors during operation

**Cause:** Not running with administrator privileges

**Solution:** 
- Recompile with `-RequireAdmin` parameter
- OR: Manually run as Administrator (right-click → Run as Administrator)

### Issue: Executable is very large (10+ MB)

**Cause:** PS2EXE bundles PowerShell runtime

**Solution:** This is normal behavior. PS2EXE creates self-contained executables.

### Issue: Antivirus flags the executable as suspicious

**Cause:** Heuristic analysis of PowerShell conversion

**Solution:**
- Whitelist in your antivirus software
- Code sign the executable
- Use reputable compilation tool
- Submit false positive report to AV vendor

## Code Signing (Advanced)

For enterprise distribution, consider code signing:

### Requirements
- Code signing certificate from trusted CA
- SignTool.exe (from Windows SDK)

### Signing Command

```powershell
# Using SignTool
signtool.exe sign /f "certificate.pfx" /p "password" /t http://timestamp.digicert.com "RuleForge.exe"
```

### Benefits of Code Signing
- ✅ Removes SmartScreen warnings
- ✅ Establishes software publisher identity
- ✅ Increases user trust
- ✅ Better for enterprise deployment

## Alternative Tools

While PS2EXE is recommended, other options exist:

| Tool | Pros | Cons |
|------|------|------|
| **PS2EXE** | Free, easy to use, good results | Requires module installation |
| **PowerShell Studio** | Professional IDE, excellent GUI | Commercial license required |
| **Advanced Installer** | Full installer creation | Complex, commercial |
| **IExpress** | Built into Windows | Less polished output |

## Version Updates

When updating RuleForge-GUI.ps1:

1. Update version number in script header
2. Test changes in PowerShell before compiling
3. Recompile with updated version number:
   ```powershell
   Invoke-PS2EXE -InputFile "RuleForge-GUI.ps1" -OutputFile "RuleForge.exe" `
       -NoConsole -RequireAdmin -Version "2.1.0.0"
   ```
4. Test compiled executable
5. Update distribution package

## Support

For issues or questions:
- **GitHub**: https://github.com/NateHutch365/Microsoft-Intune
- **Website**: https://natehutchinson.co.uk

## License

RuleForge is open-source and free to use. The compiled executable inherits the same license.

---

**Last Updated:** February 2026  
**RuleForge Version:** 2.0 - GUI Edition
