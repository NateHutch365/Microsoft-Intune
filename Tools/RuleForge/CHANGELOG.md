# Changelog

All notable changes to RuleForge are hammered out in this file.

## [2.0.0] - GUI Release - 2025
### Added
- **WPF GUI Application**: New graphical user interface for RuleForge
  - Modern blacksmith-themed dark interface with orange accents
  - Tabbed layout: Capture Rules, Compare Rules, Settings
  - Real-time progress bar with percentage display
  - Integrated debug log viewer with timestamps
  - Auto-save debug logs to file for troubleshooting
  - File browser dialogs for all input/output operations
  - DefaultRules.json status checking and generation
  - Support for all existing CLI functionality through the GUI
- **Build Documentation**: Comprehensive compilation guide (BUILD.md)
  - Prerequisites and setup instructions
  - Multiple build configurations (Framework-Dependent, Self-Contained, Single-File, Trimmed)
  - Visual Studio and command-line build options
  - Troubleshooting guide

### Changed
- **Project Structure**: GUI application in separate `GUI/` folder
- **Documentation**: Updated README.md with GUI information and installation instructions

### Preserved
- **CLI Version**: Original PowerShell script (RuleForge.ps1) remains fully functional
- **Menu Mode**: Interactive console menu still available
- All existing parameters and functionality unchanged

## [1.2.1] - 28-03-2025
### Changed
- **Code Refactoring & Modularization**:  
  - Consolidated duplicate logic into helper functions (`New-DefaultRules`, `Get-FilteredFirewallRules`, and `Export-RuleSet`) to improve maintainability without altering external functionality.
- **Cmdlet Verb Correction**:  
  - Renamed `Generate-DefaultRules` to `New-DefaultRules` in accordance with approved PowerShell verbs.
  
### Fixed
- **Output File Naming**:  
  - Corrected the naming issue so that baseline and post-install output files are now correctly named (e.g., "baseline.json" instead of "baseline.json.json").

## [1.2] - 27-02-2025
### Added
- **Interactive Menu System**: Ignite `.\RuleForge.ps1` without switches for a blazing menu:
  - Options: Capture Baseline, Capture Post-Install, Compare Rules, Exit.
  - Guided prompts with defaults (e.g., `baseline.json`, JSON output).
  - Loops back to menu post-action for continuous forging.
- **Colored Text**: ANSI colors via `$PSStyle` in PowerShell 7:
  - Yellow startup: "Firing up the forge! - Welcome to RuleForge v1.2".
  - Red exit: "Extinguishing the forge – RuleForge stopped."
  - Yellow warnings, red errors in menu mode.
- **DefaultRules.json Prompt**: Menu offers to craft `DefaultRules.json` if missing, with OOBE guidance.
- **Thematic Flair**: Blacksmith-inspired messages (e.g., “Firing up the forge!”).

### Changed
- **Prompts**: Refined menu prompts for clarity:
  - "Output filename (press Enter to accept default: baseline.json)".
  - "Output format (JSON/CSV, press Enter to accept default: JSON)".
  - "Profile type (All/Private/Public/Domain, use commas for multiples e.g., Private,Public; press Enter to accept default: All)".
- **Author**: Updated to "Nathan Hutchinson / Grok3" in script header.
- **README**: Overhauled with menu mode details, keeping CLI switch docs intact.

### Fixed
- **DefaultRules.json Creation**: Added progress bar and fixed JSON array formatting (e.g., `remotePortRanges` as `["2869"]`).

## [1.1] - 26-02-2025
### Added
- **`-SkipDefaultRules` Switch**: Excludes default Windows rules from capture using `DefaultRules.json`.
- **Sample File**: Included `DefaultRules-Win11-24H2.json` with 437 rules from Windows 11 24H2 (Feb 2025 ISO).
- **README Guidance**: Instructions for generating `DefaultRules.json` on a fresh system.

### Changed
- **Requirements**: Locked to PowerShell 7.0+ (due to `??` operator incompatibility with 5.1).
- **Version**: Bumped to 1.1 in script header.

## [1.0] - 25-02-2025
### Initial Release
- Core functionality to capture, compare, and export firewall rules for Intune:
  - `-Capture` mode: Baseline/PostInstall to JSON/CSV.
  - `-Compare` mode: Diffs two JSONs to JSON/CSV/Table.
  - Filters: `-SkipDisabled`, `-ProfileType`.
  - Debug: `-DebugOutput`.
- Published to [GitHub](https://github.com/NateHutch365/Microsoft-Intune/tree/main/Tools/RuleForge).
