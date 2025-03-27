<#
.SYNOPSIS
    RuleForge.ps1 - A PowerShell script to manage Windows Defender firewall rules for Intune integration.

.DESCRIPTION
    This script captures, compares, and exports Windows Defender firewall rules from a reference machine.
    It’s designed to streamline creating Intune firewall policies by generating a baseline of rules,
    capturing post-installation rules after adding applications, and comparing them to identify new rules.
    Output can be in JSON (for Intune compatibility) or CSV (for manual review). Use on an unmanaged
    reference machine to allow apps to create rules freely, then export them for Intune deployment.
    Running without switches launches an interactive menu.

.VERSION
    1.2.1 (Refactored) - March 2025
    1.2 - Added interactive menu system with return-to-menu and DefaultRules.json check (March 2025)
    1.1 - Added -SkipDefaultRules to exclude default Windows rules (March 2025)
    1.0 - Initial release (February 2025)

.REQUIREMENTS
    - Must be run with PowerShell 7.0 or later (uses NetSecurity module and ?? operator).
    - Must be run as a Local Administrator to access and retrieve firewall rules.

.AUTHOR
    Nathan Hutchinson / ChatGPT 03-mini-high

.WEBSITE
    https://natehutchinson.co.uk

.GITHUB
    https://github.com/NateHutch365
#>

param (
    [switch]$Capture,
    [string]$CaptureType,
    [string]$Output,
    [switch]$Compare,
    [string]$BaselineFile,
    [string]$PostInstallFile,
    [string]$OutputFormat = 'JSON',
    [string]$OutputFile,
    [switch]$SkipDisabled,
    [string]$ProfileType = 'All',
    [switch]$DebugOutput,
    [switch]$SkipDefaultRules
)

#----------------------------------------------
# Helper Functions
#----------------------------------------------

function ConvertTo-IntuneFirewallRule {
    param ($rule)
    Write-Host "Converting rule: $($rule.DisplayName)"
    $portFilter = $rule | Get-NetFirewallPortFilter
    $addressFilter = $rule | Get-NetFirewallAddressFilter
    $appFilter = $rule | Get-NetFirewallApplicationFilter

    $protocolMap = @{ 'TCP' = 6; 'UDP' = 17 }
    $protocol = if ($portFilter.Protocol -match '^\d+$') { [int]$portFilter.Protocol }
                else { $protocolMap[$portFilter.Protocol] ?? 0 }

    $localPorts = @()
    if ($null -ne $portFilter.LocalPort -and $portFilter.LocalPort -ne 'Any') {
        $localPorts = @($portFilter.LocalPort -split ',')
    }

    $remotePorts = @()
    if ($null -ne $portFilter.RemotePort -and $portFilter.RemotePort -ne 'Any') {
        $remotePorts = @($portFilter.RemotePort -split ',')
    }

    $localAddresses = @()
    if ($null -ne $addressFilter.LocalAddress -and $addressFilter.LocalAddress -ne 'Any') {
        $localAddresses = @($addressFilter.LocalAddress -split ',')
    }

    $remoteAddresses = @()
    if ($null -ne $addressFilter.RemoteAddress -and $addressFilter.RemoteAddress -ne 'Any') {
        $remoteAddresses = @($addressFilter.RemoteAddress -split ',')
    }

    [PSCustomObject]@{
        displayName          = $rule.DisplayName
        description          = $rule.Description
        action               = $rule.Action.ToString().ToLower()
        direction            = $rule.Direction.ToString().ToLower()
        protocol             = $protocol
        localPortRanges      = $localPorts
        remotePortRanges     = $remotePorts
        localAddressRanges   = $localAddresses
        remoteAddressRanges  = $remoteAddresses
        profileTypes         = $rule.Profile -split ',' -join ','
        filePath             = $appFilter.Program
        packageFamilyName    = $appFilter.Package
    }
}

function New-DefaultRules {
    Write-Host "Generating DefaultRules.json..."
    $allRules = Get-NetFirewallRule
    $tempRules = @()
    $total = $allRules.Count
    $count = 0
    foreach ($rule in $allRules) {
        $count++
        Write-Progress -Activity "Creating DefaultRules.json" -Status "$count of $total" -PercentComplete (($count / $total) * 100)
        $tempRules += ConvertTo-IntuneFirewallRule $rule
    }
    Write-Progress -Activity "Creating DefaultRules.json" -Completed
    $jsonString = $tempRules | ConvertTo-Json -Depth 5
    # Fix JSON formatting for readability
    $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
    $jsonString | Set-Content -Path "DefaultRules.json"
    Write-Host "Created DefaultRules.json with $($tempRules.Count) rules."
}

function Get-FilteredFirewallRules {
    param(
        [switch]$SkipDisabled,
        [switch]$SkipDefaultRules,
        [string]$ProfileType
    )
    $allRules = Get-NetFirewallRule

    if ($SkipDisabled) {
        Write-Host "Skipping disabled rules..."
        $allRules = $allRules | Where-Object { $_.Enabled -eq 'True' }
    }

    if ($SkipDefaultRules) {
        Write-Host "Loading default rules to skip from DefaultRules.json..."
        try {
            $defaultRules = Get-Content -Path "DefaultRules.json" -ErrorAction Stop | ConvertFrom-Json
            $defaultNames = $defaultRules.displayName
            $allRules = $allRules | Where-Object { $_.DisplayName -notin $defaultNames }
            Write-Host "Skipped $($defaultNames.Count) default rules. Processing $($allRules.Count) remaining rules..."
        } catch {
            Write-Error "Failed to load DefaultRules.json: $_"
            return @()
        }
    }

    $validProfiles = 'Private', 'Public', 'Domain', 'All'
    $selectedProfiles = $ProfileType -split ',' | ForEach-Object { $_.Trim() }
    if ($selectedProfiles -contains 'All') {
        Write-Host "Processing rules for all profiles..."
    } else {
        $invalidProfiles = $selectedProfiles | Where-Object { $_ -notin $validProfiles }
        if ($invalidProfiles) {
            Write-Error "Invalid profile type(s): $invalidProfiles. Use 'Private', 'Public', 'Domain', 'All', or a comma-separated combination."
            return @()
        }
        $allRules = $allRules | Where-Object {
            $ruleProfiles = $_.Profile -split ','
            ($ruleProfiles | Where-Object { $_ -in $selectedProfiles }).Count -gt 0
        }
        Write-Host "Filtering rules for profile(s): $ProfileType..."
    }
    return $allRules
}

function Export-RuleSet {
    param (
        [Parameter(Mandatory=$true)] $rules,
        [Parameter(Mandatory=$true)] [string]$OutputFile,
        [Parameter(Mandatory=$true)] [string]$OutputFormat,
        [switch]$DebugOutput,
        [bool]$DualOutput = $false
    )

    if ($DualOutput -or $OutputFormat -eq 'JSON') {
        # Determine correct JSON file name
        if ([System.IO.Path]::GetExtension($OutputFile).ToLower() -eq ".json") {
            $jsonFile = $OutputFile
        } else {
            $jsonFile = "$OutputFile.json"
        }
        Write-Host "Saving rules to $jsonFile..."
        $jsonString = $rules | ConvertTo-Json -Depth 5
        if ($DebugOutput) {
            Write-Host "Raw JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
        }
        # Preserve JSON formatting for readability
        $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
        if ($DebugOutput) {
            Write-Host "Formatted JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
        }
        $jsonString | Set-Content -Path $jsonFile
        Write-Host "Rules saved to $jsonFile"
    }
    if ($DualOutput -or $OutputFormat -eq 'CSV') {
        # Determine correct CSV file name
        if ([System.IO.Path]::GetExtension($OutputFile).ToLower() -eq ".csv") {
            $csvFile = $OutputFile
        } else {
            $csvFile = "$OutputFile.csv"
        }
        Write-Host "Saving rules to $csvFile..."
        $rules | Select-Object `
            @{Name='displayName';Expression={$_.displayName}},
            @{Name='description';Expression={$_.description}},
            @{Name='action';Expression={$_.action}},
            @{Name='direction';Expression={$_.direction}},
            @{Name='protocol';Expression={$_.protocol}},
            @{Name='localPortRanges';Expression={$_.localPortRanges -join ','}},
            @{Name='remotePortRanges';Expression={$_.remotePortRanges -join ','}},
            @{Name='localAddressRanges';Expression={$_.localAddressRanges -join ','}},
            @{Name='remoteAddressRanges';Expression={$_.remoteAddressRanges -join ','}},
            @{Name='profileTypes';Expression={$_.profileTypes}},
            @{Name='filePath';Expression={$_.filePath}},
            @{Name='packageFamilyName';Expression={$_.packageFamilyName}} `
            | Export-Csv -Path $csvFile -NoTypeInformation
        Write-Host "Rules saved as CSV to $csvFile"
    }
    if (-not $DualOutput -and $OutputFormat -eq 'Table') {
        Write-Host "Displaying rules as table..."
        $rules | Select-Object `
            @{Name='displayName';Expression={$_.displayName}},
            @{Name='action';Expression={$_.action}},
            @{Name='direction';Expression={$_.direction}},
            @{Name='protocol';Expression={$_.protocol}},
            @{Name='localPortRanges';Expression={$_.localPortRanges -join ','}},
            @{Name='remotePortRanges';Expression={$_.remotePortRanges -join ','}} `
            | Format-Table
    }
}

#----------------------------------------------
# Main Script Logic
#----------------------------------------------

$startTime = Get-Date

# If neither -Capture nor -Compare are specified, launch the interactive menu.
if (-not ($Capture -or $Compare)) {
    while ($true) {
        Clear-Host
        Write-Host "$($PSStyle.Foreground.Yellow)**Firing up the forge! - Welcome to RuleForge v1.2 (Refactored) - Blacksmithing Firewall Rules**$($PSStyle.Reset)"
        Write-Host "Select an option:"
        Write-Host "1. Capture Baseline Rules"
        Write-Host "2. Capture Post-Install Rules"
        Write-Host "3. Compare Rules"
        Write-Host "4. Exit"
        $choice = Read-Host "Enter your choice (1-4)"
        
        switch ($choice) {
            "1" {
                $Capture = $true
                $CaptureType = "Baseline"
                $Output = Read-Host "Output filename (press Enter to accept default: baseline.json)"
                if (-not $Output) { $Output = "baseline.json" }
                $OutputFormat = Read-Host "Output format (JSON/CSV, press Enter to accept default: JSON)"
                if (-not $OutputFormat) { $OutputFormat = "JSON" }
                $SkipDisabled = (Read-Host "Skip disabled rules? (Y/N, default: N)") -eq "Y"
                $SkipDefaultInput = Read-Host "Skip default Windows rules? (Y/N, default: N)"
                $SkipDefaultRules = $SkipDefaultInput -eq "Y"
                if ($SkipDefaultRules -and -not (Test-Path "DefaultRules.json")) {
                    Write-Host "Warning: DefaultRules.json not found." -ForegroundColor Yellow
                    $createDefault = Read-Host "Create it now with a full baseline capture? (Y/N) (only use this option on a fresh OOBE device)"
                    if ($createDefault -eq "Y") {
                        New-DefaultRules
                    } else {
                        Write-Host "Proceeding without skipping default rules."
                        $SkipDefaultRules = $false
                    }
                }
                $ProfileType = Read-Host "Profile type (All/Private/Public/Domain, use commas for multiples; default: All)"
                if (-not $ProfileType) { $ProfileType = "All" }
            }
            "2" {
                $Capture = $true
                $CaptureType = "PostInstall"
                $Output = Read-Host "Output filename (press Enter to accept default: postinstall.json)"
                if (-not $Output) { $Output = "postinstall.json" }
                $OutputFormat = Read-Host "Output format (JSON/CSV, press Enter to accept default: JSON)"
                if (-not $OutputFormat) { $OutputFormat = "JSON" }
                $SkipDisabled = (Read-Host "Skip disabled rules? (Y/N, default: N)") -eq "Y"
                $SkipDefaultInput = Read-Host "Skip default Windows rules? (Y/N, default: N)"
                $SkipDefaultRules = $SkipDefaultInput -eq "Y"
                if ($SkipDefaultRules -and -not (Test-Path "DefaultRules.json")) {
                    Write-Host "Warning: DefaultRules.json not found." -ForegroundColor Yellow
                    $createDefault = Read-Host "Create it now with a full baseline capture? (Y/N) (only use this option on a fresh OOBE device)"
                    if ($createDefault -eq "Y") {
                        New-DefaultRules
                    } else {
                        Write-Host "Proceeding without skipping default rules."
                        $SkipDefaultRules = $false
                    }
                }
                $ProfileType = Read-Host "Profile type (All/Private/Public/Domain, use commas for multiples; default: All)"
                if (-not $ProfileType) { $ProfileType = "All" }
            }
            "3" {
                $Compare = $true
                $BaselineFile = Read-Host "Baseline file (default: baseline.json)"
                if (-not $BaselineFile) { $BaselineFile = "baseline.json" }
                $PostInstallFile = Read-Host "Post-install file (default: postinstall.json)"
                if (-not $PostInstallFile) { $PostInstallFile = "postinstall.json" }
                $OutputFile = Read-Host "Output file prefix (default: newrules)"
                if (-not $OutputFile) { $OutputFile = "newrules" }
                $dualOutput = (Read-Host "Export as both JSON and CSV? (Y/N, default: Y)") -ne "N"
                if (-not $dualOutput) {
                    $OutputFormat = Read-Host "Output format (JSON/CSV/Table, default: JSON)"
                    if (-not $OutputFormat) { $OutputFormat = "JSON" }
                }
            }
            "4" {
                Write-Host "$($PSStyle.Foreground.Red)Extinguishing the forge – RuleForge stopped. Happy blacksmithing!$($PSStyle.Reset)"
                exit
            }
            default {
                Write-Host "Invalid choice, press Enter to try again." -ForegroundColor Red
                Read-Host
                continue
            }
        }

        Write-Host "Script started..."
        if ($Capture) {
            Write-Host "Capture mode activated with type: $CaptureType"
            if ($CaptureType -in 'Baseline','PostInstall') {
                Write-Host "Fetching firewall rules..."
                $allRules = Get-FilteredFirewallRules -SkipDisabled:$SkipDisabled -SkipDefaultRules:$SkipDefaultRules -ProfileType $ProfileType
                Write-Host "Processing $($allRules.Count) rules..."
                $rules = @()
                $total = $allRules.Count
                $count = 0
                foreach ($rule in $allRules) {
                    $count++
                    Write-Progress -Activity "Converting firewall rules" -Status "$count of $total" -PercentComplete (($count / $total) * 100)
                    $rules += ConvertTo-IntuneFirewallRule $rule
                }
                Write-Progress -Activity "Converting firewall rules" -Completed
                Write-Host "Saving rules to $Output..."
                Export-RuleSet -rules $rules -OutputFile $Output -OutputFormat $OutputFormat -DebugOutput:$DebugOutput
                Write-Host "Rules captured to $Output"
                $ruleCount = $rules.Count
            } else {
                Write-Error "Invalid CaptureType. Use 'Baseline' or 'PostInstall'."
            }
        } elseif ($Compare) {
            Write-Host "Compare mode activated with files: $BaselineFile and $PostInstallFile"
            if ($BaselineFile -and $PostInstallFile) {
                Write-Host "Loading baseline rules from $BaselineFile..."
                $baselineRules = Get-Content $BaselineFile | ConvertFrom-Json
                Write-Host "Loading post-install rules from $PostInstallFile..."
                $postinstallRules = Get-Content $PostInstallFile | ConvertFrom-Json
                Write-Host "Comparing rules..."
                $baselineNames = $baselineRules.displayName
                $newRules = $postinstallRules | Where-Object { $_.displayName -notin $baselineNames }
                Export-RuleSet -rules $newRules -OutputFile $OutputFile -OutputFormat $OutputFormat -DebugOutput:$DebugOutput -DualOutput:$dualOutput
            } else {
                Write-Error "BaselineFile and PostInstallFile are required."
            }
        } else {
            Write-Error "Specify either -Capture or -Compare when bypassing the menu."
        }

        $endTime = Get-Date
        $timeTaken = $endTime - $startTime
        $minutes = [math]::Floor($timeTaken.TotalSeconds / 60)
        $seconds = [math]::Round($timeTaken.TotalSeconds % 60, 2)
        if ($Capture -and $CaptureType -in 'Baseline','PostInstall') {
            Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds. Rules captured: $ruleCount."
        } else {
            Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds."
        }
        Write-Host "Press Enter to return to the menu..."
        Read-Host
        # Reset mode variables for next loop iteration
        $Capture = $false
        $Compare = $false
    }
} else {
    # CLI Mode Logic
    Write-Host "Script started..."
    if ($Capture) {
        Write-Host "Capture mode activated with type: $CaptureType"
        if ($CaptureType -in 'Baseline','PostInstall') {
            Write-Host "Fetching firewall rules..."
            $allRules = Get-FilteredFirewallRules -SkipDisabled:$SkipDisabled -SkipDefaultRules:$SkipDefaultRules -ProfileType $ProfileType
            Write-Host "Processing $($allRules.Count) rules..."
            $rules = @()
            $total = $allRules.Count
            $count = 0
            foreach ($rule in $allRules) {
                $count++
                Write-Progress -Activity "Converting firewall rules" -Status "$count of $total" -PercentComplete (($count / $total) * 100)
                $rules += ConvertTo-IntuneFirewallRule $rule
            }
            Write-Progress -Activity "Converting firewall rules" -Completed
            Write-Host "Saving rules to $Output..."
            Export-RuleSet -rules $rules -OutputFile $Output -OutputFormat $OutputFormat -DebugOutput:$DebugOutput
            Write-Host "Rules captured to $Output"
            $ruleCount = $rules.Count
        } else {
            Write-Error "Invalid CaptureType. Use 'Baseline' or 'PostInstall'."
        }
    } elseif ($Compare) {
        Write-Host "Compare mode activated with files: $BaselineFile and $PostInstallFile"
        if ($BaselineFile -and $PostInstallFile) {
            Write-Host "Loading baseline rules from $BaselineFile..."
            $baselineRules = Get-Content $BaselineFile | ConvertFrom-Json
            Write-Host "Loading post-install rules from $PostInstallFile..."
            $postinstallRules = Get-Content $PostInstallFile | ConvertFrom-Json
            Write-Host "Comparing rules..."
            $baselineNames = $baselineRules.displayName
            $newRules = $postinstallRules | Where-Object { $_.displayName -notin $baselineNames }
            Export-RuleSet -rules $newRules -OutputFile $OutputFile -OutputFormat $OutputFormat -DebugOutput:$DebugOutput
        } else {
            Write-Error "BaselineFile and PostInstallFile are required."
        }
    } else {
        Write-Error "Specify either -Capture or -Compare when bypassing the menu."
    }

    $endTime = Get-Date
    $timeTaken = $endTime - $startTime
    $minutes = [math]::Floor($timeTaken.TotalSeconds / 60)
    $seconds = [math]::Round($timeTaken.TotalSeconds % 60, 2)
    if ($Capture -and $CaptureType -in 'Baseline','PostInstall') {
        Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds. Rules captured: $ruleCount."
    } else {
        Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds."
    }
}