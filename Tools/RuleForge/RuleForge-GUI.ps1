<#
.SYNOPSIS
    RuleForge-GUI.ps1 - A WPF-based GUI for managing Windows Defender firewall rules for Intune integration.

.DESCRIPTION
    This GUI application wraps all functionality from RuleForge.ps1 into an easy-to-use graphical interface.
    It provides three main tabs: Capture Rules, Compare Rules, and About. The GUI uses Windows Presentation
    Foundation (WPF) with XAML markup for a modern, responsive interface.

.VERSION
    2.0 - GUI Edition (February 2026)

.REQUIREMENTS
    - Must be run with PowerShell 7.0 or later
    - Must be run as a Local Administrator to access and retrieve firewall rules
    - Requires NetSecurity module (built into Windows)

.AUTHOR
    Nathan Hutchinson / AI Assistant

.WEBSITE
    https://natehutchinson.co.uk

.GITHUB
    https://github.com/NateHutch365
#>

#Requires -Version 7.0

# Import required modules
Import-Module NetSecurity -ErrorAction Stop

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

#----------------------------------------------
# XAML Definition
#----------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RuleForge - Windows Firewall Rule Manager" 
        Height="700" Width="900"
        MinHeight="600" MinWidth="800"
        WindowStartupLocation="CenterScreen"
        Background="#F5F5F5">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#4CAF50"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#45a049"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#CCCCCC"/>
                    <Setter Property="Foreground" Value="#666666"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="5,2"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="5,5"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Padding" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="5,2"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="5,2"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#2C3E50" CornerRadius="5" Padding="15" Margin="0,0,0,10">
            <StackPanel>
                <TextBlock Text="RuleForge v2.0 - GUI Edition" FontSize="24" FontWeight="Bold" Foreground="White"/>
                <TextBlock Text="Windows Firewall Rule Manager for Intune" FontSize="14" Foreground="#BDC3C7"/>
            </StackPanel>
        </Border>
        
        <!-- Tab Control -->
        <TabControl Grid.Row="1" Name="MainTabControl">
            <!-- Tab 1: Capture Rules -->
            <TabItem Header="📋 Capture Rules" FontSize="14">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="10">
                        <GroupBox Header="Capture Mode" Margin="5" Padding="10">
                            <StackPanel>
                                <RadioButton Name="RadioBaseline" Content="Baseline (Clean system capture)" 
                                           IsChecked="True" Margin="5"/>
                                <RadioButton Name="RadioPostInstall" Content="Post-Install (After app installation)" 
                                           Margin="5"/>
                            </StackPanel>
                        </GroupBox>
                        
                        <GroupBox Header="Output Settings" Margin="5" Padding="10">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="120"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="100"/>
                                </Grid.ColumnDefinitions>
                                
                                <Label Grid.Row="0" Grid.Column="0" Content="Output File:" VerticalAlignment="Center"/>
                                <TextBox Grid.Row="0" Grid.Column="1" Name="TxtCaptureOutput" Text="baseline.json"/>
                                <Button Grid.Row="0" Grid.Column="2" Name="BtnBrowseCaptureOutput" Content="Browse..." 
                                      Background="#2196F3"/>
                                
                                <Label Grid.Row="1" Grid.Column="0" Content="Output Format:" VerticalAlignment="Center"/>
                                <ComboBox Grid.Row="1" Grid.Column="1" Name="CmbCaptureFormat" SelectedIndex="0">
                                    <ComboBoxItem Content="JSON"/>
                                    <ComboBoxItem Content="CSV"/>
                                    <ComboBoxItem Content="Both"/>
                                </ComboBox>
                            </Grid>
                        </GroupBox>
                        
                        <GroupBox Header="Filtering Options" Margin="5" Padding="10">
                            <StackPanel>
                                <CheckBox Name="ChkSkipDisabled" Content="Skip disabled rules"/>
                                <CheckBox Name="ChkSkipDefaultRules" Content="Skip default Windows rules (requires DefaultRules.json)"/>
                                
                                <StackPanel Orientation="Horizontal" Margin="5,10,5,5">
                                    <Label Content="Profile Type:" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                    <ComboBox Name="CmbProfileType" Width="200" SelectedIndex="0">
                                        <ComboBoxItem Content="All"/>
                                        <ComboBoxItem Content="Private"/>
                                        <ComboBoxItem Content="Public"/>
                                        <ComboBoxItem Content="Domain"/>
                                        <ComboBoxItem Content="Private,Public"/>
                                        <ComboBoxItem Content="Private,Domain"/>
                                        <ComboBoxItem Content="Public,Domain"/>
                                    </ComboBox>
                                </StackPanel>
                            </StackPanel>
                        </GroupBox>
                        
                        <Button Name="BtnCapture" Content="🔥 CAPTURE RULES" Height="50" FontSize="16" 
                              Margin="5,20,5,5"/>
                        
                        <ProgressBar Name="ProgressCapture" Height="25" Margin="5" Visibility="Collapsed"/>
                        
                        <GroupBox Header="Status Log" Margin="5" Padding="5" Height="200">
                            <TextBox Name="TxtCaptureLog" IsReadOnly="True" VerticalScrollBarVisibility="Auto" 
                                   TextWrapping="Wrap" FontFamily="Consolas" FontSize="10"/>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Tab 2: Compare Rules -->
            <TabItem Header="⚖️ Compare Rules" FontSize="14">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="10">
                        <GroupBox Header="Input Files" Margin="5" Padding="10">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="120"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="100"/>
                                </Grid.ColumnDefinitions>
                                
                                <Label Grid.Row="0" Grid.Column="0" Content="Baseline File:" VerticalAlignment="Center"/>
                                <TextBox Grid.Row="0" Grid.Column="1" Name="TxtBaselineFile" Text="baseline.json"/>
                                <Button Grid.Row="0" Grid.Column="2" Name="BtnBrowseBaseline" Content="Browse..." 
                                      Background="#2196F3"/>
                                
                                <Label Grid.Row="1" Grid.Column="0" Content="Post-Install File:" VerticalAlignment="Center"/>
                                <TextBox Grid.Row="1" Grid.Column="1" Name="TxtPostInstallFile" Text="postinstall.json"/>
                                <Button Grid.Row="1" Grid.Column="2" Name="BtnBrowsePostInstall" Content="Browse..." 
                                      Background="#2196F3"/>
                            </Grid>
                        </GroupBox>
                        
                        <GroupBox Header="Output Settings" Margin="5" Padding="10">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="120"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="100"/>
                                </Grid.ColumnDefinitions>
                                
                                <Label Grid.Row="0" Grid.Column="0" Content="Output Prefix:" VerticalAlignment="Center"/>
                                <TextBox Grid.Row="0" Grid.Column="1" Name="TxtCompareOutput" Text="newrules"/>
                                <Button Grid.Row="0" Grid.Column="2" Name="BtnBrowseCompareOutput" Content="Browse..." 
                                      Background="#2196F3"/>
                                
                                <Label Grid.Row="1" Grid.Column="0" Content="Output Format:" VerticalAlignment="Center"/>
                                <ComboBox Grid.Row="1" Grid.Column="1" Name="CmbCompareFormat" SelectedIndex="2">
                                    <ComboBoxItem Content="JSON"/>
                                    <ComboBoxItem Content="CSV"/>
                                    <ComboBoxItem Content="Both"/>
                                    <ComboBoxItem Content="Table"/>
                                </ComboBox>
                            </Grid>
                        </GroupBox>
                        
                        <Button Name="BtnCompare" Content="⚖️ COMPARE RULES" Height="50" FontSize="16" 
                              Margin="5,20,5,5"/>
                        
                        <ProgressBar Name="ProgressCompare" Height="25" Margin="5" Visibility="Collapsed"/>
                        
                        <GroupBox Header="Status Log" Margin="5" Padding="5" Height="250">
                            <TextBox Name="TxtCompareLog" IsReadOnly="True" VerticalScrollBarVisibility="Auto" 
                                   TextWrapping="Wrap" FontFamily="Consolas" FontSize="10"/>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Tab 3: About -->
            <TabItem Header="ℹ️ About" FontSize="14">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                        <TextBlock Text="🔥 RuleForge v2.0 - GUI Edition" FontSize="28" FontWeight="Bold" 
                                 Foreground="#E74C3C" Margin="0,10"/>
                        
                        <TextBlock Text="Windows Firewall Rule Manager for Microsoft Intune" FontSize="16" 
                                 Foreground="#34495E" Margin="0,5,0,20"/>
                        
                        <Separator Margin="0,10"/>
                        
                        <TextBlock Text="🛠️ Functionality" FontSize="18" FontWeight="Bold" Margin="0,10"/>
                        <TextBlock TextWrapping="Wrap" Margin="10,5" FontSize="13">
                            RuleForge simplifies Windows Defender firewall rule management for Intune deployment:
                        </TextBlock>
                        <TextBlock TextWrapping="Wrap" Margin="20,5" FontSize="12">
                            • Capture baseline firewall rules from a clean reference system<LineBreak/>
                            • Capture post-installation rules after adding applications<LineBreak/>
                            • Compare rule sets to identify newly created rules<LineBreak/>
                            • Export to JSON (Intune-compatible) or CSV formats<LineBreak/>
                            • Filter by profile types (Private, Public, Domain)<LineBreak/>
                            • Skip disabled or default Windows rules
                        </TextBlock>
                        
                        <Separator Margin="0,10"/>
                        
                        <TextBlock Text="⚙️ Requirements" FontSize="18" FontWeight="Bold" Margin="0,10"/>
                        <TextBlock TextWrapping="Wrap" Margin="20,5" FontSize="12">
                            • PowerShell 7.0 or later<LineBreak/>
                            • Administrator privileges (required for firewall access)<LineBreak/>
                            • NetSecurity module (built into Windows)<LineBreak/>
                            • Windows 10/11 or Windows Server
                        </TextBlock>
                        
                        <Separator Margin="0,10"/>
                        
                        <TextBlock Text="👤 Author Information" FontSize="18" FontWeight="Bold" Margin="0,10"/>
                        <StackPanel Margin="20,5">
                            <TextBlock FontSize="12">
                                <Run Text="Author: " FontWeight="Bold"/>
                                <Run Text="Nathan Hutchinson"/>
                            </TextBlock>
                            <TextBlock FontSize="12" Margin="0,5">
                                <Run Text="Website: " FontWeight="Bold"/>
                                <Hyperlink Name="LinkWebsite" NavigateUri="https://natehutchinson.co.uk">
                                    https://natehutchinson.co.uk
                                </Hyperlink>
                            </TextBlock>
                            <TextBlock FontSize="12" Margin="0,5">
                                <Run Text="GitHub: " FontWeight="Bold"/>
                                <Hyperlink Name="LinkGitHub" NavigateUri="https://github.com/NateHutch365/Microsoft-Intune">
                                    https://github.com/NateHutch365/Microsoft-Intune
                                </Hyperlink>
                            </TextBlock>
                        </StackPanel>
                        
                        <Separator Margin="0,10"/>
                        
                        <TextBlock Text="🎯 Usage Tips" FontSize="18" FontWeight="Bold" Margin="0,10"/>
                        <TextBlock TextWrapping="Wrap" Margin="20,5" FontSize="12">
                            1. Use an unmanaged reference machine to capture rules freely<LineBreak/>
                            2. Create a DefaultRules.json on a fresh OOBE system for better filtering<LineBreak/>
                            3. Capture baseline before installing applications<LineBreak/>
                            4. Capture post-install after each application installation<LineBreak/>
                            5. Compare to identify and export only new application rules<LineBreak/>
                            6. Import JSON files directly into Intune firewall policies
                        </TextBlock>
                        
                        <Separator Margin="0,10"/>
                        
                        <TextBlock Text="🔨 Compilation" FontSize="18" FontWeight="Bold" Margin="0,10"/>
                        <TextBlock TextWrapping="Wrap" Margin="20,5" FontSize="12">
                            This GUI can be compiled to a standalone .exe using PS2EXE.<LineBreak/>
                            See COMPILE-TO-EXE.md for detailed instructions.
                        </TextBlock>
                        
                        <Border Background="#FFF9C4" BorderBrush="#FBC02D" BorderThickness="2" 
                              CornerRadius="5" Padding="10" Margin="0,20">
                            <StackPanel>
                                <TextBlock Text="⚠️ Administrator Privilege Required" FontSize="14" 
                                         FontWeight="Bold" Foreground="#F57C00"/>
                                <TextBlock TextWrapping="Wrap" FontSize="12" Foreground="#5D4037" Margin="0,5">
                                    This application must be run with administrator privileges to access 
                                    Windows Firewall rules. Right-click and select "Run as Administrator".
                                </TextBlock>
                            </StackPanel>
                        </Border>
                        
                        <TextBlock Text="Version 2.0 - February 2026" FontSize="11" Foreground="Gray" 
                                 HorizontalAlignment="Center" Margin="0,20"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

#----------------------------------------------
# Helper Functions (from RuleForge.ps1)
#----------------------------------------------

function ConvertTo-IntuneFirewallRule {
    param ($rule)
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
    param([string]$StatusCallback)
    
    Show-StatusMessage "Generating DefaultRules.json..." $StatusCallback
    $allRules = Get-NetFirewallRule
    $tempRules = @()
    $total = $allRules.Count
    $count = 0
    
    foreach ($rule in $allRules) {
        $count++
        $percent = ($count / $total) * 100
        Update-ProgressBar $percent "Creating DefaultRules.json: $count of $total" $StatusCallback
        $tempRules += ConvertTo-IntuneFirewallRule $rule
    }
    
    $jsonString = $tempRules | ConvertTo-Json -Depth 5
    $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
    $jsonString | Set-Content -Path "DefaultRules.json"
    Show-StatusMessage "Created DefaultRules.json with $($tempRules.Count) rules." $StatusCallback
}

function Get-FilteredFirewallRules {
    param(
        [switch]$SkipDisabled,
        [switch]$SkipDefaultRules,
        [string]$ProfileType,
        [string]$StatusCallback
    )
    
    Show-StatusMessage "Fetching firewall rules..." $StatusCallback
    $allRules = Get-NetFirewallRule

    if ($SkipDisabled) {
        Show-StatusMessage "Skipping disabled rules..." $StatusCallback
        $allRules = $allRules | Where-Object { $_.Enabled -eq 'True' }
    }

    if ($SkipDefaultRules) {
        Show-StatusMessage "Loading default rules to skip from DefaultRules.json..." $StatusCallback
        try {
            if (-not (Test-Path "DefaultRules.json")) {
                Show-StatusMessage "ERROR: DefaultRules.json not found!" $StatusCallback
                return @()
            }
            $defaultRules = Get-Content -Path "DefaultRules.json" -ErrorAction Stop | ConvertFrom-Json
            $defaultNames = $defaultRules.displayName
            $allRules = $allRules | Where-Object { $_.DisplayName -notin $defaultNames }
            Show-StatusMessage "Skipped $($defaultNames.Count) default rules. Processing $($allRules.Count) remaining rules..." $StatusCallback
        } catch {
            Show-StatusMessage "ERROR: Failed to load DefaultRules.json: $_" $StatusCallback
            return @()
        }
    }

    $validProfiles = 'Private', 'Public', 'Domain', 'All'
    $selectedProfiles = $ProfileType -split ',' | ForEach-Object { $_.Trim() }
    
    if ($selectedProfiles -contains 'All') {
        Show-StatusMessage "Processing rules for all profiles..." $StatusCallback
    } else {
        $invalidProfiles = $selectedProfiles | Where-Object { $_ -notin $validProfiles }
        if ($invalidProfiles) {
            Show-StatusMessage "ERROR: Invalid profile type(s): $invalidProfiles" $StatusCallback
            return @()
        }
        $allRules = $allRules | Where-Object {
            $ruleProfiles = $_.Profile -split ','
            ($ruleProfiles | Where-Object { $_ -in $selectedProfiles }).Count -gt 0
        }
        Show-StatusMessage "Filtering rules for profile(s): $ProfileType..." $StatusCallback
    }
    
    return $allRules
}

function Export-RuleSet {
    param (
        [Parameter(Mandatory=$true)] $rules,
        [Parameter(Mandatory=$true)] [string]$OutputFile,
        [Parameter(Mandatory=$true)] [string]$OutputFormat,
        [bool]$DualOutput = $false,
        [string]$StatusCallback
    )

    if ($DualOutput -or $OutputFormat -eq 'JSON') {
        if ([System.IO.Path]::GetExtension($OutputFile).ToLower() -eq ".json") {
            $jsonFile = $OutputFile
        } else {
            $jsonFile = "$OutputFile.json"
        }
        Show-StatusMessage "Saving rules to $jsonFile..." $StatusCallback
        $jsonString = $rules | ConvertTo-Json -Depth 5
        $jsonString = $jsonString -replace '\[\s*"\s*([^"]+?)\s*"\s*\]', '["$1"]'
        $jsonString | Set-Content -Path $jsonFile
        Show-StatusMessage "Rules saved to $jsonFile" $StatusCallback
    }
    
    if ($DualOutput -or $OutputFormat -eq 'CSV') {
        if ([System.IO.Path]::GetExtension($OutputFile).ToLower() -eq ".csv") {
            $csvFile = $OutputFile
        } else {
            $csvFile = "$OutputFile.csv"
        }
        Show-StatusMessage "Saving rules to $csvFile..." $StatusCallback
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
        Show-StatusMessage "Rules saved as CSV to $csvFile" $StatusCallback
    }
    
    if (-not $DualOutput -and $OutputFormat -eq 'Table') {
        Show-StatusMessage "Displaying rules as table..." $StatusCallback
        $tableOutput = $rules | Select-Object `
            @{Name='displayName';Expression={$_.displayName}},
            @{Name='action';Expression={$_.action}},
            @{Name='direction';Expression={$_.direction}},
            @{Name='protocol';Expression={$_.protocol}},
            @{Name='localPortRanges';Expression={$_.localPortRanges -join ','}},
            @{Name='remotePortRanges';Expression={$_.remotePortRanges -join ','}} `
            | Format-Table | Out-String
        Show-StatusMessage $tableOutput $StatusCallback
    }
}

#----------------------------------------------
# GUI Helper Functions
#----------------------------------------------

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-StatusMessage {
    param(
        [string]$Message,
        [string]$LogControl
    )
    
    if ($LogControl) {
        $window.Dispatcher.Invoke([action]{
            $logBox = $window.FindName($LogControl)
            if ($logBox) {
                $timestamp = Get-Date -Format "HH:mm:ss"
                $logBox.AppendText("[$timestamp] $Message`r`n")
                $logBox.ScrollToEnd()
            }
        })
    }
}

function Update-ProgressBar {
    param(
        [double]$Percent,
        [string]$Status,
        [string]$LogControl
    )
    
    $progressName = if ($LogControl -eq "TxtCaptureLog") { "ProgressCapture" } else { "ProgressCompare" }
    
    $window.Dispatcher.Invoke([action]{
        $progressBar = $window.FindName($progressName)
        if ($progressBar) {
            if ($Percent -ge 0 -and $Percent -le 100) {
                $progressBar.Visibility = "Visible"
                $progressBar.Value = $Percent
            } else {
                $progressBar.Visibility = "Collapsed"
            }
        }
    })
    
    if ($Status) {
        Show-StatusMessage $Status $LogControl
    }
}

function Show-FileDialog {
    param(
        [string]$Filter = "JSON Files (*.json)|*.json|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*",
        [string]$Title = "Select File",
        [bool]$Save = $false,
        [string]$DefaultFileName = ""
    )
    
    if ($Save) {
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.FileName = $DefaultFileName
    } else {
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
    }
    
    $dialog.Filter = $Filter
    $dialog.Title = $Title
    $dialog.InitialDirectory = Get-Location
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

function Invoke-CaptureOperation {
    param($window)
    
    $captureType = if ($window.FindName("RadioBaseline").IsChecked) { "Baseline" } else { "PostInstall" }
    $outputFile = $window.FindName("TxtCaptureOutput").Text
    $formatItem = $window.FindName("CmbCaptureFormat").SelectedItem.Content
    $skipDisabled = $window.FindName("ChkSkipDisabled").IsChecked
    $skipDefault = $window.FindName("ChkSkipDefaultRules").IsChecked
    $profileType = $window.FindName("CmbProfileType").SelectedItem.Content
    
    $logBox = $window.FindName("TxtCaptureLog")
    $captureBtn = $window.FindName("BtnCapture")
    
    # Clear log
    $window.Dispatcher.Invoke([action]{ $logBox.Clear() })
    
    # Check for DefaultRules.json if needed
    if ($skipDefault -and -not (Test-Path "DefaultRules.json")) {
        $result = [System.Windows.MessageBox]::Show(
            "DefaultRules.json not found. Would you like to create it now?`n`n" +
            "Note: This should only be done on a fresh OOBE device.`n" +
            "This process may take several minutes.",
            "Create DefaultRules.json?",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            try {
                New-DefaultRules -StatusCallback "TxtCaptureLog"
                Update-ProgressBar -1 "" "TxtCaptureLog"
            } catch {
                [System.Windows.MessageBox]::Show(
                    "Failed to create DefaultRules.json: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
                return
            }
        } else {
            Show-StatusMessage "Proceeding without skipping default rules." "TxtCaptureLog"
            $skipDefault = $false
        }
    }
    
    # Disable button during operation
    $window.Dispatcher.Invoke([action]{ $captureBtn.IsEnabled = $false })
    
    # Run in background
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("window", $window)
    $runspace.SessionStateProxy.SetVariable("captureType", $captureType)
    $runspace.SessionStateProxy.SetVariable("outputFile", $outputFile)
    $runspace.SessionStateProxy.SetVariable("formatItem", $formatItem)
    $runspace.SessionStateProxy.SetVariable("skipDisabled", $skipDisabled)
    $runspace.SessionStateProxy.SetVariable("skipDefault", $skipDefault)
    $runspace.SessionStateProxy.SetVariable("profileType", $profileType)
    
    # Pass functions to runspace
    $runspace.SessionStateProxy.SetVariable("ConvertToIntuneFirewallRuleFunc", ${function:ConvertTo-IntuneFirewallRule})
    $runspace.SessionStateProxy.SetVariable("GetFilteredFirewallRulesFunc", ${function:Get-FilteredFirewallRules})
    $runspace.SessionStateProxy.SetVariable("ExportRuleSetFunc", ${function:Export-RuleSet})
    $runspace.SessionStateProxy.SetVariable("ShowStatusMessageFunc", ${function:Show-StatusMessage})
    $runspace.SessionStateProxy.SetVariable("UpdateProgressBarFunc", ${function:Update-ProgressBar})
    
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    
    [void]$ps.AddScript({
        # Import NetSecurity module for firewall cmdlets
        Import-Module NetSecurity -ErrorAction Stop
        
        function ConvertTo-IntuneFirewallRule { & $ConvertToIntuneFirewallRuleFunc @args }
        function Get-FilteredFirewallRules { & $GetFilteredFirewallRulesFunc @args }
        function Export-RuleSet { & $ExportRuleSetFunc @args }
        function Show-StatusMessage { & $ShowStatusMessageFunc @args }
        function Update-ProgressBar { & $UpdateProgressBarFunc @args }
        
        try {
            $startTime = Get-Date
            Show-StatusMessage "Starting $captureType capture..." "TxtCaptureLog"
            
            # Get filtered rules
            $allRules = Get-FilteredFirewallRules -SkipDisabled:$skipDisabled `
                -SkipDefaultRules:$skipDefault -ProfileType $profileType -StatusCallback "TxtCaptureLog"
            
            if ($allRules.Count -eq 0) {
                Show-StatusMessage "No rules to process!" "TxtCaptureLog"
                return
            }
            
            Show-StatusMessage "Processing $($allRules.Count) rules..." "TxtCaptureLog"
            
            # Convert rules
            $rules = @()
            $total = $allRules.Count
            $count = 0
            
            foreach ($rule in $allRules) {
                $count++
                $percent = ($count / $total) * 100
                Update-ProgressBar $percent "Converting rules: $count of $total" "TxtCaptureLog"
                $rules += ConvertTo-IntuneFirewallRule $rule
            }
            
            # Export rules
            $dualOutput = $formatItem -eq "Both"
            $format = if ($dualOutput) { "JSON" } else { $formatItem }
            
            Export-RuleSet -rules $rules -OutputFile $outputFile -OutputFormat $format `
                -DualOutput $dualOutput -StatusCallback "TxtCaptureLog"
            
            $endTime = Get-Date
            $duration = $endTime - $startTime
            Show-StatusMessage "Capture completed! Processed $($rules.Count) rules in $([math]::Round($duration.TotalSeconds, 2)) seconds." "TxtCaptureLog"
            
        } catch {
            Show-StatusMessage "ERROR: $_" "TxtCaptureLog"
            $window.Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred during capture: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            })
        } finally {
            Update-ProgressBar -1 "" "TxtCaptureLog"
            $window.Dispatcher.Invoke([action]{
                $window.FindName("BtnCapture").IsEnabled = $true
            })
        }
    })
    
    [void]$ps.BeginInvoke()
}

function Invoke-CompareOperation {
    param($window)
    
    $baselineFile = $window.FindName("TxtBaselineFile").Text
    $postInstallFile = $window.FindName("TxtPostInstallFile").Text
    $outputPrefix = $window.FindName("TxtCompareOutput").Text
    $formatItem = $window.FindName("CmbCompareFormat").SelectedItem.Content
    
    $logBox = $window.FindName("TxtCompareLog")
    $compareBtn = $window.FindName("BtnCompare")
    
    # Validate files exist
    if (-not (Test-Path $baselineFile)) {
        [System.Windows.MessageBox]::Show(
            "Baseline file not found: $baselineFile",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        return
    }
    
    if (-not (Test-Path $postInstallFile)) {
        [System.Windows.MessageBox]::Show(
            "Post-Install file not found: $postInstallFile",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        return
    }
    
    # Clear log
    $window.Dispatcher.Invoke([action]{ $logBox.Clear() })
    
    # Disable button during operation
    $window.Dispatcher.Invoke([action]{ $compareBtn.IsEnabled = $false })
    
    # Run in background
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("window", $window)
    $runspace.SessionStateProxy.SetVariable("baselineFile", $baselineFile)
    $runspace.SessionStateProxy.SetVariable("postInstallFile", $postInstallFile)
    $runspace.SessionStateProxy.SetVariable("outputPrefix", $outputPrefix)
    $runspace.SessionStateProxy.SetVariable("formatItem", $formatItem)
    
    # Pass functions to runspace
    $runspace.SessionStateProxy.SetVariable("ExportRuleSetFunc", ${function:Export-RuleSet})
    $runspace.SessionStateProxy.SetVariable("ShowStatusMessageFunc", ${function:Show-StatusMessage})
    $runspace.SessionStateProxy.SetVariable("UpdateProgressBarFunc", ${function:Update-ProgressBar})
    
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    
    [void]$ps.AddScript({
        function Export-RuleSet { & $ExportRuleSetFunc @args }
        function Show-StatusMessage { & $ShowStatusMessageFunc @args }
        function Update-ProgressBar { & $UpdateProgressBarFunc @args }
        
        try {
            $startTime = Get-Date
            Show-StatusMessage "Loading baseline rules from $baselineFile..." "TxtCompareLog"
            Update-ProgressBar 25 "" "TxtCompareLog"
            
            $baselineRules = Get-Content $baselineFile | ConvertFrom-Json
            
            Show-StatusMessage "Loading post-install rules from $postInstallFile..." "TxtCompareLog"
            Update-ProgressBar 50 "" "TxtCompareLog"
            
            $postinstallRules = Get-Content $postInstallFile | ConvertFrom-Json
            
            Show-StatusMessage "Comparing rules..." "TxtCompareLog"
            Update-ProgressBar 75 "" "TxtCompareLog"
            
            $baselineNames = $baselineRules.displayName
            $newRules = $postinstallRules | Where-Object { $_.displayName -notin $baselineNames }
            
            Show-StatusMessage "Found $($newRules.Count) new rules" "TxtCompareLog"
            
            $dualOutput = $formatItem -eq "Both"
            $format = if ($dualOutput) { "JSON" } elseif ($formatItem -eq "Table") { "Table" } else { $formatItem }
            
            Export-RuleSet -rules $newRules -OutputFile $outputPrefix -OutputFormat $format `
                -DualOutput $dualOutput -StatusCallback "TxtCompareLog"
            
            $endTime = Get-Date
            $duration = $endTime - $startTime
            Show-StatusMessage "Comparison completed in $([math]::Round($duration.TotalSeconds, 2)) seconds." "TxtCompareLog"
            
        } catch {
            Show-StatusMessage "ERROR: $_" "TxtCompareLog"
            $window.Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred during comparison: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            })
        } finally {
            Update-ProgressBar -1 "" "TxtCompareLog"
            $window.Dispatcher.Invoke([action]{
                $window.FindName("BtnCompare").IsEnabled = $true
            })
        }
    })
    
    [void]$ps.BeginInvoke()
}

#----------------------------------------------
# Main GUI Setup
#----------------------------------------------

try {
    # Check admin privileges
    if (-not (Test-AdminPrivileges)) {
        $result = [System.Windows.MessageBox]::Show(
            "⚠️ This application requires Administrator privileges to access Windows Firewall rules.`n`n" +
            "Please restart this application as Administrator.`n`n" +
            "Would you like to continue anyway? (Operations will likely fail)",
            "Administrator Privileges Required",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        
        if ($result -eq [System.Windows.MessageBoxResult]::No) {
            exit
        }
    }
    
    # Load XAML
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Get controls
    $btnCapture = $window.FindName("BtnCapture")
    $btnCompare = $window.FindName("BtnCompare")
    $btnBrowseCaptureOutput = $window.FindName("BtnBrowseCaptureOutput")
    $btnBrowseBaseline = $window.FindName("BtnBrowseBaseline")
    $btnBrowsePostInstall = $window.FindName("BtnBrowsePostInstall")
    $btnBrowseCompareOutput = $window.FindName("BtnBrowseCompareOutput")
    $linkWebsite = $window.FindName("LinkWebsite")
    $linkGitHub = $window.FindName("LinkGitHub")
    
    # Event Handlers
    $btnCapture.Add_Click({
        Invoke-CaptureOperation $window
    })
    
    $btnCompare.Add_Click({
        Invoke-CompareOperation $window
    })
    
    $btnBrowseCaptureOutput.Add_Click({
        $file = Show-FileDialog -Save $true -Filter "JSON Files (*.json)|*.json|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*" `
            -Title "Save Capture Output" -DefaultFileName $window.FindName("TxtCaptureOutput").Text
        if ($file) {
            $window.FindName("TxtCaptureOutput").Text = $file
        }
    })
    
    $btnBrowseBaseline.Add_Click({
        $file = Show-FileDialog -Filter "JSON Files (*.json)|*.json|All Files (*.*)|*.*" -Title "Select Baseline File"
        if ($file) {
            $window.FindName("TxtBaselineFile").Text = $file
        }
    })
    
    $btnBrowsePostInstall.Add_Click({
        $file = Show-FileDialog -Filter "JSON Files (*.json)|*.json|All Files (*.*)|*.*" -Title "Select Post-Install File"
        if ($file) {
            $window.FindName("TxtPostInstallFile").Text = $file
        }
    })
    
    $btnBrowseCompareOutput.Add_Click({
        $file = Show-FileDialog -Save $true -Filter "All Files (*.*)|*.*" `
            -Title "Save Comparison Output (prefix)" -DefaultFileName $window.FindName("TxtCompareOutput").Text
        if ($file) {
            # Remove extension if provided, as we use this as a prefix
            $prefix = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $dir = [System.IO.Path]::GetDirectoryName($file)
            if ($dir) {
                $window.FindName("TxtCompareOutput").Text = Join-Path $dir $prefix
            } else {
                $window.FindName("TxtCompareOutput").Text = $prefix
            }
        }
    })
    
    $linkWebsite.Add_RequestNavigate({
        param($sender, $e)
        Start-Process $e.Uri.AbsoluteUri
        $e.Handled = $true
    })
    
    $linkGitHub.Add_RequestNavigate({
        param($sender, $e)
        Start-Process $e.Uri.AbsoluteUri
        $e.Handled = $true
    })
    
    # Show window
    $window.ShowDialog() | Out-Null
    
} catch {
    [System.Windows.MessageBox]::Show(
        "Failed to initialize GUI: $_",
        "Critical Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
    Write-Error $_
}
