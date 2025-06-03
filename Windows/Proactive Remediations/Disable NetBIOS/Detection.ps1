#Detection Script
$Path = "HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces\tcpip*"
$Name = "NetbiosOptions"
$Type = "DWORD"
$Value = 2

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
	$Counter = 0
	Foreach ($Entry in $Registry )
	{
		If ($Entry -eq $Value)
			{
				$Counter+=0
			}
        else
            {
                $Counter+=1
            }
    } 
	if($Counter -eq 0) 
		{
			Write-Output "OK"
			Exit 0
		}
	else 
		{
			Write-Warning "Not OK" 
			exit 1
		}
} 
Catch {
    Write-Warning "Not OK"
    Exit 1
}