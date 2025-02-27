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

`RuleForge.ps1` is a PowerShell script designed to streamline the management of Windows Defender firewall rules for Microsoft Intune. It captures firewall rules from a reference machine, compares them to identify changes (e.g., new rules from app installations), and exports them in JSON or CSV format. This tool is ideal for endpoint security admins hardening devices via Intune, ensuring a single source of truth by disabling local policy merges and managing rules centrally.

- **Version**: 1.1
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
```

#### Compare Mode
Compares two captured rule sets (baseline and post-install) and outputs the differences.

```powershell
.\RuleForge.ps1 -Compare -BaselineFile <BaselinePath> -PostInstallFile <PostInstallPath> -OutputFile <OutputPath> [Options]
```

### Parameters

#### Common Parameters
- `-Capture`
  - Type: Switch
  - Description: Enables capture mode to export current firewall rules.
  - Example: `-Capture`

- `-Compare`
  - Type: Switch
  - Description: Enables compare mode to find new rules between two captures.
  - Example: `-Compare`

- `-SkipDisabled`
  - Type: Switch
  - Description: Filters out disabled rules during capture, including only enabled rules.
  - Default: False (includes all rules).
  - Example: `-SkipDisabled`

- `-ProfileType`
  - Type: String
  - Description: Filters rules by network profile type(s). Accepts `Private`, `Public`, `Domain`, `All`, or a comma-separated list (e.g., `Private,Public`).
  - Default: `All`
  - Example: `-ProfileType 'Private'` or `-ProfileType 'Private,Public'`

- `-DebugOutput`
  - Type: Switch
  - Description: Enables debug output, showing raw and formatted JSON snippets (first 200 characters) before saving. Useful for troubleshooting.
  - Default: False
  - Example: `-DebugOutput`
 
- `-SkipDefaultRules`
  - Type: Switch
  - Description: Excludes default Windows firewall rules listed in `DefaultRules.json` during capture. Speeds up processing by skipping system rules.
  - Example: `-SkipDefaultRules`
  - Note: Requires a `DefaultRules.json` file. Generate it by running `-Capture -CaptureType Baseline -Output DefaultRules.json` on a fresh Windows install.

#### Capture Mode Parameters
- `-CaptureType`
  - Type: String
  - Description: Specifies the type of capture. Required for `-Capture`.
  - Options:
    - `Baseline`: Captures rules before app installation.
    - `PostInstall`: Captures rules after app installation.
  - Example: `-CaptureType 'Baseline'`

- `-Output`
  - Type: String
  - Description: Path to save the captured rules file. Extension changes based on `-OutputFormat` (`.json` or `.csv`).
  - Required for `-Capture`.
  - Example: `-Output 'C:\Scripts\baseline.json'`

- `-OutputFormat`
  - Type: String
  - Description: Format for the output file in `-Capture` mode.
  - Options:
    - `JSON`: Saves rules as JSON (Intune-compatible, arrays like `[]` mean "Any"). Default.
    - `CSV`: Saves rules as a flat CSV file for manual review.
  - Default: `JSON`
  - Example: `-OutputFormat 'CSV'`

#### Compare Mode Parameters
- `-BaselineFile`
  - Type: String
  - Description: Path to the baseline JSON file (from a `Baseline` capture). Required for `-Compare`.
  - Example: `-BaselineFile 'C:\Scripts\baseline.json'`

- `-PostInstallFile`
  - Type: String
  - Description: Path to the post-install JSON file (from a `PostInstall` capture). Required for `-Compare`.
  - Example: `-PostInstallFile 'C:\Scripts\postinstall.json'`

- `-OutputFile`
  - Type: String
  - Description: Path to save the comparison result. Extension changes based on `-OutputFormat` (`.json` or `.csv`).
  - Required for `-Compare` unless `-OutputFormat 'Table'`.
  - Example: `-OutputFile 'C:\Scripts\newrules.csv'`

- `-OutputFormat`
  - Type: String
  - Description: Format for the comparison output in `-Compare` mode.
  - Options:
    - `JSON`: Saves new rules as JSON (Intune-compatible). Default.
    - `CSV`: Saves new rules as a CSV file.
    - `Table`: Displays new rules in the PowerShell console as a table (no file output).
  - Default: `JSON`
  - Example: `-OutputFormat 'Table'`

### Examples

#### Capture Baseline Rules as JSON
```powershell
.\RuleForge.ps1 -Capture -CaptureType Baseline -Output C:\Scripts\baseline.json -SkipDisabled -ProfileType 'Private'
```
- Captures enabled rules for the Private profile, saves to `baseline.json`.

#### Capture Post-Install Rules as CSV
```powershell
.\RuleForge.ps1 -Capture -CaptureType PostInstall -Output C:\Scripts\postinstall.json -OutputFormat CSV -SkipDisabled -ProfileType 'Private'
```
- After installing an app, captures rules to `postinstall.csv`.

#### Compare and Output New Rules as CSV
```powershell
.\RuleForge.ps1 -Compare -BaselineFile C:\Scripts\baseline.json -PostInstallFile C:\Scripts\postinstall.json -OutputFormat CSV -OutputFile C:\Scripts\newrules.csv
```
- Compares the two JSON files, saves new rules to `newrules.csv`.

#### Compare with Debug Output
```powershell
.\RuleForge.ps1 -Compare -BaselineFile C:\Scripts\baseline.json -PostInstallFile C:\Scripts\postinstall.json -OutputFile C:\Scripts\newrules.json -DebugOutput
```
- Shows raw and formatted JSON snippets during comparison.

#### The following steps will provide you with both a JSON for automation and a CSV for manual review - Update the parameters as required e.g., `-SkipDisabled` and `-ProfileType`

#### Capture Baseline Rules for private profile as JSON, skip disabled rules
```powershell
.\RuleForge.ps1 -Capture -CaptureType Baseline -Output baseline.json -SkipDisabled -ProfileType 'Private'
```

#### Capture PostInstall Rules for private profile as JSON, skip disabled rules
```powershell
.\RuleForge.ps1 -Capture -CaptureType PostInstall -Output postinstall.json -SkipDisabled -ProfileType 'Private'
```

#### Compare and Output New Rules as JSON
```powershell
.\RuleForge.ps1 -Compare -BaselineFile baseline.json -PostInstallFile postinstall.json -OutputFormat JSON -OutputFile newrules.json
```

#### Compare and Output New Rules as CSV
```powershell
.\RuleForge.ps1 -Compare -BaselineFile baseline.json -PostInstallFile postinstall.json -OutputFormat CSV -OutputFile newrules.json
```

### Output Formats

#### JSON
- **Purpose**: Compatible with Intune’s `windowsFirewallRule` schema via Microsoft Graph API.
- **Note**: Empty arrays (`[]`) represent "Any" (no specific port/address restriction).
- **Example**:
```json
{
  "displayName": "Firefox (C:\\Program Files\\Mozilla Firefox)",
  "description": null,
  "action": "allow",
  "direction": "inbound",
  "protocol": 6,
  "localPortRanges": [],
  "remotePortRanges": [],
  "localAddressRanges": [],
  "remoteAddressRanges": [],
  "profileTypes": "Private",
  "filePath": "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
  "packageFamilyName": null
}
```

#### CSV
- **Purpose**: Flat table format for manual review in Excel or text editors.
- **Note**: Array fields (e.g., `localPortRanges`) are joined with commas (e.g., `8443`,`9999`).
- **Example**:
```csv
"displayName","description","action","direction","protocol","localPortRanges","remotePortRanges","localAddressRanges","remoteAddressRanges","profileTypes","filePath","packageFamilyName"
"Firefox (C:\Program Files\Mozilla Firefox)","","allow","inbound","6","","","","","Private","C:\Program Files\Mozilla Firefox\firefox.exe",""
```
![image](https://github.com/user-attachments/assets/027ca689-c22e-497c-9cdc-e96662282177)


#### Table
- **Purpose**: Quick console display for `-Compare` mode.
- **Example**:
```
displayName                          action direction protocol localPortRanges remotePortRanges
-----------                          ------ --------- -------- --------------- ----------------
Firefox (C:\Program Files\Mozilla Firefox) allow inbound   6
```

### Workflow

1. **Baseline Capture:**
    * Run `-Capture -CaptureType Baseline` before installing apps to create a baseline (e.g., `baseline.json`).
2. **Install Apps:**
    * Install applications on the reference machine that create firewall rules.
3. **Post-Install Capture:**
    * Run `-Capture -CaptureType PostInstall` to capture rules after installation (e.g., `postinstall.json`).
4. **Compare:**
    * Run `-Compare` with the baseline and post-install JSON files to generate new rules (e.g., `newrules.csv`).
5. **Review:**
    * Use the CSV output for manual Intune policy creation or JSON for future automation.

### Notes

* **Reference Machine:** Use an unmanaged device (no Intune/GPO) to allow apps to create rules freely.
* **Performance:** For large rule sets (e.g., 500+ rules), expect a few minutes of processing time, shown in the final output (e.g., “Time taken: 0 minutes, 18.68 seconds. Rules captured: 38”).
* **Future Plans:** Conversion to a PowerShell module with Microsoft Graph API integration for direct Intune imports is in progress.
* **Generating DefaultRules.json**: To use `-SkipDefaultRules`, create a baseline of default rules on a fresh Windows install with no added apps. Run: `.\RuleForge.ps1 -Capture -CaptureType Baseline -Output DefaultRules.json`
* Place `DefaultRules.json` in the same directory as `RuleForge.ps1`. A sample file for Windows 11 24H2 is available in the repo as `DefaultRules-Win11-24H2.json`. Rename it to `DefaultRules.json` to use.


## Installation

1. Download `RuleForge.ps1` from this repository.
2. Open PowerShell as an Administrator.
3. Navigate to the script directory (e.g., `cd C:\Scripts`).
4. Run the script with desired parameters.


## Contributing

Feel free to fork this repository, submit pull requests, or report issues on GitHub. Feedback is welcome!

## License

This project is open-source and free to use.
