# Network configuration & renaming server with reboot

$NomVM = Read-Host("Entrez le nom de la VM")
$server = Read-Host("Entrez le FQDN du serveur ESXI")
Write-Host "Entrez ici les logins du serveur ESXI"
Connect-VIServer -Server $server

$IPAddr = Read-Host("Entrez l'adresse IP")
$Mask = Read-Host("Entrez le masque (24 pour /24)")
$Gtw = Read-Host("Entrez la passerelle")
$DNSServer = Read-Host("Entrez le serveur DNS")
$DNSSuffix = Read-Host("Entrez le suffixe DNS")
$ServerName = Read-Host("Entrez le nom du serveur")

$script = @"
    `$InterfaceIndex = `$(Get-NetIPAddress | Where-Object {`$_.InterfaceAlias -like "Ethernet*" -and `$_.AddressFamily -like "IPv4"}).InterfaceIndex
    `$InterfaceAlias = `$(Get-NetIPAddress | Where-Object {`$_.InterfaceIndex -like `$InterfaceIndex}).InterfaceAlias

    New-NetIPAddress -InterfaceIndex `$InterfaceIndex -AddressFamily IPv4 -IPAddress $IPAddr -PrefixLength $Mask -DefaultGateway $Gtw
    Set-DnsClientServerAddress -InterfaceIndex `$InterfaceIndex -ServerAddresses $DNSServer
    Set-DnsClient -InterfaceIndex `$InterfaceIndex -ConnectionSpecificSuffix $DNSSuffix
    # Desactiver ipv6
    Disable-NetAdapterBinding -InterfaceAlias `$InterfaceAlias -ComponentID ms_tcpip6

    Rename-Computer -NewName $ServerName -Force -Passthru
    Restart-Computer -Force
"@

$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
Write-Host "Entrez ici les logins de la VM"
$GuestCrendials = Get-Credential
Invoke-VMScript -vm $vm -ScriptText $script -GuestCredential $GuestCrendials