using System.Diagnostics;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Win32;

namespace RuleForgeGUI
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private readonly string _logFilePath;
        private readonly StringBuilder _logBuffer;
        private CancellationTokenSource? _cancellationTokenSource;
        private bool _isOperationRunning;

        public MainWindow()
        {
            InitializeComponent();
            _logBuffer = new StringBuilder();
            _logFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), 
                "RuleForge", "RuleForge_debug.log");
            
            // Ensure log directory exists
            Directory.CreateDirectory(Path.GetDirectoryName(_logFilePath)!);
            
            // Check for DefaultRules.json
            CheckDefaultRulesStatus();
            
            Log("🔥 RuleForge GUI v2.0 initialized - Ready to forge firewall rules!");
            Log($"Log file location: {_logFilePath}");
        }

        #region Logging

        private void Log(string message, bool isError = false)
        {
            var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            var logEntry = $"[{timestamp}] {message}";
            
            Dispatcher.Invoke(() =>
            {
                txtLog.AppendText(logEntry + Environment.NewLine);
                txtLog.ScrollToEnd();
            });

            _logBuffer.AppendLine(logEntry);

            // Save to file if enabled
            if (chkSaveDebugLog?.IsChecked == true)
            {
                try
                {
                    File.AppendAllText(_logFilePath, logEntry + Environment.NewLine);
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"Failed to write log: {ex.Message}");
                }
            }
        }

        private void UpdateStatus(string status)
        {
            Dispatcher.Invoke(() => txtStatus.Text = status);
        }

        private void UpdateProgress(int percentage, string? statusText = null)
        {
            Dispatcher.Invoke(() =>
            {
                progressBar.Value = percentage;
                txtProgressPercent.Text = $"{percentage}%";
                if (statusText != null)
                {
                    txtStatus.Text = statusText;
                }
            });
        }

        private void SetControlsEnabled(bool enabled)
        {
            Dispatcher.Invoke(() =>
            {
                btnCapture.IsEnabled = enabled;
                btnCompare.IsEnabled = enabled;
                btnGenerateDefault.IsEnabled = enabled;
                _isOperationRunning = !enabled;
            });
        }

        #endregion

        #region Capture Operations

        private async void StartCapture_Click(object sender, RoutedEventArgs e)
        {
            if (_isOperationRunning) return;

            var captureType = rbBaseline.IsChecked == true ? "Baseline" : "PostInstall";
            var outputFile = txtCaptureOutput.Text;
            var outputFormat = ((ComboBoxItem)cmbCaptureFormat.SelectedItem).Content.ToString()!;
            var skipDisabled = chkSkipDisabled.IsChecked == true;
            var skipDefault = chkSkipDefault.IsChecked == true;
            var profileType = ((ComboBoxItem)cmbProfileType.SelectedItem).Content.ToString()!;
            var debugOutput = chkDebugOutput.IsChecked == true;

            // Validate output file
            if (string.IsNullOrWhiteSpace(outputFile))
            {
                MessageBox.Show("Please specify an output file path.", "Validation Error", 
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            // Check for DefaultRules.json if skip default is enabled
            if (skipDefault && !File.Exists(txtDefaultRulesPath.Text))
            {
                var result = MessageBox.Show(
                    "DefaultRules.json not found. Would you like to generate it now?\n\n" +
                    "Note: This should only be done on a clean/OOBE system.",
                    "DefaultRules.json Missing",
                    MessageBoxButton.YesNoCancel, MessageBoxImage.Warning);

                if (result == MessageBoxResult.Yes)
                {
                    await GenerateDefaultRulesAsync();
                    return;
                }
                else if (result == MessageBoxResult.Cancel)
                {
                    return;
                }
                // If No, continue without skipping default rules
                skipDefault = false;
            }

            SetControlsEnabled(false);
            _cancellationTokenSource = new CancellationTokenSource();

            try
            {
                await Task.Run(() => ExecuteCaptureAsync(captureType, outputFile, outputFormat, 
                    skipDisabled, skipDefault, profileType, debugOutput), _cancellationTokenSource.Token);
            }
            catch (OperationCanceledException)
            {
                Log("⚠️ Operation cancelled by user.");
                UpdateStatus("Operation cancelled.");
            }
            catch (Exception ex)
            {
                Log($"❌ Error during capture: {ex.Message}", true);
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                SetControlsEnabled(true);
                _cancellationTokenSource?.Dispose();
                _cancellationTokenSource = null;
            }
        }

        private async Task ExecuteCaptureAsync(string captureType, string outputFile, string outputFormat,
            bool skipDisabled, bool skipDefault, string profileType, bool debugOutput)
        {
            Log($"🔨 Starting {captureType} capture...");
            UpdateProgress(0, $"Starting {captureType} capture...");

            var scriptPath = GetPowerShellScriptPath();
            if (!File.Exists(scriptPath))
            {
                Log($"❌ RuleForge.ps1 not found at: {scriptPath}", true);
                throw new FileNotFoundException("RuleForge.ps1 not found", scriptPath);
            }

            // Build PowerShell command
            var psCommand = new StringBuilder();
            psCommand.AppendLine($". '{scriptPath}'");
            
            // Build parameters
            var parameters = new StringBuilder();
            parameters.Append($"-Capture -CaptureType {captureType} -Output '{outputFile}' -OutputFormat {outputFormat}");
            
            if (skipDisabled) parameters.Append(" -SkipDisabled");
            if (skipDefault) parameters.Append(" -SkipDefaultRules");
            if (profileType != "All") parameters.Append($" -ProfileType '{profileType}'");
            if (debugOutput) parameters.Append(" -DebugOutput");

            Log($"📝 Executing: {parameters}");
            UpdateProgress(10, "Fetching firewall rules...");

            await ExecutePowerShellWithProgressAsync(scriptPath, parameters.ToString());

            UpdateProgress(100, $"{captureType} capture completed!");
            Log($"✅ {captureType} capture completed successfully!");
            Log($"📁 Output saved to: {outputFile}");
            
            MessageBox.Show($"{captureType} capture completed successfully!\n\nOutput saved to: {outputFile}",
                "Success", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        #endregion

        #region Compare Operations

        private async void StartCompare_Click(object sender, RoutedEventArgs e)
        {
            if (_isOperationRunning) return;

            var baselineFile = txtBaselineFile.Text;
            var postInstallFile = txtPostInstallFile.Text;
            var outputFile = txtCompareOutput.Text;
            var formatSelection = ((ComboBoxItem)cmbCompareFormat.SelectedItem).Content.ToString()!;
            var dualOutput = chkDualOutput.IsChecked == true || formatSelection.Contains("Both");
            var outputFormat = formatSelection.Contains("Both") ? "JSON" : formatSelection;
            var debugOutput = chkDebugOutput.IsChecked == true;

            // Validate inputs
            if (!File.Exists(baselineFile))
            {
                MessageBox.Show($"Baseline file not found: {baselineFile}", "Validation Error",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (!File.Exists(postInstallFile))
            {
                MessageBox.Show($"Post-install file not found: {postInstallFile}", "Validation Error",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(outputFile))
            {
                MessageBox.Show("Please specify an output file path.", "Validation Error",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            SetControlsEnabled(false);
            _cancellationTokenSource = new CancellationTokenSource();

            try
            {
                await Task.Run(() => ExecuteCompareAsync(baselineFile, postInstallFile, outputFile,
                    outputFormat, dualOutput, debugOutput), _cancellationTokenSource.Token);
            }
            catch (OperationCanceledException)
            {
                Log("⚠️ Operation cancelled by user.");
                UpdateStatus("Operation cancelled.");
            }
            catch (Exception ex)
            {
                Log($"❌ Error during comparison: {ex.Message}", true);
                MessageBox.Show($"An error occurred: {ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                SetControlsEnabled(true);
                _cancellationTokenSource?.Dispose();
                _cancellationTokenSource = null;
            }
        }

        private async Task ExecuteCompareAsync(string baselineFile, string postInstallFile, string outputFile,
            string outputFormat, bool dualOutput, bool debugOutput)
        {
            Log("⚔️ Starting rule comparison...");
            UpdateProgress(0, "Loading baseline rules...");

            var scriptPath = GetPowerShellScriptPath();
            if (!File.Exists(scriptPath))
            {
                Log($"❌ RuleForge.ps1 not found at: {scriptPath}", true);
                throw new FileNotFoundException("RuleForge.ps1 not found", scriptPath);
            }

            // Build parameters
            var parameters = new StringBuilder();
            parameters.Append($"-Compare -BaselineFile '{baselineFile}' -PostInstallFile '{postInstallFile}'");
            parameters.Append($" -OutputFile '{outputFile}' -OutputFormat {outputFormat}");
            if (debugOutput) parameters.Append(" -DebugOutput");

            Log($"📝 Executing: {parameters}");
            UpdateProgress(20, "Comparing rules...");

            await ExecutePowerShellWithProgressAsync(scriptPath, parameters.ToString());

            UpdateProgress(100, "Rule comparison completed!");
            Log("✅ Rule comparison completed successfully!");

            var outputMsg = dualOutput
                ? $"Output saved to: {outputFile}.json and {outputFile}.csv"
                : $"Output saved to: {outputFile}.{outputFormat.ToLower()}";
            Log($"📁 {outputMsg}");

            MessageBox.Show($"Rule comparison completed successfully!\n\n{outputMsg}",
                "Success", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        #endregion

        #region PowerShell Execution

        private string GetPowerShellScriptPath()
        {
            // First check in the application directory
            var appDir = AppDomain.CurrentDomain.BaseDirectory;
            var scriptInAppDir = Path.Combine(appDir, "RuleForge.ps1");
            if (File.Exists(scriptInAppDir))
                return scriptInAppDir;

            // Check parent directory (when running from GUI folder)
            var parentDir = Directory.GetParent(appDir)?.FullName;
            if (parentDir != null)
            {
                var scriptInParent = Path.Combine(parentDir, "RuleForge.ps1");
                if (File.Exists(scriptInParent))
                    return scriptInParent;
            }

            // Check current working directory
            var scriptInCwd = Path.Combine(Environment.CurrentDirectory, "RuleForge.ps1");
            if (File.Exists(scriptInCwd))
                return scriptInCwd;

            // Return default path (will trigger error if not found)
            return scriptInAppDir;
        }

        private async Task ExecutePowerShellWithProgressAsync(string scriptPath, string parameters)
        {
            var initialSessionState = InitialSessionState.CreateDefault();
            
            using var runspace = RunspaceFactory.CreateRunspace(initialSessionState);
            runspace.Open();

            using var ps = PowerShell.Create();
            ps.Runspace = runspace;

            // Load the script and execute with parameters
            var script = $@"
                Set-Location '{Path.GetDirectoryName(scriptPath)}'
                & '{scriptPath}' {parameters}
            ";

            ps.AddScript(script);

            // Capture output streams
            ps.Streams.Information.DataAdded += (s, e) =>
            {
                var record = ps.Streams.Information[e.Index];
                Log($"ℹ️ {record.MessageData}");
            };

            ps.Streams.Warning.DataAdded += (s, e) =>
            {
                var record = ps.Streams.Warning[e.Index];
                Log($"⚠️ {record.Message}");
            };

            ps.Streams.Error.DataAdded += (s, e) =>
            {
                var record = ps.Streams.Error[e.Index];
                Log($"❌ {record.Exception?.Message ?? record.ToString()}", true);
            };

            ps.Streams.Verbose.DataAdded += (s, e) =>
            {
                var record = ps.Streams.Verbose[e.Index];
                if (chkDebugOutput.IsChecked == true)
                {
                    Log($"🔍 {record.Message}");
                }
            };

            ps.Streams.Progress.DataAdded += (s, e) =>
            {
                var record = ps.Streams.Progress[e.Index];
                if (record.PercentComplete >= 0)
                {
                    UpdateProgress(record.PercentComplete, record.StatusDescription);
                }
            };

            try
            {
                var results = await Task.Run(() => ps.Invoke());

                foreach (var result in results)
                {
                    if (result?.BaseObject != null)
                    {
                        Log($"📤 {result}");
                    }
                }

                if (ps.HadErrors)
                {
                    foreach (var error in ps.Streams.Error)
                    {
                        Log($"❌ PowerShell Error: {error}", true);
                    }
                }
            }
            catch (Exception ex)
            {
                Log($"❌ PowerShell execution failed: {ex.Message}", true);
                throw;
            }
        }

        #endregion

        #region Default Rules Generation

        private async void GenerateDefaultRules_Click(object sender, RoutedEventArgs e)
        {
            if (_isOperationRunning) return;

            var result = MessageBox.Show(
                "Generate DefaultRules.json from the current system?\n\n" +
                "⚠️ IMPORTANT: Only do this on a clean/OOBE system without any additional applications installed. " +
                "This will capture ALL current firewall rules as the baseline for filtering.\n\n" +
                "Continue?",
                "Generate Default Rules",
                MessageBoxButton.YesNo, MessageBoxImage.Warning);

            if (result != MessageBoxResult.Yes) return;

            await GenerateDefaultRulesAsync();
        }

        private async Task GenerateDefaultRulesAsync()
        {
            SetControlsEnabled(false);
            _cancellationTokenSource = new CancellationTokenSource();

            try
            {
                Log("🔧 Generating DefaultRules.json...");
                UpdateProgress(0, "Generating default rules...");

                var scriptPath = GetPowerShellScriptPath();
                var outputPath = Path.Combine(Path.GetDirectoryName(scriptPath)!, "DefaultRules.json");

                await ExecutePowerShellWithProgressAsync(scriptPath, 
                    $"-Capture -CaptureType Baseline -Output '{outputPath}'");

                UpdateProgress(100, "DefaultRules.json generated!");
                Log($"✅ DefaultRules.json generated at: {outputPath}");
                
                CheckDefaultRulesStatus();

                MessageBox.Show($"DefaultRules.json generated successfully!\n\nLocation: {outputPath}",
                    "Success", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                Log($"❌ Failed to generate DefaultRules.json: {ex.Message}", true);
                MessageBox.Show($"Failed to generate DefaultRules.json: {ex.Message}",
                    "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                SetControlsEnabled(true);
                _cancellationTokenSource?.Dispose();
                _cancellationTokenSource = null;
            }
        }

        private void CheckDefaultRulesStatus()
        {
            var defaultRulesPath = txtDefaultRulesPath?.Text ?? "DefaultRules.json";
            
            // Check in script directory
            var scriptPath = GetPowerShellScriptPath();
            var fullPath = Path.IsPathRooted(defaultRulesPath) 
                ? defaultRulesPath 
                : Path.Combine(Path.GetDirectoryName(scriptPath) ?? "", defaultRulesPath);

            Dispatcher.Invoke(() =>
            {
                if (File.Exists(fullPath))
                {
                    var fileInfo = new FileInfo(fullPath);
                    txtDefaultRulesStatus.Text = $"✅ Found ({fileInfo.Length / 1024:N0} KB)";
                    txtDefaultRulesStatus.Foreground = System.Windows.Media.Brushes.LightGreen;
                }
                else
                {
                    txtDefaultRulesStatus.Text = "❌ Not found";
                    txtDefaultRulesStatus.Foreground = System.Windows.Media.Brushes.Orange;
                }
            });
        }

        #endregion

        #region Browse Dialogs

        private void BrowseCaptureOutput_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new SaveFileDialog
            {
                Filter = "JSON Files (*.json)|*.json|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*",
                DefaultExt = ".json",
                FileName = rbBaseline.IsChecked == true ? "baseline.json" : "postinstall.json"
            };

            if (dialog.ShowDialog() == true)
            {
                txtCaptureOutput.Text = dialog.FileName;
            }
        }

        private void BrowseBaseline_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*",
                DefaultExt = ".json"
            };

            if (dialog.ShowDialog() == true)
            {
                txtBaselineFile.Text = dialog.FileName;
            }
        }

        private void BrowsePostInstall_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*",
                DefaultExt = ".json"
            };

            if (dialog.ShowDialog() == true)
            {
                txtPostInstallFile.Text = dialog.FileName;
            }
        }

        private void BrowseCompareOutput_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new SaveFileDialog
            {
                Filter = "JSON Files (*.json)|*.json|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*",
                DefaultExt = ".json",
                FileName = "newrules"
            };

            if (dialog.ShowDialog() == true)
            {
                // Remove extension as RuleForge adds it based on format
                var fileName = Path.GetFileNameWithoutExtension(dialog.FileName);
                var directory = Path.GetDirectoryName(dialog.FileName);
                txtCompareOutput.Text = Path.Combine(directory!, fileName);
            }
        }

        private void BrowseDefaultRules_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*",
                DefaultExt = ".json",
                FileName = "DefaultRules.json"
            };

            if (dialog.ShowDialog() == true)
            {
                txtDefaultRulesPath.Text = dialog.FileName;
                CheckDefaultRulesStatus();
            }
        }

        #endregion

        #region Log and Utility Functions

        private void CopyLog_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                Clipboard.SetText(txtLog.Text);
                Log("📋 Log copied to clipboard.");
            }
            catch (Exception ex)
            {
                Log($"❌ Failed to copy to clipboard: {ex.Message}", true);
            }
        }

        private void ClearLogDisplay_Click(object sender, RoutedEventArgs e)
        {
            txtLog.Clear();
            _logBuffer.Clear();
            Log("🔥 Log cleared. Ready to forge firewall rules!");
        }

        private void OpenLogFolder_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var logDir = Path.GetDirectoryName(_logFilePath);
                if (Directory.Exists(logDir))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = logDir,
                        UseShellExecute = true
                    });
                    Log($"📂 Opened log folder: {logDir}");
                }
                else
                {
                    Directory.CreateDirectory(logDir!);
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = logDir,
                        UseShellExecute = true
                    });
                    Log($"📂 Created and opened log folder: {logDir}");
                }
            }
            catch (Exception ex)
            {
                Log($"❌ Failed to open log folder: {ex.Message}", true);
                MessageBox.Show($"Failed to open log folder: {ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void ClearLogs_Click(object sender, RoutedEventArgs e)
        {
            var result = MessageBox.Show(
                "Are you sure you want to delete all log files?",
                "Clear Logs",
                MessageBoxButton.YesNo, MessageBoxImage.Question);

            if (result != MessageBoxResult.Yes) return;

            try
            {
                if (File.Exists(_logFilePath))
                {
                    File.Delete(_logFilePath);
                    Log("🗑️ Log files cleared.");
                }
                else
                {
                    Log("ℹ️ No log files to clear.");
                }
            }
            catch (Exception ex)
            {
                Log($"❌ Failed to clear log files: {ex.Message}", true);
            }
        }

        #endregion
    }
}
