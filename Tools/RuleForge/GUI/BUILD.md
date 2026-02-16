# RuleForge GUI - Build and Compilation Guide

This guide provides step-by-step instructions to compile RuleForge GUI into a standalone Windows executable (.exe).

## 📋 Prerequisites

### Required Software

1. **.NET 8.0 SDK** (or later)
   - Download from: https://dotnet.microsoft.com/download/dotnet/8.0
   - Verify installation: `dotnet --version` (should show 8.0.x or higher)

2. **Windows 10/11** (for building WPF applications)
   - WPF is Windows-only and requires Windows to build

3. **(Optional) Visual Studio 2022**
   - Community Edition is free: https://visualstudio.microsoft.com/
   - Required workloads:
     - ".NET desktop development"
     - "Desktop development with C++"

## 🔨 Building from Command Line

### Quick Build (Debug)

```powershell
# Navigate to the GUI directory
cd Tools/RuleForge/GUI

# Restore packages and build
dotnet restore
dotnet build
```

### Release Build

```powershell
# Navigate to the GUI directory
cd Tools/RuleForge/GUI

# Build release version
dotnet build -c Release
```

The output will be in `bin/Release/net8.0-windows/`

## 📦 Publishing as Standalone Executable

### Option 1: Framework-Dependent (Smaller, requires .NET Runtime)

```powershell
# Navigate to the GUI directory
cd Tools/RuleForge/GUI

# Publish framework-dependent
dotnet publish -c Release -r win-x64 --self-contained false -o ./publish/framework-dependent
```

**Output:** `./publish/framework-dependent/RuleForgeGUI.exe`
- Requires .NET 8.0 Runtime installed on target machine
- Smaller file size (~500 KB)

### Option 2: Self-Contained (Larger, includes .NET Runtime)

```powershell
# Navigate to the GUI directory
cd Tools/RuleForge/GUI

# Publish self-contained
dotnet publish -c Release -r win-x64 --self-contained true -o ./publish/self-contained
```

**Output:** `./publish/self-contained/RuleForgeGUI.exe`
- No .NET Runtime installation required on target machine
- Larger file size (~150 MB total, includes all dependencies)

### Option 3: Single-File Executable (Recommended for Distribution)

```powershell
# Navigate to the GUI directory
cd Tools/RuleForge/GUI

# Publish as single file (self-contained)
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o ./publish/single-file
```

**Output:** `./publish/single-file/RuleForgeGUI.exe`
- Single executable file
- No external dependencies
- ~80-100 MB file size

### Option 4: Trimmed Single-File (Smallest Self-Contained)

```powershell
# Navigate to the GUI directory
cd Tools/RuleForge/GUI

# Publish trimmed single file
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=true -p:IncludeNativeLibrariesForSelfExtract=true -o ./publish/trimmed
```

**Output:** `./publish/trimmed/RuleForgeGUI.exe`
- Smallest self-contained option
- ~50-70 MB file size
- Note: Trimming may remove unused code, test thoroughly

## 🖥️ Building with Visual Studio

1. **Open the Solution**
   - Open Visual Studio 2022
   - File > Open > Project/Solution
   - Navigate to `Tools/RuleForge/GUI/RuleForgeGUI.csproj`

2. **Configure Build**
   - Select `Release` configuration from toolbar
   - Select `x64` platform (or `Any CPU`)

3. **Build**
   - Build > Build Solution (Ctrl+Shift+B)

4. **Publish**
   - Right-click project in Solution Explorer
   - Click "Publish..."
   - Choose "Folder" target
   - Configure settings:
     - Target Framework: net8.0-windows
     - Deployment mode: Self-contained or Framework-dependent
     - Target runtime: win-x64
   - Click "Publish"

## 📁 Required Files for Distribution

### Framework-Dependent Distribution
```
RuleForgeGUI.exe          # Main application
RuleForge.ps1             # PowerShell script (copy from parent directory)
DefaultRules.json         # (Optional) Default rules file
```

### Self-Contained Distribution
```
RuleForgeGUI.exe          # Main application (or single file)
RuleForge.ps1             # PowerShell script (copy from parent directory)
DefaultRules.json         # (Optional) Default rules file
```

### Important Notes
- Always include `RuleForge.ps1` in the same directory as the executable
- The GUI application calls the PowerShell script for all operations
- `DefaultRules.json` is optional but useful for filtering default Windows rules

## 🧪 Testing the Build

After building, test the executable:

```powershell
# Run the application
.\publish\single-file\RuleForgeGUI.exe

# Verify PowerShell script is accessible
# The application will show an error if RuleForge.ps1 is not found
```

## ⚠️ Troubleshooting

### Build Errors

1. **"Target framework not found"**
   - Install .NET 8.0 SDK from https://dotnet.microsoft.com/download

2. **"WPF is not supported on this platform"**
   - WPF requires Windows; cannot build on Linux/macOS

3. **"Package restore failed"**
   - Run `dotnet restore` manually
   - Check internet connection for NuGet packages

### Runtime Errors

1. **"RuleForge.ps1 not found"**
   - Copy `RuleForge.ps1` to the same directory as the executable
   - Or to the parent directory of the executable

2. **"PowerShell 7.0 required"**
   - Install PowerShell 7 from https://github.com/PowerShell/PowerShell/releases
   - The GUI uses the System.Management.Automation SDK

3. **"Administrator access required"**
   - Run the application as Administrator (right-click > Run as administrator)
   - Firewall rule capture requires elevated privileges

## 📊 Build Output Summary

| Build Type | Size | .NET Required | Portability |
|------------|------|---------------|-------------|
| Framework-Dependent | ~500 KB | Yes (.NET 8.0) | Low overhead |
| Self-Contained | ~150 MB | No | Full runtime included |
| Single-File | ~80-100 MB | No | One executable |
| Trimmed | ~50-70 MB | No | Smallest option |

## 🚀 Quick Start Script

Create a `build.ps1` script for easy building:

```powershell
# build.ps1 - RuleForge GUI Build Script
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    
    [ValidateSet("Framework", "SelfContained", "SingleFile", "Trimmed")]
    [string]$Type = "SingleFile"
)

$projectDir = $PSScriptRoot
Set-Location $projectDir

Write-Host "Building RuleForge GUI ($Configuration - $Type)..." -ForegroundColor Yellow

switch ($Type) {
    "Framework" {
        dotnet publish -c $Configuration -r win-x64 --self-contained false -o "./publish/framework"
    }
    "SelfContained" {
        dotnet publish -c $Configuration -r win-x64 --self-contained true -o "./publish/self-contained"
    }
    "SingleFile" {
        dotnet publish -c $Configuration -r win-x64 --self-contained true `
            -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true `
            -o "./publish/single-file"
    }
    "Trimmed" {
        dotnet publish -c $Configuration -r win-x64 --self-contained true `
            -p:PublishSingleFile=true -p:PublishTrimmed=true `
            -p:IncludeNativeLibrariesForSelfExtract=true `
            -o "./publish/trimmed"
    }
}

# Copy RuleForge.ps1
$publishDir = "./publish/$($Type.ToLower())"
Copy-Item "../RuleForge.ps1" -Destination $publishDir -Force

Write-Host "Build complete! Output: $publishDir" -ForegroundColor Green
```

Run with: `.\build.ps1 -Configuration Release -Type SingleFile`

## 📝 Version Information

- **RuleForge GUI Version:** 2.0.0
- **Target Framework:** .NET 8.0 Windows
- **Supported OS:** Windows 10/11
- **Required Runtime:** PowerShell 7.0+
