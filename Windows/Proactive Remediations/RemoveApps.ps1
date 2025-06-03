<#
    .SYNOPSIS
        Split Detection and Remediation scripts in two and upload to Proactive Remediations 
        
    .DESCRIPTION
        Detects and removes software specified in Variables
        To remove multiple simple add the software in both $programs variables: @('Dell SupportAssist','Dell CommandUpdate','Dell Update')
    .NOTES
        Author:      Dirk Bester
        Created:     2022-01-24
        Updated:     2022-01-25
        Version history:
        1.0.0
#>

# Detection Script

# Define Variables
$programs = @('HP Connection Optimizer','HP Documentation','HP Notifications','HP Wolf Security','HP Wolf Security - Console','HP Wolf Security Application Support for Sure Sense','HP Security Update Service') 

Try{
foreach($program in $programs){
    if($app = Get-WmiObject Win32_Product -Filter "Name='$program'"){
    }
}

# Detection: Exit code 0 no Remediation required. Exit code 1 Remediation will be triggered.
if($app -eq $null) {
    Write-Host "No Software Found"
    exit 0
    }
    else { 
        # Found Match, remediate
        Write-Host "Software Found"
        exit 1
}
}
Catch{
    $errorNessage = $_.Exception.Message
    Write-Error $errorNessage
    Exit 1
}

# Remediation Script

# Define Variables
$programs = @('HP Connection Optimizer','HP Documentation','HP Notifications','HP Wolf Security','HP Wolf Security - Console','HP Wolf Security Application Support for Sure Sense','HP Security Update Service') 

# Remove specified applications in Variables
Try{
foreach($program in $programs){
    if($app = Get-WmiObject Win32_Product -Filter "Name='$program'"){
    $app.Uninstall()
    }
}

# Check if applications have been removed. Exit code 0 = Successful. Exit code 1 = Failed
if($app -eq $null) {
    Write-Host "No Software Found"
    exit 0
    }
    else { 
        
        Write-Host "Software Still Found"
}
}
Catch{
    $errorNessage = $_.Exception.Message
    Write-Error $errorNessage
    Exit 1
}
