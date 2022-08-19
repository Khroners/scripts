$port = Read-Host("Entrez le port RDP")
$NomVM = Read-Host("Entrez le nom de la VM")
$server = Read-Host("Entrez le FQDN du serveur ESXI")
Write-Host "Entrez ici les logins du serveur ESXI"
Connect-VIServer -Server $server
$script = @"
   # Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'PortNumber' -Value $port
   # New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Domain' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port 
   # New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Domain' -Direction Inbound -Action Allow -Protocol UDP -LocalPort $port 
   # Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
   Write-Host "Test"
"@

$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
Write-Host "Entrez ici les logins de la VM"
$GuestCrendials = Get-Credential
Invoke-VMScript -vm $vm -ScriptText $script -GuestCredential $GuestCrendials