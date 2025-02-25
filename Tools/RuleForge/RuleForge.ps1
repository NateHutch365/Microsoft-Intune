<#
.SYNOPSIS
    RuleForge.ps1 - A PowerShell script to manage Windows Defender firewall rules for Intune integration.

.DESCRIPTION
    This script captures, compares, and exports Windows Defender firewall rules from a reference machine.
    It’s designed to streamline creating Intune firewall policies by generating a baseline of rules,
    capturing post-installation rules after adding applications, and comparing them to identify new rules.
    Output can be in JSON (for Intune compatibility) or CSV (for manual review). Use on an unmanaged
    reference machine to allow apps to create rules freely, then export them for Intune deployment.

.VERSION
    1.0

.REQUIREMENTS
    - Must be run with PowerShell as a Local Administrator to access and retrieve firewall rules.
    - Windows PowerShell 5.1 or later recommended (uses NetSecurity module cmdlets).

.AUTHOR
    Nathan Hutchinson

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
    [switch]$DebugOutput
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

    # Return object with arrays intact for JSON, we'll flatten for CSV later
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
            $rules | ForEach-Object {
                [PSCustomObject]@{
                    displayName = $_.displayName
                    description = $_.description
                    action = $_.action
                    direction = $_.direction
                    protocol = $_.protocol
                    localPortRanges = $_.localPortRanges -join ','
                    remotePortRanges = $_.remotePortRanges -join ','
                    localAddressRanges = $_.localAddressRanges -join ','
                    remoteAddressRanges = $_.remoteAddressRanges -join ','
                    profileTypes = $_.profileTypes
                    filePath = $_.filePath
                    packageFamilyName = $_.packageFamilyName
                }
            } | Export-Csv -Path $csvPath -NoTypeInformation
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
        
        if ($OutputFormat -eq 'JSON') {
            Write-Host "Saving new rules to $OutputFile..."
            $jsonString = $newRules | ConvertTo-Json -Depth 5
            if ($DebugOutput) {
                Write-Host "Raw JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
            }
            $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
            if ($DebugOutput) {
                Write-Host "Formatted JSON snippet (first 200 chars): $($jsonString.Substring(0, [Math]::Min(200, $jsonString.Length)))"
            }
            $jsonString | Set-Content -Path $OutputFile
            Write-Host "New rules saved to $OutputFile"
        } elseif ($OutputFormat -eq 'CSV') {
            Write-Host "Saving new rules to $OutputFile..."
            $csvPath = [System.IO.Path]::ChangeExtension($OutputFile, '.csv')
            $newRules | ForEach-Object {
                [PSCustomObject]@{
                    displayName = $_.displayName
                    description = $_.description
                    action = $_.action
                    direction = $_.direction
                    protocol = $_.protocol
                    localPortRanges = $_.localPortRanges -join ','
                    remotePortRanges = $_.remotePortRanges -join ','
                    localAddressRanges = $_.localAddressRanges -join ','
                    remoteAddressRanges = $_.remoteAddressRanges -join ','
                    profileTypes = $_.profileTypes
                    filePath = $_.filePath
                    packageFamilyName = $_.packageFamilyName
                }
            } | Export-Csv -Path $csvPath -NoTypeInformation
            Write-Host "New rules saved as CSV to $csvPath"
        } elseif ($OutputFormat -eq 'Table') {
            Write-Host "Displaying new rules as table..."
            $newRules | Select-Object displayName, action, direction, protocol, localPortRanges, remotePortRanges | Format-Table
        } else {
            Write-Error "Invalid OutputFormat. Use 'JSON', 'CSV', or 'Table'."
            return
        }
    } else {
        Write-Error "BaselineFile and PostInstallFile are required."
    }
} else {
    Write-Error "Specify either -Capture or -Compare."
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