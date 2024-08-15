try
{  

$chromeInstalled = Test-Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'

if ($chromeInstalled -eq 'True') {
    Write-Host "Google Chrome is installed locally"
    exit 1
    }
    else {
        #No remediation required    
        Write-Host "Google Chrome is not installed locally"
        exit 0
    }  
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    # exit 1
}