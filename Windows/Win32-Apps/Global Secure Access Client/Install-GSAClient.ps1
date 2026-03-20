<#
    .SYNOPSIS
        Evergreen installer for the Global Secure Access (GSA) client.
   
    .NOTES
        Author: James Robinson | SkipToTheEndpoint | https://skiptotheendpoint.co.uk
        Version: v1
        Release Date: 03/10/2025

        Modified By: Nate Hutchinson | NateHutch365
        Modified Date: 20/03/2026
        Changes:
            - Replaced HttpClient async download with WebClient to fix AggregateException
              failures under SYSTEM context in PowerShell 5.1 (.NET Framework)
            - Added forced TLS 1.2 negotiation to prevent SSL/TLS handshake failures
            - Fixed $Proc.ExitCode null reference in Finally block when download fails
            - Fixed copy/paste typo in Uninstall-GSA log message ("Installing" -> "Uninstalling")
            - Removed System.Net.Http assembly import (no longer required)

        Intune Info:
        Install Command:    %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\Install-GSAClient.ps1 -Install
        Uninstall Command:  %windir%\SysNative\WindowsPowershell\v1.0\powershell.exe -noprofile -executionpolicy bypass -file .\Install-GSAClient.ps1 -Uninstall
        Detection Rule:     File - C:\Program Files\Global Secure Access Client\GlobalSecureAccessClientManagerService.exe
#>

Param(
    [switch]$Install,
    [switch]$Uninstall
)

#### Logging Variables ####
$Script:ScriptName = "Install-GSAClient"
$Script:LogFile = "$ScriptName.log"
$Script:LogsFolder = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"

### Functions ###
function Start-Logging {
    Start-Transcript -Path $LogsFolder\$LogFile -Append
    Write-Host "Current script timestamp: $(Get-Date -f yyyy-MM-dd_HH-mm)"
}

function Get-File {
    Param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$URL,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    # Force TLS 1.2 - required for SYSTEM context on PowerShell 5.1 / .NET Framework 4.x
    # Without this, HTTPS handshakes to aka.ms / download.microsoft.com can fail silently
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Create destination path if it doesn't exist
    If (-not(Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }

    $destination = Join-Path -Path $Path -ChildPath $Name

    # Use WebClient for synchronous download - more reliable than HttpClient async under
    # SYSTEM context in PS 5.1. Note: WebClient deprecation only applies to .NET Core 6+,
    # not .NET Framework which PS 5.1 uses (CLR 4.x).
    Try {
        Write-Host "Downloading to: $destination"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($URL, $destination)
        Write-Host "Download complete"
    }
    Catch {
        Throw "Download failed from $URL - $($_.Exception.Message)"
    }
    Finally {
        if ($null -ne $webClient) {
            $webClient.Dispose()
        }
    }
}

function Get-GSA {
    $arch = $env:PROCESSOR_ARCHITECTURE
    If ($arch -eq 'AMD64') {
        Write-Host "Downloading latest GSA X64 Installer"
        $GSAURL = "https://aka.ms/GlobalSecureAccess-windows"
        $Script:FileName = "GlobalSecureAccessClient.exe"
    } 
    ElseIf ($arch -eq 'ARM64') {
        Write-Host "Downloading latest GSA ARM64 Installer"
        $GSAURL = "https://aka.ms/GlobalSecureAccess-WindowsOnArm"
        $Script:FileName = "GlobalSecureAccessClientArm64.exe"
    } 
    Else {
        Throw "Unsupported architecture: $arch"
    }
    
    Get-File -URL $GSAURL -Path "$env:TEMP" -Name $FileName
}

function Install-GSA {
    Write-Host "Installing: $($FileName)"
    Try {
        $Script:Proc = Start-Process $env:TEMP\$FileName -ArgumentList "/install /quiet /norestart" -Wait -PassThru -ErrorAction Stop
    }
    Catch {
        Write-Error "$($_.Exception.Message)"
    }
}

function Uninstall-GSA {
    Write-Host "Uninstalling: $($FileName)"
    Try {
        $Script:Proc = Start-Process $env:TEMP\$FileName -ArgumentList "/uninstall /quiet /norestart" -Wait -PassThru -ErrorAction Stop
    }
    Catch {
        Write-Error "$($_.Exception.Message)"
    }
}

### Main
Start-Logging

Try {
    Get-GSA
    If ($Install) {
        Install-GSA
    } 
    ElseIf ($Uninstall) {
        Uninstall-GSA
    }
}
Catch {
    Write-Error "$($_.Exception.Message)"
}

Finally {
    # Guard against $Proc being null if the script failed before reaching install/uninstall
    If ($null -ne $Script:Proc) {
        If ($Proc.ExitCode -eq 0) {
            Write-Host "SUCCESS: Operation succeeded with exit code: $($Proc.ExitCode)"
            Stop-Transcript
            Exit $($Proc.ExitCode)
        }
        Else {
            Write-Host "FAILURE: Operation failed with exit code: $($Proc.ExitCode)"
            Stop-Transcript
            Exit $($Proc.ExitCode)
        }
    }
    Else {
        Write-Host "FAILURE: Script did not reach install/uninstall stage. Check log for download errors."
        Stop-Transcript
        Exit 1
    }
}