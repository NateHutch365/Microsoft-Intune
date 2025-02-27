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

## Notes
- **JSON Format**: Empty arrays (`[]`) mean “Any” (no specific port/address).
- **DefaultRules.json**: For `-SkipDefaultRules`, craft it on a fresh OOBE system: `.\RuleForge.ps1 -Capture -CaptureType Baseline -Output DefaultRules.json` Place it with `RuleForge.ps1`. A Windows 11 24H2 sample is at `DefaultRules-Win11-24H2.json` (you'll want to rename this).
- **Colors**: Requires a modern terminal (e.g., Windows Terminal) for ANSI colors to glow.

## Roadmap
- **v2.0**: Forge into a PowerShell module.
- **v2.x**: Integrate Microsoft Graph API for Intune smelting.
- **v1.5**: Enhance menu with interactive app selection for production devices.
- **v1.4**: Add `-ExtractAppRules` to filter app-specific rules from full captures.
- **v1.3**: Introduce `-AppPath` to capture app-specific rules from live systems.
- **v1.2**: Ignite menu system with colored text and default rule skipping.
- **v1.1**: Hammer in `-SkipDefaultRules` with sample `DefaultRules-Win11-24H2.json`.
- **v1.0**: Initial spark with core capture/compare/export.

## Contributing
Fork it, hammer out pull requests, or spark issues on [GitHub](https://github.com/NateHutch365/Microsoft-Intune/tree/main/Tools/RuleForge).

## License
This project is open-source and free to use.

## Acknowledgments
Vision and roadmap by Nathan Hutchinson, forged by Grok3 at xAI.
