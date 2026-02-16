```
                                                  +##****- .########%#*  *******.                                              
                                              #@  @@@@@@@@: =@@@@@@@@@. %@@@@@@@= *@-                                          
                                            *@@#  :-=*%@@@@=           #@@%+-:..  :@@@.                                        
                                              -= -@@  @@@@@@@@@@@@@@@@@@@@@@# -@* :+:                                          
                                           @@*#* -@@@@@@@@@@@@*     *@@@@@@@@@@@* ++%@@*                                       
                                           @@@@@ :@@@@@@@@@@%  =@@@#  @@@@@@@@@@* +@@@@#                                       
                                           @@#@# :@@@@@@@@@@: *@@@@@% .@@@@@@@@@* +@@%@#                                       
                                           @%=** :@@@@@@@@@@- +@@@@@+ -@@@@@@@@@* +**+@#                                       
                                           @@@#* :@@@@@@@@@@@:  +%+  :@@@@@@@@@@* +=#+@#                                       
                                           @@#@% -@@@@@@@@@@@@@%-.-%@@@@@@@@@@@@* +##*@#                                       
                                           @#-** -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* ++*:@#                                       
                                                 :@@@@@@@@@:           %@@@@@@@@*                                              
                                            %@@@  -==+*%@@- *@@@@@@@@@. =*++++++. *@@@.                                        
                                             .@@  %@@@@@@# -@@@@@@@@@@@  @@@@@@@+ *@+                                          
                                                                                                                               
                                                              %@@@@@@                                                          
                                                                *@%                                                            
                                                              @%   #@                                                          
                                                              +@@@@@#                                                          
                                                                -@+                                                            
                                                              @@+ :@@                                                          
                                                               #@@@@:                                                          
                                                              +. :  +                                                          
                                                              %@@*%@@                                                          
                                                                #@%:                                                           
                                                              %%.  =@                                                          
                                                              =@@@@@*  .+%                                                     
                =@@@@@@@#   .@@@  .@@@   @@@-      @@@@@@@@   . .+: :  .-   %@@@@@%.   @@@@@@@@-    *@@@@@@-   @@@@@@@@        
                -@@@##@@@%  .@@@  .@@@   %@@:      @@@%***+   @@*:+@@      @@@@*%@@@   @@@@#%@@@:  #@@%*@@@@   @@@@###+        
                -@@@  .@@@  .@@@  .@@@   %@@-      @@@.        *@@@#       @@@:  @@@   @@@:  @@@-  %@@   @@@   @@@:            
                -@@@  .@@@  .@@@  .@@@   %@@-      @@@.       +. .  *      @@@:  @@@   @@@:  @@@-  %@@   @@@   @@@:            
                -@@@  .@@@  .@@@  .@@@   %@@-      @@@.       @@@#@@@      @@@.  @@@   @@@:  @@@-  %@@         @@@.            
                -@@@  +@@@  .@@@  .@@@   %@@-      @@@@@@%.    #@@@#  =%-  @@@.  @@@   @@@= :@@@-  %@@         @@@@@@@:        
                -@@@@@@@@:  .@@@  .@@@   %@@-      @@@@%%#    =  .  *:+#:  @@@.  @@@   @@@@@@@@+   %@@ %@@@@.  @@@@%%%.        
                -@@@+@@@    .@@@  .@@@   %@@-      @@@        @@@*%@@      @@@.  @@@   @@@=@@@+    %@@  -@@@   @@@:            
                -@@@ @@@*   .@@@  .@@@   %@@-      @@@.        %@@@@.      @@@.  @@@   @@@:-@@@    %@@   @@@   @@@:            
                -@@@ .@@@.  .@@@  .@@@   %@@-      @@@.       -  =  =      @@@. .@@@   @@@. %@@*   @@@   @@@   @@@:            
                =@@@  #@@%   @@@@@@@@@   @@@@@@@+  @@@@@@@@   @@@+%@@      @@@@@@@@@   @@@:  @@@.  #@@@@@@@@   @@@@@@@@        
                =@@@   @@@-   #@@@@@*    @@@@@@@*  @@@@@@@@    +@@@+        *@@@@@*    @@@:  =@@#   *@@@@@@:   @@@@@@@@        
                                                              %=   :@                                                          
                                                              @@@@@@@                                                          
                                                              #%%%%%*                                                          
                                                             --::..:-*.                                                        
                                                           +@@@@@@@@@@@#                                                       
                                                          -@@-       =@@-                                                      
                                                          %@%         @@@                                                      
                                                          #@@        .@@@                                                      
                                                          .@@%       @@@.                                                      
                                                           .@@@@+-+@@@@                                                        
                                                             :%@@@@@@-                                                         

```


# RuleForge

## Overview

A PowerShell script to forge Windows Defender firewall rules for Microsoft Intune integration.

## Synopsis
I wanted to know if I could build a useful tool using just AI as the developer, turns out, you can! 

RuleForge crafts Windows Defender firewall rules into a form ready for Intune deployment. Capture baseline rules from a clean system, snag post-install rules after adding apps, and compare them to hammer out the new ones—all with a blazing interactive menu or classic CLI switches. Output in JSON for Intune or CSV for review, and wield it on an unmanaged machine to let apps forge their rules freely.

## Description
Born to simplify firewall rule management for Intune, RuleForge has evolved into a blacksmith’s dream for Windows admins. Fire it up with `.\RuleForge.ps1` to enter the forge (menu mode), or swing the CLI hammer with switches for precision strikes. Version 1.2 brings a glowing menu system, colored text, and the power to skip default rules.

## Requirements
- **PowerShell**: Version 7.0 or later (uses `??` operator and ANSI colors via `$PSStyle`).
- **Permissions**: Run as Local Administrator to wield firewall rule access.
- **Module**: Relies on `NetSecurity` (built into Windows PowerShell).

## Installation
1. Ensure PowerShell 7 is installed (`winget install --id Microsoft.PowerShell --source winget`; grab it from [Microsoft](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5) if needed).
2. Download `RuleForge.ps1` from [GitHub](https://github.com/NateHutch365/Microsoft-Intune/tree/main/Tools/RuleForge).
3. (Optional) Drop `DefaultRules.json` in the same directory for `-SkipDefaultRules`. A sample `DefaultRules-Win11-24H2.json` is included for Windows 11 24H2.

## Running the Script
Scripts from the web carry the "Mark of the Web" and may be blocked by PowerShell’s execution policy. If you see “RuleForge.ps1 is not digitally signed,” unblock it:
- **GUI**: Right-click `RuleForge.ps1` > Properties > Check "Unblock" > Apply.
- **PowerShell**: `Unblock-File -Path .\RuleForge.ps1`.

Then fire up the forge:
- **Menu Mode**: `.\RuleForge.ps1` (no switches).
- **CLI Mode**: `.\RuleForge.ps1 -Capture -CaptureType Baseline -Output baseline.json` (with switches).

## Usage
### The Forge (Menu Mode)
Run `.\RuleForge.ps1` without switches to ignite the interactive menu:

![image](https://github.com/user-attachments/assets/cbd1cf16-4e1e-478e-b4e6-28f6498377f3)

- **1. Capture Baseline Rules**: Forge a baseline from a clean system.
  - Prompts: Output filename, format (JSON/CSV), skip disabled/default rules, profile type.
  - Defaults: `baseline.json`, JSON, no skips, All profiles.
- **2. Capture Post-Install Rules**: Hammer out rules after app installs.
  - Same prompts, defaults to `postinstall.json`.
- **3. Compare Rules**: Smelt new rules from baseline and post-install captures.
  - Prompts: Baseline file, post-install file, output prefix, dual JSON/CSV export.
  - Defaults: `baseline.json`, `postinstall.json`, `newrules`, dual output.
- **4. Exit**: “Extinguishing the forge – RuleForge stopped. Happy blacksmithing!”

Press Enter on prompts to accept defaults. Missing `DefaultRules.json`? The forge offers to craft one (best on a fresh OOBE system).

### CLI Mode (Manual Switches)
For precision forging, use switches:
#### Parameters
- `-Capture`
  - Type: Switch
  - Description: Captures firewall rules from the local machine.
  - Example: `-Capture -CaptureType Baseline -Output baseline.json`

- `-CaptureType`
  - Type: String
  - Description: Specifies capture type: `Baseline` or `PostInstall`.
  - Example: `-CaptureType Baseline`

- `-Output`
  - Type: String
  - Description: Output file path for captured rules.
  - Example: `-Output baseline.json`

- `-Compare`
  - Type: Switch
  - Description: Compares two rule sets to identify new rules.
  - Example: `-Compare -BaselineFile baseline.json -PostInstallFile postinstall.json`

- `-BaselineFile`
  - Type: String
  - Description: Path to baseline rules file (JSON).
  - Example: `-BaselineFile baseline.json`

- `-PostInstallFile`
  - Type: String
  - Description: Path to post-install rules file (JSON).
  - Example: `-PostInstallFile postinstall.json`

- `-OutputFormat`
  - Type: String
  - Description: Output format: `JSON` (default), `CSV`, or `Table` (console only).
  - Example: `-OutputFormat CSV`

- `-OutputFile`
  - Type: String
  - Description: Output file prefix for comparison (e.g., `newrules` becomes `newrules.json`/`newrules.csv`).
  - Example: `-OutputFile newrules`

- `-SkipDisabled`
  - Type: Switch
  - Description: Excludes disabled rules from capture.
  - Example: `-SkipDisabled`

- `-ProfileType`
  - Type: String
  - Description: Filters by profile: `All` (default), `Private`, `Public`, `Domain`, or comma-separated (e.g., `Private,Public`).
  - Example: `-ProfileType Private,Public`

- `-DebugOutput`
  - Type: Switch
  - Description: Shows raw/formatted JSON snippets for debugging.
  - Example: `-DebugOutput`

- `-SkipDefaultRules`
  - Type: Switch
  - Description: Skips default Windows rules listed in `DefaultRules.json`.
  - Example: `-SkipDefaultRules`

#### Examples
- **Capture Baseline**: `.\RuleForge.ps1 -Capture -CaptureType Baseline -Output baseline.json -SkipDefaultRules`
- **Capture Baseline for private & public profile**: `.\RuleForge.ps1 -Capture -CaptureType Baseline -Output baseline.json -SkipDisabled -ProfileType 'Private,Public'`
- **Capture Post-Install**: `.\RuleForge.ps1 -Capture -CaptureType PostInstall -Output postinstall.json -SkipDisabled`
- **Compare Rules**: `.\RuleForge.ps1 -Compare -BaselineFile baseline.json -PostInstallFile postinstall.json -OutputFile newrules`
- **Compare and Output New Rules as CSV:** `.\RuleForge.ps1 -Compare -BaselineFile baseline.json -PostInstallFile postinstall.json -OutputFormat CSV -OutputFile newrules`

![image](https://github.com/user-attachments/assets/949cd8e5-dd74-4312-92d2-78e36088d6e5)

## GUI Version (v2.0+)

RuleForge now includes a modern graphical user interface for users who prefer a visual experience over command-line interaction.

### Overview

`RuleForge-GUI.ps1` provides a WPF-based graphical interface that wraps all functionality from the CLI version. It features:
- Tab-based interface for Capture, Compare, and About sections
- File browser dialogs for easy file selection
- Progress bars and real-time status logging
- Admin privilege checking on startup
- All the power of RuleForge with none of the command-line complexity

### Running the GUI Version

```powershell
# Navigate to RuleForge directory
cd Tools\RuleForge

# Run the GUI (requires PowerShell 7.0+)
.\RuleForge-GUI.ps1
```

**Important:** Right-click and select "Run as Administrator" or the GUI will prompt you that admin privileges are required for firewall access.

### GUI Features

#### Tab 1: Capture Rules
- Select capture mode: Baseline or Post-Install
- Browse for output file location
- Choose output format: JSON, CSV, or Both
- Filter options:
  - Skip disabled rules
  - Skip default Windows rules
  - Select profile types (All, Private, Public, Domain, or combinations)
- Large "Capture Rules" button to start the operation
- Progress bar shows operation status
- Real-time status log displays all actions and results

#### Tab 2: Compare Rules
- Browse and select baseline file
- Browse and select post-install file
- Specify output file prefix
- Choose output format: JSON, CSV, Both, or Table
- Large "Compare Rules" button to start comparison
- Progress bar and status log show operation progress
- Results displayed in the status log

#### Tab 3: About
- Version information (v2.0 - GUI Edition)
- Author and contact information
- Links to website and GitHub repository
- Complete functionality description
- System requirements
- Usage tips for best results
- Compilation instructions reference

### DefaultRules.json Handling

If you check "Skip default Windows rules" but `DefaultRules.json` doesn't exist, the GUI will prompt you:

> DefaultRules.json not found. Would you like to create it now?
> 
> Note: This should only be done on a fresh OOBE device.

Clicking "Yes" will generate the file automatically. This process may take several minutes depending on system performance.

### User Experience Improvements

- **No Execution Policy Issues**: Once compiled to .exe, no more "script is not digitally signed" warnings
- **Intuitive Interface**: No need to remember command-line switches
- **Visual Feedback**: Progress bars and status messages keep you informed
- **Error Handling**: User-friendly error messages in popup dialogs
- **Responsive UI**: Operations run in background, preventing interface freezing

### Compiling to Standalone Executable

The GUI can be compiled to a standalone Windows executable for easier distribution:

```powershell
# Install PS2EXE module
Install-Module -Name ps2exe -Scope CurrentUser

# Compile to executable
Invoke-PS2EXE `
    -InputFile "RuleForge-GUI.ps1" `
    -OutputFile "RuleForge.exe" `
    -NoConsole `
    -RequireAdmin `
    -Title "RuleForge v2.0" `
    -Version "2.0.0.0"
```

For complete compilation instructions, see **[COMPILE-TO-EXE.md](COMPILE-TO-EXE.md)**.

### GUI vs CLI: Which to Use?

| Feature | GUI Version | CLI Version |
|---------|-------------|-------------|
| **Ease of Use** | Intuitive, visual | Requires command knowledge |
| **Automation** | Manual operation | Scriptable with parameters |
| **Learning Curve** | Low | Medium |
| **Distribution** | Can compile to .exe | Script file only |
| **Batch Processing** | Not ideal | Excellent |
| **Interactive Use** | Excellent | Good (menu mode) |
| **Remote Execution** | Requires RDP/GUI | Works over PowerShell remoting |

**Choose GUI** if you: Want point-and-click simplicity, work locally on machines, prefer visual feedback

**Choose CLI** if you: Need automation, work remotely, want to script operations, integrate with other tools

Both versions maintain identical core functionality and can be used interchangeably based on your needs.

## Notes
- **JSON Format**: Empty arrays (`[]`) mean “Any” (no specific port/address).
- **DefaultRules.json**: For `-SkipDefaultRules`, craft it on a fresh OOBE system: `.\RuleForge.ps1 -Capture -CaptureType Baseline -Output DefaultRules.json` Place it with `RuleForge.ps1`. A Windows 11 24H2 sample is at `DefaultRules-Win11-24H2.json` (you'll want to rename this).
- **Colors**: Requires a modern terminal (e.g., Windows Terminal) for ANSI colors to glow.

## Roadmap
- **v2.x**: Integrate Microsoft Defender XDR API for Advanced Hunting queries to capture live blocked connections from production.
- **v2.x**: Incorporate `Test-IntuneFirewallRules` for rule validation and error reporting via Graph API.
- **v2.0**: Forge into a PowerShell module.
- **v1.5**: Enhance menu with interactive app selection for production devices.
- **v1.4**: Add `-ExtractAppRules` to filter app-specific rules from full captures.
- **v1.3**: Introduce `-AppPath` to capture app-specific rules from live systems, plus basic rule validation.
- **v1.2**: Ignite menu system with colored text and default rule skipping.
- **v1.1**: Hammer in `-SkipDefaultRules` with sample `DefaultRules-Win11-24H2.json`.
- **v1.0**: Initial spark with core capture/compare/export.

## Contributing
Fork it, hammer out pull requests, or spark issues on [GitHub](https://github.com/NateHutch365/Microsoft-Intune/tree/main/Tools/RuleForge).

## License
This project is open-source and free to use.

## Acknowledgments
Vision and roadmap by Nathan Hutchinson, forged by Grok3 at xAI.
