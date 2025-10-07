<#
    .SYNOPSIS
        Evergreen installer for the Global Secure Access (GSA) client.
   
    .NOTES
        Author: James Robinson | SkipToTheEndpoint | https://skiptotheendpoint.co.uk
        Version: v1
        Release Date: 03/10/2025

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

### Import required assemblies - Required due to WebClient deprecation: https://learn.microsoft.com/en-us/dotnet/core/compatibility/networking/6.0/webrequest-deprecated
Add-Type -AssemblyName System.Net.Http

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
    Begin {
        # Create httpClient object
        $httpClient = New-Object System.Net.Http.HttpClient
        $response = $httpClient.GetAsync($URL)
        $response.Wait()
    }
    Process {
        # Create path if it doesn't exist
        If (-not(Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
        # Create file stream
        $outputFileStream = [System.IO.FileStream]::new((Join-Path -Path $Path -ChildPath $Name), [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        # Download file
        $downloadTask = $response.Result.Content.CopyToAsync($outputFileStream)
        $downloadTask.Wait()
        # Close the file stream
        $outputFileStream.Close()
    }
    End {
        # Dispose of httpClient object
        $httpClient.Dispose()
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
    Write-Host "Installing: $($FileName)"
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
    If ($Proc.ExitCode -eq '0') {
        Write-Host "SUCCESS: Operation succeeded with exit code: $($Proc.ExitCode)"
        Exit $($Proc.ExitCode)
    }
    Else {
        Write-Host "FAILURE: Operation failed with exit code: $($Proc.ExitCode)"
        Exit $($Proc.ExitCode)
    }
    Stop-Transcript
}