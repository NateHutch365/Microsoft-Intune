# Changelog

All notable changes to RuleForge will be documented in this file.

## [1.1] - 2025-03-XX
### Added
- `-SkipDefaultRules` switch to exclude default Windows firewall rules listed in `DefaultRules.json` during capture. Speeds up processing by skipping system rules (e.g., 437 rules in Windows 11 24H2 OOBE reduced from 82s).
- Sample `DefaultRules-Win11-24H2.json` file with 437 default rules from a fresh Windows 11 24H2 (Feb 2025 ISO) install.
- README guidance for generating `DefaultRules.json` via initial baseline capture.

### Changed
- Updated script version from 1.0 to 1.1 in the `.VERSION` header.

## [1.0] - 2025-02-27
### Initial Release
- Core functionality to capture, compare, and export Windows Defender firewall rules for Intune integration.
- Features:
  - `-Capture` mode with `Baseline` and `PostInstall` types, outputting JSON or CSV.
  - `-Compare` mode to identify new rules between two JSON captures, outputting JSON, CSV, or table.
  - Filtering options: `-SkipDisabled`, `-ProfileType`.
  - Debug support with `-DebugOutput`.
- Published to GitHub: `https://github.com/NateHutch365/Microsoft-Intune/tree/main/Tools/RuleForge`.