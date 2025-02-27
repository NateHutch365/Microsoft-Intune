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
    1.2 - Added interactive menu system with return-to-menu and DefaultRules.json check (March 2025)
    1.1 - Added -SkipDefaultRules to exclude default Windows rules (March 2025)
    1.0 - Initial release (February 2025)

.REQUIREMENTS
    - Must be run with PowerShell 7.0 or later (uses NetSecurity module and ?? operator).
    - Must be run as a Local Administrator to access and retrieve firewall rules.

.AUTHOR
    Nathan Hutchinson / Grok3

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
        displayName = $rule.DisplayName
        description = $rule.Description
        action = $rule.Action.ToString().ToLower()
        direction = $rule.Direction.ToString().ToLower()
        protocol = $protocol
        localPortRanges = $localPorts
        remotePortRanges = $remotePorts
        localAddressRanges = $localAddresses
        remoteAddressRanges = $remoteAddresses
        profileTypes = $rule.Profile -split ',' -join ','
        filePath = $appFilter.Program
        packageFamilyName = $appFilter.Package
    }
}

# Interactive Menu if no switches provided
if (-not ($Capture -or $Compare)) {
    while ($true) {
        Clear-Host
        Write-Host "$($PSStyle.Foreground.Yellow)**Firing up the forge! - Welcome to RuleForge v1.2 - Blacksmithing Firewall Rules**$($PSStyle.Reset)"
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
                    $createDefault = Read-Host "Create it now with a full baseline capture? (Y/N) (only use this option if you are on a fresh device following the OOBE experience)"
                    if ($createDefault -eq "Y") {
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
                        $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
                        $jsonString | Set-Content -Path "DefaultRules.json"
                        Write-Host "Created DefaultRules.json with $($tempRules.Count) rules."
                    } else {
                        Write-Host "Proceeding without skipping default rules."
                        $SkipDefaultRules = $false
                    }
                }
                $ProfileType = Read-Host "Profile type (All/Private/Public/Domain, use commas for multiples e.g., Private,Public; press Enter to accept default: All)"
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
                    $createDefault = Read-Host "Create it now with a full baseline capture? (Y/N) (only use this option if you are on a fresh device following the OOBE experience)"
                    if ($createDefault -eq "Y") {
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
                        $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
                        $jsonString | Set-Content -Path "DefaultRules.json"
                        Write-Host "Created DefaultRules.json with $($tempRules.Count) rules."
                    } else {
                        Write-Host "Proceeding without skipping default rules."
                        $SkipDefaultRules = $false
                    }
                }
                $ProfileType = Read-Host "Profile type (All/Private/Public/Domain, use commas for multiples e.g., Private,Public; press Enter to accept default: All)"
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
        $startTime = Get-Date

        if ($Capture) {
            Write-Host "Capture mode activated with type: $CaptureType"
            if ($CaptureType -in 'Baseline', 'PostInstall') {
                Write-Host "Fetching firewall rules..."
                $allRules = Get-NetFirewallRule
                
                if ($SkipDisabled) {
                    $allRules = $allRules | Where-Object { $_.Enabled -eq 'True' }
                    Write-Host "Skipping disabled rules..."
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
                        return
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
                        return
                    }
                    $allRules = $allRules | Where-Object { 
                        $ruleProfiles = $_.Profile -split ','
                        ($ruleProfiles | Where-Object { $_ -in $selectedProfiles }).Count -gt 0
                    }
                    Write-Host "Filtering rules for profile(s): $ProfileType..."
                }

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
                if ($OutputFormat -eq 'JSON') {
                    $jsonString = $rules | ConvertTo-Json -Depth 5
                    if ($DebugOutput) {
                        Write-Host "Raw JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                    }
                    $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
                    if ($DebugOutput) {
                        Write-Host "Formatted JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                    }
                    $jsonString | Set-Content -Path $Output
                } elseif ($OutputFormat -eq 'CSV') {
                    $csvPath = [System.IO.Path]::ChangeExtension($Output, '.csv')
                    $rules | Select-Object @{Name='displayName';Expression={$_.displayName}},
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
                           | Export-Csv -Path $csvPath -NoTypeInformation
                    Write-Host "Rules saved as CSV to $csvPath"
                } else {
                    Write-Error "Invalid OutputFormat for Capture mode. Use 'JSON' or 'CSV'."
                    return
                }
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
                
                if ($dualOutput -or $OutputFormat -eq 'JSON') {
                    Write-Host "Saving new rules to $OutputFile.json..."
                    $jsonString = $newRules | ConvertTo-Json -Depth 5
                    if ($DebugOutput) {
                        Write-Host "Raw JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                    }
                    $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
                    if ($DebugOutput) {
                        Write-Host "Formatted JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                    }
                    $jsonString | Set-Content -Path "$OutputFile.json"
                    Write-Host "New rules saved to $OutputFile.json"
                }
                if ($dualOutput -or $OutputFormat -eq 'CSV') {
                    Write-Host "Saving new rules to $OutputFile.csv..."
                    $newRules | Select-Object @{Name='displayName';Expression={$_.displayName}},
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
                              | Export-Csv -Path "$OutputFile.csv" -NoTypeInformation
                    Write-Host "New rules saved as CSV to $OutputFile.csv"
                }
                if ($OutputFormat -eq 'Table') {
                    Write-Host "Displaying new rules as table..."
                    $newRules | Select-Object @{Name='displayName';Expression={$_.displayName}},
                                              @{Name='action';Expression={$_.action}},
                                              @{Name='direction';Expression={$_.direction}},
                                              @{Name='protocol';Expression={$_.protocol}},
                                              @{Name='localPortRanges';Expression={$_.localPortRanges -join ','}},
                                              @{Name='remotePortRanges';Expression={$_.remotePortRanges -join ','}} `
                              | Format-Table
                } elseif (-not $dualOutput -and $OutputFormat -notin 'JSON', 'CSV') {
                    Write-Error "Invalid OutputFormat. Use 'JSON', 'CSV', or 'Table'."
                }
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
        if ($Capture -and $CaptureType -in 'Baseline', 'PostInstall') {
            Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds. Rules captured: $ruleCount."
        } else {
            Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds."
        }

        Write-Host "Press Enter to return to the menu..."
        Read-Host
        $Capture = $false
        $Compare = $false
    }
} else {
    # CLI mode logic (unchanged)
    Write-Host "Script started..."
    $startTime = Get-Date

    if ($Capture) {
        Write-Host "Capture mode activated with type: $CaptureType"
        if ($CaptureType -in 'Baseline', 'PostInstall') {
            Write-Host "Fetching firewall rules..."
            $allRules = Get-NetFirewallRule
            
            if ($SkipDisabled) {
                $allRules = $allRules | Where-Object { $_.Enabled -eq 'True' }
                Write-Host "Skipping disabled rules..."
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
                    return
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
                    return
                }
                $allRules = $allRules | Where-Object { 
                    $ruleProfiles = $_.Profile -split ','
                    ($ruleProfiles | Where-Object { $_ -in $selectedProfiles }).Count -gt 0
                }
                Write-Host "Filtering rules for profile(s): $ProfileType..."
            }

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
            if ($OutputFormat -eq 'JSON') {
                $jsonString = $rules | ConvertTo-Json -Depth 5
                if ($DebugOutput) {
                    Write-Host "Raw JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                }
                $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
                if ($DebugOutput) {
                    Write-Host "Formatted JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                }
                $jsonString | Set-Content -Path $Output
            } elseif ($OutputFormat -eq 'CSV') {
                $csvPath = [System.IO.Path]::ChangeExtension($Output, '.csv')
                $rules | Select-Object @{Name='displayName';Expression={$_.displayName}},
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
                       | Export-Csv -Path $csvPath -NoTypeInformation
                Write-Host "Rules saved as CSV to $csvPath"
            } else {
                Write-Error "Invalid OutputFormat for Capture mode. Use 'JSON' or 'CSV'."
                return
            }
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
            
            if ($dualOutput -or $OutputFormat -eq 'JSON') {
                Write-Host "Saving new rules to $OutputFile.json..."
                $jsonString = $newRules | ConvertTo-Json -Depth 5
                if ($DebugOutput) {
                    Write-Host "Raw JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                }
                $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
                if ($DebugOutput) {
                    Write-Host "Formatted JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
                }
                $jsonString | Set-Content -Path "$OutputFile.json"
                Write-Host "New rules saved to $OutputFile.json"
            }
            if ($dualOutput -or $OutputFormat -eq 'CSV') {
                Write-Host "Saving new rules to $OutputFile.csv..."
                $newRules | Select-Object @{Name='displayName';Expression={$_.displayName}},
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
                          | Export-Csv -Path "$OutputFile.csv" -NoTypeInformation
                Write-Host "New rules saved as CSV to $OutputFile.csv"
            }
            if ($OutputFormat -eq 'Table') {
                Write-Host "Displaying new rules as table..."
                $newRules | Select-Object @{Name='displayName';Expression={$_.displayName}},
                                          @{Name='action';Expression={$_.action}},
                                          @{Name='direction';Expression={$_.direction}},
                                          @{Name='protocol';Expression={$_.protocol}},
                                          @{Name='localPortRanges';Expression={$_.localPortRanges -join ','}},
                                          @{Name='remotePortRanges';Expression={$_.remotePortRanges -join ','}} `
                          | Format-Table
            } elseif (-not $dualOutput -and $OutputFormat -notin 'JSON', 'CSV') {
                Write-Error "Invalid OutputFormat. Use 'JSON', 'CSV', or 'Table'."
                return
            }
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
    if ($Capture -and $CaptureType -in 'Baseline', 'PostInstall') {
        Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds. Rules captured: $ruleCount."
    } else {
        Write-Host "Script finished. Time taken: $minutes minutes, $seconds seconds."
    }
}