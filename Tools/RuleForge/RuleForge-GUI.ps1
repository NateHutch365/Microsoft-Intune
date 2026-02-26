<#
.SYNOPSIS
    RuleForge-GUI.ps1 - A WPF GUI for managing Windows Defender firewall rules for Intune integration.

.DESCRIPTION
    This script provides a graphical user interface for RuleForge, wrapping all the functionality of the
    CLI version (RuleForge.ps1) in a WPF-based application. It captures, compares, and exports Windows
    Defender firewall rules with a visual progress tracker and debug logging.

    Features:
    - WPF-based GUI with Capture and Compare tabs
    - Real-time progress bar for rule capture and comparison operations
    - Debug log panel with file logging for troubleshooting
    - File browse dialogs for input/output file selection
    - All filter options from the CLI version (skip disabled, skip defaults, profile type)
    - Background processing to keep the UI responsive during operations

.VERSION
    2.0.0 - GUI Edition

.REQUIREMENTS
    - Windows PowerShell 5.1 or PowerShell 7.x on Windows
    - Must be run as Local Administrator to access firewall rules
    - NetSecurity module (built into Windows)
    - .NET Framework / WPF assemblies (included with Windows)

.AUTHOR
    Nathan Hutchinson

.NOTES
    The original CLI version (RuleForge.ps1) is preserved alongside this GUI version.
    Admins can choose whichever interface suits their workflow.

.WEBSITE
    https://natehutchinson.co.uk

.GITHUB
    https://github.com/NateHutch365
#>

#Requires -Version 5.1

# ============================================================================
# Region: Assembly Loading
# ============================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ============================================================================
# Region: Script-Level Variables
# ============================================================================
# Resolve app directory safely for both .ps1 and packaged .exe
$script:ScriptDir = if ($PSScriptRoot -and (Test-Path -LiteralPath $PSScriptRoot)) {
    $PSScriptRoot
}
elseif ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
    Split-Path -Parent $PSCommandPath
}
elseif ($MyInvocation.MyCommand.Path -and (Test-Path -LiteralPath $MyInvocation.MyCommand.Path)) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
else {
    [System.AppDomain]::CurrentDomain.BaseDirectory
}

$script:LogFile = Join-Path $script:ScriptDir "RuleForge-Debug.log"
$script:SyncHash = [hashtable]::Synchronized(@{})
$script:SyncHash.LogQueue = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$script:SyncHash.Progress = 0
$script:SyncHash.StatusMessage = ""
$script:SyncHash.IsRunning = $false
$script:SyncHash.Completed = $false
$script:SyncHash.Error = $null
$script:SyncHash.CancelRequested = $false
$script:CurrentRunspace = $null
$script:CurrentPowerShell = $null

# ============================================================================
# Region: Debug Logging (UI Thread)
# ============================================================================
function Write-DebugLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $entry = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $script:LogFile -Value $entry -ErrorAction SilentlyContinue
    } catch { }
    return $entry
}

# ============================================================================
# Region: XAML GUI Definition
# ============================================================================
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="RuleForge v2.0 GUI - Firewall Rule Manager for Intune"
    Height="780" Width="920"
    MinHeight="650" MinWidth="750"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResizeWithGrip">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="160"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Row 0: Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,8">
            <TextBlock Text="RuleForge v2.0" FontSize="22" FontWeight="Bold"
                       Foreground="DarkOrange" HorizontalAlignment="Center"/>
            <TextBlock Text="Blacksmithing Firewall Rules for Microsoft Intune"
                       FontSize="11" Foreground="Gray" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>

        <!-- Row 1: Tab Control -->
        <TabControl Grid.Row="1" Name="MainTabControl" Margin="0,0,0,5">

            <!-- Capture Tab -->
            <TabItem Header="  Capture Rules  " Name="CaptureTab">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="5">
                    <StackPanel Margin="10">

                        <GroupBox Header="Capture Type" Margin="0,0,0,8" Padding="8">
                            <StackPanel Orientation="Horizontal">
                                <RadioButton Name="BaselineRadio" Content="Baseline"
                                             IsChecked="True" Margin="0,0,25,0" VerticalContentAlignment="Center"/>
                                <RadioButton Name="PostInstallRadio" Content="Post-Install"
                                             VerticalContentAlignment="Center"/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox Header="Output Settings" Margin="0,0,0,8" Padding="8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="110"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>

                                <TextBlock Grid.Row="0" Grid.Column="0" Text="Output File:"
                                           VerticalAlignment="Center" Margin="0,0,0,6"/>
                                <TextBox Grid.Row="0" Grid.Column="1" Name="CaptureOutputFile"
                                         Text="baseline.json" Margin="0,0,5,6" Padding="4"/>
                                <Button Grid.Row="0" Grid.Column="2" Name="CaptureOutputBrowse"
                                        Content="Browse..." Width="75" Margin="0,0,0,6"/>

                                <TextBlock Grid.Row="1" Grid.Column="0" Text="Output Format:"
                                           VerticalAlignment="Center"/>
                                <ComboBox Grid.Row="1" Grid.Column="1" Name="CaptureOutputFormat"
                                          SelectedIndex="0" Padding="4" Margin="0,0,5,0">
                                    <ComboBoxItem Content="JSON"/>
                                    <ComboBoxItem Content="CSV"/>
                                </ComboBox>
                            </Grid>
                        </GroupBox>

                        <GroupBox Header="Filter Options" Margin="0,0,0,8" Padding="8">
                            <StackPanel>
                                <CheckBox Name="SkipDisabledCheck" Content="Skip disabled rules"
                                          Margin="0,0,0,6"/>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                    <CheckBox Name="SkipDefaultCheck"
                                              Content="Skip default Windows rules (requires DefaultRules.json)"
                                              Margin="0,0,10,0" VerticalContentAlignment="Center"/>
                                    <Button Name="GenerateDefaultRulesBtn"
                                            Content="Generate DefaultRules.json" FontSize="11" Padding="6,2"/>
                                </StackPanel>
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock Text="Profile Type:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <ComboBox Name="ProfileTypeCombo" SelectedIndex="0" Width="180" Padding="4">
                                        <ComboBoxItem Content="All"/>
                                        <ComboBoxItem Content="Private"/>
                                        <ComboBoxItem Content="Public"/>
                                        <ComboBoxItem Content="Domain"/>
                                        <ComboBoxItem Content="Private,Public"/>
                                        <ComboBoxItem Content="Private,Domain"/>
                                        <ComboBoxItem Content="Public,Domain"/>
                                        <ComboBoxItem Content="Private,Public,Domain"/>
                                    </ComboBox>
                                </StackPanel>
                            </StackPanel>
                        </GroupBox>

                        <Button Name="StartCaptureBtn" Content="Start Capture" FontSize="14"
                                FontWeight="Bold" Height="38" Margin="0,5,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Compare Tab -->
            <TabItem Header="  Compare Rules  " Name="CompareTab">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="5">
                    <StackPanel Margin="10">

                        <GroupBox Header="Input Files" Margin="0,0,0,8" Padding="8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="110"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>

                                <TextBlock Grid.Row="0" Grid.Column="0" Text="Baseline File:"
                                           VerticalAlignment="Center" Margin="0,0,0,6"/>
                                <TextBox Grid.Row="0" Grid.Column="1" Name="BaselineFileInput"
                                         Text="baseline.json" Margin="0,0,5,6" Padding="4"/>
                                <Button Grid.Row="0" Grid.Column="2" Name="BaselineBrowse"
                                        Content="Browse..." Width="75" Margin="0,0,0,6"/>

                                <TextBlock Grid.Row="1" Grid.Column="0" Text="Post-Install File:"
                                           VerticalAlignment="Center"/>
                                <TextBox Grid.Row="1" Grid.Column="1" Name="PostInstallFileInput"
                                         Text="postinstall.json" Margin="0,0,5,0" Padding="4"/>
                                <Button Grid.Row="1" Grid.Column="2" Name="PostInstallBrowse"
                                        Content="Browse..." Width="75"/>
                            </Grid>
                        </GroupBox>

                        <GroupBox Header="Output Settings" Margin="0,0,0,8" Padding="8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="110"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>

                                <TextBlock Grid.Row="0" Grid.Column="0" Text="Output Prefix:"
                                           VerticalAlignment="Center" Margin="0,0,0,6"/>
                                <TextBox Grid.Row="0" Grid.Column="1" Name="CompareOutputFile"
                                         Text="newrules" Margin="0,0,5,6" Padding="4"/>
                                <Button Grid.Row="0" Grid.Column="2" Name="CompareOutputBrowse"
                                        Content="Browse..." Width="75" Margin="0,0,0,6"/>

                                <CheckBox Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="3" Name="DualOutputCheck"
                                          Content="Export as both JSON and CSV" IsChecked="True" Margin="0,0,0,6"/>

                                <TextBlock Grid.Row="2" Grid.Column="0" Text="Output Format:"
                                           VerticalAlignment="Center" Name="CompareFormatLabel"/>
                                <ComboBox Grid.Row="2" Grid.Column="1" Name="CompareOutputFormat"
                                          SelectedIndex="0" Padding="4" Margin="0,0,5,0" IsEnabled="False">
                                    <ComboBoxItem Content="JSON"/>
                                    <ComboBoxItem Content="CSV"/>
                                    <ComboBoxItem Content="Table"/>
                                </ComboBox>
                            </Grid>
                        </GroupBox>

                        <Button Name="StartCompareBtn" Content="Start Compare" FontSize="14"
                                FontWeight="Bold" Height="38" Margin="0,5,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>

        <!-- Row 2: Progress Bar -->
        <StackPanel Grid.Row="2" Margin="0,5,0,0">
            <Grid>
                <ProgressBar Name="ProgressBar" Height="26" Minimum="0" Maximum="100" Value="0"/>
                <TextBlock Name="ProgressText" Text="0%" HorizontalAlignment="Center"
                           VerticalAlignment="Center" FontWeight="Bold"/>
            </Grid>
            <TextBlock Name="StatusText" Text="Ready - Welcome to RuleForge!"
                       Foreground="Gray" Margin="0,4,0,0" TextWrapping="Wrap"/>
        </StackPanel>

        <!-- Row 3: Log Header -->
        <DockPanel Grid.Row="3" Margin="0,8,0,2">
            <TextBlock Text="Debug Log" FontWeight="Bold" VerticalAlignment="Center"
                       DockPanel.Dock="Left" Margin="0,0,10,0"/>
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                <Button Name="ClearLogBtn" Content="Clear" Width="55" FontSize="10" Height="22"/>
                <Button Name="SaveLogBtn" Content="Save Log" Width="65" FontSize="10"
                        Height="22" Margin="5,0,0,0"/>
                <Button Name="OpenLogFileBtn" Content="Open Log File" Width="85" FontSize="10"
                        Height="22" Margin="5,0,0,0"/>
            </StackPanel>
            <Border/>
        </DockPanel>

        <!-- Row 4: Log Box -->
        <TextBox Grid.Row="4" Name="LogBox" IsReadOnly="True" TextWrapping="NoWrap"
                 VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                 Background="#1E1E1E" Foreground="#00FF00" FontFamily="Consolas" FontSize="11"
                 AcceptsReturn="True" Padding="5"/>

        <!-- Row 5: Bottom Buttons -->
        <DockPanel Grid.Row="5" Margin="0,8,0,0">
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                <Button Name="CancelBtn" Content="Cancel Operation" Width="120" Height="30"
                        IsEnabled="False" Margin="0,0,8,0"/>
                <Button Name="ExitBtn" Content="Exit" Width="80" Height="30"/>
            </StackPanel>
            <Border/>
        </DockPanel>
    </Grid>
</Window>
"@

# ============================================================================
# Region: Window and Control Initialization
# ============================================================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find all named controls
$mainTabControl       = $window.FindName("MainTabControl")
$baselineRadio        = $window.FindName("BaselineRadio")
$postInstallRadio     = $window.FindName("PostInstallRadio")
$captureOutputFile    = $window.FindName("CaptureOutputFile")
$captureOutputBrowse  = $window.FindName("CaptureOutputBrowse")
$captureOutputFormat  = $window.FindName("CaptureOutputFormat")
$skipDisabledCheck    = $window.FindName("SkipDisabledCheck")
$skipDefaultCheck     = $window.FindName("SkipDefaultCheck")
$generateDefaultBtn   = $window.FindName("GenerateDefaultRulesBtn")
$profileTypeCombo     = $window.FindName("ProfileTypeCombo")
$startCaptureBtn      = $window.FindName("StartCaptureBtn")

$baselineFileInput    = $window.FindName("BaselineFileInput")
$baselineBrowse       = $window.FindName("BaselineBrowse")
$postInstallFileInput = $window.FindName("PostInstallFileInput")
$postInstallBrowse    = $window.FindName("PostInstallBrowse")
$compareOutputFile    = $window.FindName("CompareOutputFile")
$compareOutputBrowse  = $window.FindName("CompareOutputBrowse")
$dualOutputCheck      = $window.FindName("DualOutputCheck")
$compareOutputFormat  = $window.FindName("CompareOutputFormat")
$startCompareBtn      = $window.FindName("StartCompareBtn")

$progressBar          = $window.FindName("ProgressBar")
$progressText         = $window.FindName("ProgressText")
$statusText           = $window.FindName("StatusText")
$logBox               = $window.FindName("LogBox")
$clearLogBtn          = $window.FindName("ClearLogBtn")
$saveLogBtn           = $window.FindName("SaveLogBtn")
$openLogFileBtn       = $window.FindName("OpenLogFileBtn")
$cancelBtn            = $window.FindName("CancelBtn")
$exitBtn              = $window.FindName("ExitBtn")

# Store references in SyncHash for background thread access
$script:SyncHash.Window = $window

# ============================================================================
# Region: UI Helper Functions
# ============================================================================
function Append-Log {
    param([string]$Entry)
    $logBox.AppendText("$Entry`r`n")
    $logBox.ScrollToEnd()
}

function Update-UIState {
    param([bool]$Running)
    $startCaptureBtn.IsEnabled    = -not $Running
    $startCompareBtn.IsEnabled    = -not $Running
    $generateDefaultBtn.IsEnabled = -not $Running
    $cancelBtn.IsEnabled          = $Running
    $mainTabControl.IsEnabled     = -not $Running
}

function Show-SaveFileDialog {
    param(
        [string]$DefaultName = "output.json",
        [string]$Filter = "JSON Files (*.json)|*.json|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
    )
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.FileName = $DefaultName
    $dialog.Filter = $Filter
    $dialog.InitialDirectory = $script:ScriptDir
    if ($dialog.ShowDialog() -eq $true) {
        return $dialog.FileName
    }
    return $null
}

function Show-OpenFileDialog {
    param(
        [string]$Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    )
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = $Filter
    $dialog.InitialDirectory = $script:ScriptDir
    if ($dialog.ShowDialog() -eq $true) {
        return $dialog.FileName
    }
    return $null
}

# ============================================================================
# Region: Background Operation Runner
# ============================================================================
function Start-BackgroundOperation {
    param(
        [scriptblock]$ScriptBlock,
        [hashtable]$Parameters
    )

    $script:SyncHash.Progress = 0
    $script:SyncHash.StatusMessage = "Starting operation..."
    $script:SyncHash.IsRunning = $true
    $script:SyncHash.Completed = $false
    $script:SyncHash.Error = $null
    $script:SyncHash.CancelRequested = $false
    $script:SyncHash.LogQueue.Clear()

    Update-UIState -Running $true
    $progressBar.Value = 0
    $progressText.Text = "0%"

    $entry = Write-DebugLog "Starting background operation" "INFO"
    Append-Log $entry

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("syncHash", $script:SyncHash)
    $runspace.SessionStateProxy.SetVariable("params", $Parameters)
    $runspace.SessionStateProxy.SetVariable("scriptDir", $script:ScriptDir)
    $runspace.SessionStateProxy.SetVariable("logFilePath", $script:LogFile)
    $runspace.SessionStateProxy.SetVariable("sharedFunctions", $script:SharedFunctions)

    $psCmd = [powershell]::Create()
    $psCmd.Runspace = $runspace
    $psCmd.AddScript($ScriptBlock) | Out-Null

    $script:CurrentRunspace = $runspace
    $script:CurrentPowerShell = $psCmd
    $script:CurrentHandle = $psCmd.BeginInvoke()

    # Start the UI update timer
    $script:UpdateTimer.Start()
}

# ============================================================================
# Region: Shared Functions for Background Runspaces
# ============================================================================
# Functions defined here are injected into each background runspace via
# SessionStateProxy to avoid code duplication across scriptblocks.
$script:SharedFunctions = @'
function Add-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $entry = "[$timestamp] [$Level] $Message"
    $syncHash.LogQueue.Add($entry) | Out-Null
    try {
        Add-Content -Path $logFilePath -Value $entry -ErrorAction SilentlyContinue
    } catch { }
}

function ConvertTo-IntuneFirewallRule {
    param($rule)
    Add-Log "Converting rule: $($rule.DisplayName)" "DEBUG"
    $portFilter = $rule | Get-NetFirewallPortFilter
    $addressFilter = $rule | Get-NetFirewallAddressFilter
    $appFilter = $rule | Get-NetFirewallApplicationFilter

    $protocolMap = @{ 'TCP' = 6; 'UDP' = 17 }
    $protocol = if ($portFilter.Protocol -match '^\d+$') {
        [int]$portFilter.Protocol
    } else {
        $mapped = $protocolMap[$portFilter.Protocol]
        if ($null -ne $mapped) { $mapped } else { 0 }
    }

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
        displayName        = $rule.DisplayName
        description        = $rule.Description
        action             = $rule.Action.ToString().ToLower()
        direction          = $rule.Direction.ToString().ToLower()
        protocol           = $protocol
        localPortRanges    = $localPorts
        remotePortRanges   = $remotePorts
        localAddressRanges = $localAddresses
        remoteAddressRanges = $remoteAddresses
        profileTypes       = $rule.Profile -split ',' -join ','
        filePath           = $appFilter.Program
        packageFamilyName  = $appFilter.Package
    }
}

function Export-RuleSetToFile {
    param(
        [Parameter(Mandatory=$true)] $rules,
        [Parameter(Mandatory=$true)] [string]$OutputFile,
        [Parameter(Mandatory=$true)] [string]$OutputFormat,
        [bool]$DualOutput = $false
    )

    if ($DualOutput -or $OutputFormat -eq 'JSON') {
        if ([System.IO.Path]::GetExtension($OutputFile).ToLower() -eq ".json") {
            $jsonFile = $OutputFile
        } else {
            $jsonFile = "$OutputFile.json"
        }
        Add-Log "Saving rules to $jsonFile..."
        $jsonString = $rules | ConvertTo-Json -Depth 5
        $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
        $jsonString | Set-Content -Path $jsonFile
        Add-Log "Rules saved to $jsonFile"
    }
    if ($DualOutput -or $OutputFormat -eq 'CSV') {
        if ([System.IO.Path]::GetExtension($OutputFile).ToLower() -eq ".csv") {
            $csvFile = $OutputFile
        } else {
            $csvFile = "$OutputFile.csv"
        }
        Add-Log "Saving rules to $csvFile..."
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
            @{Name='packageFamilyName';Expression={$_.packageFamilyName}} |
            Export-Csv -Path $csvFile -NoTypeInformation
        Add-Log "Rules saved as CSV to $csvFile"
    }
}
'@

# ============================================================================
# Region: Core Operation Script Blocks
# ============================================================================

# Script block for capture operations (runs in background runspace)
$script:CaptureScriptBlock = {
    . ([scriptblock]::Create($sharedFunctions))

    try {
        Import-Module NetSecurity -ErrorAction Stop
        Add-Log "NetSecurity module loaded successfully"

        $syncHash.StatusMessage = "Fetching firewall rules..."
        Add-Log "Fetching firewall rules with filters - SkipDisabled: $($params.SkipDisabled), SkipDefault: $($params.SkipDefaultRules), Profile: $($params.ProfileType)"

        $allRules = Get-NetFirewallRule

        if ($params.SkipDisabled) {
            Add-Log "Filtering out disabled rules..."
            $allRules = $allRules | Where-Object { $_.Enabled -eq 'True' }
        }

        if ($params.SkipDefaultRules) {
            $defaultRulesPath = Join-Path $scriptDir "DefaultRules.json"
            Add-Log "Loading default rules from $defaultRulesPath"
            if (Test-Path $defaultRulesPath) {
                $defaultRules = Get-Content -Path $defaultRulesPath -ErrorAction Stop | ConvertFrom-Json
                $defaultNames = $defaultRules.displayName
                $allRules = $allRules | Where-Object { $_.DisplayName -notin $defaultNames }
                Add-Log "Skipped $($defaultNames.Count) default rules. Processing $($allRules.Count) remaining."
            } else {
                Add-Log "DefaultRules.json not found at $defaultRulesPath - proceeding without skipping defaults" "WARN"
            }
        }

        $profileType = $params.ProfileType
        $validProfiles = 'Private', 'Public', 'Domain', 'All'
        $selectedProfiles = $profileType -split ',' | ForEach-Object { $_.Trim() }
        if ($selectedProfiles -notcontains 'All') {
            $invalidProfiles = $selectedProfiles | Where-Object { $_ -notin $validProfiles }
            if ($invalidProfiles) {
                throw "Invalid profile type(s): $invalidProfiles"
            }
            $allRules = $allRules | Where-Object {
                $ruleProfiles = $_.Profile -split ','
                ($ruleProfiles | Where-Object { $_ -in $selectedProfiles }).Count -gt 0
            }
            Add-Log "Filtered rules for profile(s): $profileType"
        } else {
            Add-Log "Processing rules for all profiles"
        }

        $total = @($allRules).Count
        Add-Log "Processing $total rules..."
        $syncHash.StatusMessage = "Processing $total rules..."

        $rules = @()
        $count = 0
        foreach ($rule in $allRules) {
            if ($syncHash.CancelRequested) {
                Add-Log "Operation cancelled by user" "WARN"
                $syncHash.StatusMessage = "Operation cancelled."
                $syncHash.Completed = $true
                $syncHash.IsRunning = $false
                return
            }
            $count++
            $rules += ConvertTo-IntuneFirewallRule $rule
            $syncHash.Progress = [math]::Round(($count / [math]::Max($total, 1)) * 100)
            $syncHash.StatusMessage = "Processing rule $count of $total - $($rule.DisplayName)"
        }

        Add-Log "Exporting $($rules.Count) rules..."
        $syncHash.StatusMessage = "Exporting rules..."
        Export-RuleSetToFile -rules $rules -OutputFile $params.OutputFile -OutputFormat $params.OutputFormat

        $syncHash.Progress = 100
        $syncHash.StatusMessage = "Capture complete! $($rules.Count) rules saved to $($params.OutputFile)."
        Add-Log "Capture completed successfully. $($rules.Count) rules captured."
    }
    catch {
        $syncHash.Error = $_.Exception.Message
        Add-Log "ERROR: $($_.Exception.Message)" "ERROR"
        $syncHash.StatusMessage = "Error: $($_.Exception.Message)"
    }
    finally {
        $syncHash.Completed = $true
        $syncHash.IsRunning = $false
    }
}

# Script block for generating DefaultRules.json (runs in background runspace)
$script:GenerateDefaultScriptBlock = {
    . ([scriptblock]::Create($sharedFunctions))

    try {
        Import-Module NetSecurity -ErrorAction Stop
        Add-Log "Generating DefaultRules.json..."
        $syncHash.StatusMessage = "Generating DefaultRules.json - fetching all rules..."

        $allRules = Get-NetFirewallRule
        $total = @($allRules).Count
        $count = 0
        $rules = @()

        Add-Log "Found $total rules to process for DefaultRules.json"

        foreach ($rule in $allRules) {
            if ($syncHash.CancelRequested) {
                Add-Log "Operation cancelled by user" "WARN"
                $syncHash.StatusMessage = "Operation cancelled."
                $syncHash.Completed = $true
                $syncHash.IsRunning = $false
                return
            }
            $count++
            $rules += ConvertTo-IntuneFirewallRule $rule
            $syncHash.Progress = [math]::Round(($count / [math]::Max($total, 1)) * 100)
            $syncHash.StatusMessage = "Generating DefaultRules.json - rule $count of $total"
        }

        $outputPath = Join-Path $scriptDir "DefaultRules.json"
        $jsonString = $rules | ConvertTo-Json -Depth 5
        $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
        $jsonString | Set-Content -Path $outputPath

        $syncHash.Progress = 100
        $syncHash.StatusMessage = "DefaultRules.json created with $($rules.Count) rules."
        Add-Log "Created DefaultRules.json with $($rules.Count) rules at $outputPath"
    }
    catch {
        $syncHash.Error = $_.Exception.Message
        Add-Log "ERROR: $($_.Exception.Message)" "ERROR"
        $syncHash.StatusMessage = "Error: $($_.Exception.Message)"
    }
    finally {
        $syncHash.Completed = $true
        $syncHash.IsRunning = $false
    }
}

# Script block for compare operations (runs in background runspace)
$script:CompareScriptBlock = {
    . ([scriptblock]::Create($sharedFunctions))

    try {
        $baselineFile = $params.BaselineFile
        $postInstallFile = $params.PostInstallFile
        $outputFile = $params.OutputFile
        $outputFormat = $params.OutputFormat
        $dualOutput = $params.DualOutput

        Add-Log "Compare mode: Baseline=$baselineFile, PostInstall=$postInstallFile"
        $syncHash.StatusMessage = "Loading baseline rules..."
        $syncHash.Progress = 10

        if (-not (Test-Path $baselineFile)) {
            throw "Baseline file not found: $baselineFile"
        }
        if (-not (Test-Path $postInstallFile)) {
            throw "Post-install file not found: $postInstallFile"
        }

        $baselineRules = Get-Content $baselineFile | ConvertFrom-Json
        Add-Log "Loaded $($baselineRules.Count) baseline rules"
        $syncHash.Progress = 30

        $syncHash.StatusMessage = "Loading post-install rules..."
        $postinstallRules = Get-Content $postInstallFile | ConvertFrom-Json
        Add-Log "Loaded $($postinstallRules.Count) post-install rules"
        $syncHash.Progress = 50

        $syncHash.StatusMessage = "Comparing rules..."
        $baselineNames = $baselineRules.displayName
        $newRules = $postinstallRules | Where-Object { $_.displayName -notin $baselineNames }
        Add-Log "Found $(@($newRules).Count) new rules"
        $syncHash.Progress = 70

        $syncHash.StatusMessage = "Exporting new rules..."
        Export-RuleSetToFile -rules @($newRules) -OutputFile $outputFile -OutputFormat $outputFormat -DualOutput $dualOutput
        $syncHash.Progress = 100

        $syncHash.StatusMessage = "Compare complete! Found $(@($newRules).Count) new rules."
        Add-Log "Compare completed successfully. $(@($newRules).Count) new rules exported."
    }
    catch {
        $syncHash.Error = $_.Exception.Message
        Add-Log "ERROR: $($_.Exception.Message)" "ERROR"
        $syncHash.StatusMessage = "Error: $($_.Exception.Message)"
    }
    finally {
        $syncHash.Completed = $true
        $syncHash.IsRunning = $false
    }
}

# ============================================================================
# Region: DispatcherTimer for UI Updates
# ============================================================================
$script:UpdateTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:UpdateTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$script:UpdateTimer.Add_Tick({
    # Update progress bar
    $progressBar.Value = $script:SyncHash.Progress
    $progressText.Text = "$($script:SyncHash.Progress)%"

    # Update status text
    if ($script:SyncHash.StatusMessage) {
        $statusText.Text = $script:SyncHash.StatusMessage
    }

    # Flush log messages from background thread
    while ($script:SyncHash.LogQueue.Count -gt 0) {
        try {
            $msg = $script:SyncHash.LogQueue[0]
            $script:SyncHash.LogQueue.RemoveAt(0)
            $logBox.AppendText("$msg`r`n")
            $logBox.ScrollToEnd()
        } catch {
            break
        }
    }

    # Check if operation completed
    if ($script:SyncHash.Completed) {
        $script:UpdateTimer.Stop()
        Update-UIState -Running $false

        if ($script:SyncHash.Error) {
            $entry = Write-DebugLog "Operation failed: $($script:SyncHash.Error)" "ERROR"
            Append-Log $entry
            [System.Windows.MessageBox]::Show(
                "Operation failed: $($script:SyncHash.Error)",
                "RuleForge Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
        } else {
            $entry = Write-DebugLog "Operation completed successfully" "INFO"
            Append-Log $entry
        }

        # Clean up runspace
        if ($script:CurrentPowerShell) {
            try {
                $script:CurrentPowerShell.EndInvoke($script:CurrentHandle)
                $script:CurrentPowerShell.Dispose()
            } catch { }
        }
        if ($script:CurrentRunspace) {
            try { $script:CurrentRunspace.Close() } catch { }
        }
    }
})

# ============================================================================
# Region: Event Handlers
# ============================================================================

# Capture type radio button changes default filename
$baselineRadio.Add_Checked({
    if ($captureOutputFile.Text -eq "postinstall.json" -or $captureOutputFile.Text -eq "postinstall.csv") {
        $ext = if ($captureOutputFormat.SelectedIndex -eq 1) { ".csv" } else { ".json" }
        $captureOutputFile.Text = "baseline$ext"
    }
})

$postInstallRadio.Add_Checked({
    if ($captureOutputFile.Text -eq "baseline.json" -or $captureOutputFile.Text -eq "baseline.csv") {
        $ext = if ($captureOutputFormat.SelectedIndex -eq 1) { ".csv" } else { ".json" }
        $captureOutputFile.Text = "postinstall$ext"
    }
})

# Dual output checkbox toggles format dropdown
$dualOutputCheck.Add_Checked({
    $compareOutputFormat.IsEnabled = $false
})

$dualOutputCheck.Add_Unchecked({
    $compareOutputFormat.IsEnabled = $true
})

# Browse buttons
$captureOutputBrowse.Add_Click({
    $file = Show-SaveFileDialog -DefaultName $captureOutputFile.Text
    if ($file) { $captureOutputFile.Text = $file }
})

$baselineBrowse.Add_Click({
    $file = Show-OpenFileDialog
    if ($file) { $baselineFileInput.Text = $file }
})

$postInstallBrowse.Add_Click({
    $file = Show-OpenFileDialog
    if ($file) { $postInstallFileInput.Text = $file }
})

$compareOutputBrowse.Add_Click({
    $file = Show-SaveFileDialog -DefaultName $compareOutputFile.Text
    if ($file) { $compareOutputFile.Text = $file }
})

# Start Capture
$startCaptureBtn.Add_Click({
    $outputFile = $captureOutputFile.Text.Trim()
    if (-not $outputFile) {
        [System.Windows.MessageBox]::Show("Please specify an output file name.", "RuleForge",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    # Resolve relative paths to script directory
    if (-not [System.IO.Path]::IsPathRooted($outputFile)) {
        $outputFile = Join-Path $script:ScriptDir $outputFile
    }

    $captureType = if ($baselineRadio.IsChecked) { "Baseline" } else { "PostInstall" }
    $outputFormat = $captureOutputFormat.Text
    $skipDisabled = $skipDisabledCheck.IsChecked -eq $true
    $skipDefault = $skipDefaultCheck.IsChecked -eq $true
    $profileType = $profileTypeCombo.Text

    # Check DefaultRules.json if skip default is requested
    if ($skipDefault) {
        $defaultPath = Join-Path $script:ScriptDir "DefaultRules.json"
        if (-not (Test-Path $defaultPath)) {
            $result = [System.Windows.MessageBox]::Show(
                "DefaultRules.json not found. Continue without skipping default rules?`n`nClick 'No' to generate it first.",
                "RuleForge Warning",
                [System.Windows.MessageBoxButton]::YesNoCancel,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($result -eq 'No') {
                # Trigger default rules generation instead
                $generateDefaultBtn.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
                return
            } elseif ($result -eq 'Cancel') {
                return
            }
            $skipDefault = $false
        }
    }

    $entry = Write-DebugLog "Starting $captureType capture - Output: $outputFile, Format: $outputFormat, SkipDisabled: $skipDisabled, SkipDefault: $skipDefault, Profile: $profileType"
    Append-Log $entry

    $captureParams = @{
        CaptureType     = $captureType
        OutputFile      = $outputFile
        OutputFormat    = $outputFormat
        SkipDisabled    = $skipDisabled
        SkipDefaultRules = $skipDefault
        ProfileType     = $profileType
    }

    Start-BackgroundOperation -ScriptBlock $script:CaptureScriptBlock -Parameters $captureParams
})

# Generate DefaultRules.json
$generateDefaultBtn.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "This will capture ALL current firewall rules into DefaultRules.json.`n`nBest used on a fresh/OOBE system. Continue?",
        "Generate DefaultRules.json",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($result -eq 'Yes') {
        $entry = Write-DebugLog "Generating DefaultRules.json..."
        Append-Log $entry
        Start-BackgroundOperation -ScriptBlock $script:GenerateDefaultScriptBlock -Parameters @{}
    }
})

# Start Compare
$startCompareBtn.Add_Click({
    $baseFile = $baselineFileInput.Text.Trim()
    $postFile = $postInstallFileInput.Text.Trim()
    $outFile = $compareOutputFile.Text.Trim()

    if (-not $baseFile -or -not $postFile -or -not $outFile) {
        [System.Windows.MessageBox]::Show("Please fill in all file fields.", "RuleForge",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    # Resolve relative paths
    if (-not [System.IO.Path]::IsPathRooted($baseFile)) {
        $baseFile = Join-Path $script:ScriptDir $baseFile
    }
    if (-not [System.IO.Path]::IsPathRooted($postFile)) {
        $postFile = Join-Path $script:ScriptDir $postFile
    }
    if (-not [System.IO.Path]::IsPathRooted($outFile)) {
        $outFile = Join-Path $script:ScriptDir $outFile
    }

    # Validate input files exist
    if (-not (Test-Path $baseFile)) {
        [System.Windows.MessageBox]::Show("Baseline file not found: $baseFile", "RuleForge",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }
    if (-not (Test-Path $postFile)) {
        [System.Windows.MessageBox]::Show("Post-install file not found: $postFile", "RuleForge",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }

    $dualOutput = $dualOutputCheck.IsChecked -eq $true
    $outputFormat = $compareOutputFormat.Text

    $entry = Write-DebugLog "Starting compare - Baseline: $baseFile, PostInstall: $postFile, Output: $outFile, DualOutput: $dualOutput"
    Append-Log $entry

    $compareParams = @{
        BaselineFile = $baseFile
        PostInstallFile = $postFile
        OutputFile = $outFile
        OutputFormat = $outputFormat
        DualOutput = $dualOutput
    }

    Start-BackgroundOperation -ScriptBlock $script:CompareScriptBlock -Parameters $compareParams
})

# Cancel operation
$cancelBtn.Add_Click({
    if ($script:SyncHash.IsRunning) {
        $script:SyncHash.CancelRequested = $true
        $statusText.Text = "Cancelling operation..."
        $entry = Write-DebugLog "Cancel requested by user" "WARN"
        Append-Log $entry
    }
})

# Log management buttons
$clearLogBtn.Add_Click({
    $logBox.Clear()
})

$saveLogBtn.Add_Click({
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.FileName = "RuleForge-Log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $dialog.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
    $dialog.InitialDirectory = $script:ScriptDir
    if ($dialog.ShowDialog() -eq $true) {
        $logBox.Text | Set-Content -Path $dialog.FileName
        $entry = Write-DebugLog "Log saved to $($dialog.FileName)"
        Append-Log $entry
    }
})

$openLogFileBtn.Add_Click({
    if (Test-Path $script:LogFile) {
        Start-Process notepad.exe -ArgumentList $script:LogFile
    } else {
        [System.Windows.MessageBox]::Show("Log file not found: $($script:LogFile)", "RuleForge",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})

# Exit button
$exitBtn.Add_Click({
    if ($script:SyncHash.IsRunning) {
        $result = [System.Windows.MessageBox]::Show(
            "An operation is still running. Exit anyway?",
            "RuleForge",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        if ($result -ne 'Yes') { return }
        $script:SyncHash.CancelRequested = $true
    }
    $window.Close()
})

# Window closing handler
$window.Add_Closing({
    if ($script:SyncHash.IsRunning) {
        $script:SyncHash.CancelRequested = $true
    }
    $script:UpdateTimer.Stop()
    if ($script:CurrentPowerShell) {
        try { $script:CurrentPowerShell.Stop() } catch { }
        try { $script:CurrentPowerShell.Dispose() } catch { }
    }
    if ($script:CurrentRunspace) {
        try { $script:CurrentRunspace.Close() } catch { }
        try { $script:CurrentRunspace.Dispose() } catch { }
    }
})

# ============================================================================
# Region: Main Entry Point
# ============================================================================

# Initialize debug log
$entry = Write-DebugLog "RuleForge GUI v2.0 started"
Append-Log $entry
$entry = Write-DebugLog "Script directory: $script:ScriptDir"
Append-Log $entry
$entry = Write-DebugLog "Log file: $script:LogFile"
Append-Log $entry
$entry = Write-DebugLog "PowerShell version: $($PSVersionTable.PSVersion)"
Append-Log $entry

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    $entry = Write-DebugLog "WARNING: Not running as Administrator. Firewall rule access may be limited." "WARN"
    Append-Log $entry
    $statusText.Text = "Warning: Not running as Administrator - some operations may fail"
    $statusText.Foreground = [System.Windows.Media.Brushes]::OrangeRed
}

# Show the window
$window.ShowDialog() | Out-Null
