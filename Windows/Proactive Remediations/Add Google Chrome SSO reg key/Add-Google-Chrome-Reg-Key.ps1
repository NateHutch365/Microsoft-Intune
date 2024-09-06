###############################
# ChromeAPAuthEnabled - detect
###############################
 
$regkey="HKLM:\Software\Policies\Google\Chrome"
$name="CloudAPAuthEnabled"
$value=1
 
# Registry Detection Template
If (!(Test-Path $regkey)) {
    Write-Output 'RegKey not available - remediate'
    Exit 1
}
 
 
$check=(Get-ItemProperty -path $regkey -name $name -ErrorAction SilentlyContinue).$name
    if ($check -eq $value){
        write-output 'setting ok - no remediation required'
        Exit 0
}
else {
    write-output 'value not ok, no value or could not read - go and remediate'
    Exit 1
}
 
 
##################################
# ChromeAPAuthEnabled - remediate
##################################
 
$regkey="HKLM:\Software\Policies\Google\Chrome"
$name="CloudAPAuthEnabled"
$value=1
 
# Registry Template
 
If (!(Test-Path $regkey)) {
    New-Item -Path $regkey -ErrorAction stop
}
 
if (!(Get-ItemProperty -Path $regkey -Name $name -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regkey -Name $name -Value $value -PropertyType DWORD -ErrorAction stop
    write-output "New RegKey path created"
    set-ItemProperty -Path $regkey -Name $name -Value $value -ErrorAction stop
    write-output "New RegKey created"
}
 
# Recheck Key creation
$check=(Get-ItemProperty -path $regkey -name $name -ErrorAction SilentlyContinue).$name
    if ($check -eq $value){
        write-output 'setting ok - remediation completed'
        Exit 0
}
else {
    write-output 'remediation failed'
    Exit 1
}
 
 