# Network configuration, RDP, renaming, add domain controller to existing domain, AD sites & replications

Function Start-SleepProgress($seconds) {
    $s = 0;
    Do {
        $p = [math]::Round(100 - (($seconds - $s) / $seconds * 100));
        Write-Progress -Activity "Waiting..." -Status "$p% Complete:" -SecondsRemaining ($seconds - $s) -PercentComplete $p;
        [System.Threading.Thread]::Sleep(1000)
        $s++;
    }
    While($s -lt $seconds);
    
}

$esxi = Read-Host("Enter IP address of ESXI server")
$NomVM = Read-Host("Enter the name of the VM")
$domainName = Read-Host("Enter the domain name")
$domainUser = Read-Host("Enter the username (AD\user for exemple")

$Network = Read-Host("Entrez l'adresse reseau (10.0.0.0/24 par ex)")
$IPAddr = Read-Host("Entrez l'adresse IP")
$Mask = Read-Host("Entrez le masque (Ex: 24 pour /24)")
$Gtw = Read-Host("Entrez l'adresse IP de la passerelle")
$DNSServer = Read-Host("Entrez le serveur DNS")
$DNSSuffix = Read-Host("Entrez le suffixe DNS")
$Port = Read-Host("Entrez le port RDP")
$Site = Read-Host("Entrez le nouveau site AD")
$ServerName = Read-Host("Entrez le nom du serveur")
$SecurePassword = Read-Host "Entrez le mot de passe DSRM"


# Connection à l'ESXI et la VM
Connect-VIServer $esxi
$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
Write-Host "Entrez les logins de la VM"
$cred = Get-Credential Administrateur

# Domaine AD
$userID = $domainUser
$DomainAccountPWD = (Get-Credential $userID -Message "Entrez le MDP du compte admin du domaine").GetNetworkCredential().Password


# Configuration de la carte reseau
$script1 = @"
    `$InterfaceIndex = `$(Get-NetIPAddress | Where-Object {`$_.InterfaceAlias -like "Ethernet*" -and `$_.AddressFamily -like "IPv4"}).InterfaceIndex
    `$InterfaceAlias = `$(Get-NetIPAddress | Where-Object {`$_.InterfaceIndex -like `$InterfaceIndex}).InterfaceAlias
    New-NetIPAddress -InterfaceIndex `$InterfaceIndex -AddressFamily IPv4 -IPAddress $IPAddr -PrefixLength $Mask -DefaultGateway $Gtw
    Set-DnsClientServerAddress -InterfaceIndex `$InterfaceIndex -ServerAddresses $DNSServer
    Set-DnsClient -InterfaceIndex `$InterfaceIndex -ConnectionSpecificSuffix $DNSSuffix
    # Desactiver ipv6
    Disable-NetAdapterBinding -InterfaceAlias `$InterfaceAlias -ComponentID ms_tcpip6

    # Activer le bureau a distance sur un port RDP personnalisé
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'PortNumber' -Value $Port
    New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Domain' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port 
    New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Domain' -Direction Inbound -Action Allow -Protocol UDP -LocalPort $Port 

    # Renommage du serveur et redémarrage
    Rename-Computer -NewName $ServerName -Force -Passthru -Restart
"@

 
Invoke-VMScript -VM $vm -ScriptText $script1 -Verbose -GuestCredential $cred

Start-SleepProgress 45

# Installation des services AD DS avec RSAT
$script2 = @"
`$domain = "$domainName"
`$password = "$DomainAccountPWD" | ConvertTo-SecureString -asPlainText -force;
`$username = "$userID";
`$credential = New-Object System.Management.Automation.PSCredential(`$username, `$password);
`$SecurePassword = "$SecurePassword" | ConvertTo-SecureString -AsPlainText -Force
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment
Install-ADDSDomainController -InstallDns -SafeModeAdministratorPassword `$SecurePassword -Credential `$credential -DomainName `$domain -Force
"@

Invoke-VMScript -VM $vm -ScriptText $script2 -Verbose -GuestCredential $cred

Start-SleepProgress 300

# PostConfigAD
$script3 = @"
Add-DnsServerPrimaryZone -DynamicUpdate Secure -NetworkId $Network -ReplicationScope Domain
New-ADReplicationSite -Name $Site -Description $Site
New-ADReplicationSubnet -Name $Network -Site $Site
Move-ADDirectoryServer -Identity $ServerName -Site $Site
"@

$password = "$DomainAccountPWD" | ConvertTo-SecureString -asPlainText -force;
$credential = New-Object System.Management.Automation.PSCredential($userID, $password);

Invoke-VMScript -VM $vm -ScriptText $script3 -Verbose -GuestCredential $credential

Start-SleepProgress 5

#$NomVM = Read-Host("Entrez le nom de la VM")
#$FiltreVM = "*" + $NomVM + "*"

#Write-Host "Entrez ici les logins de la VM"

#$userID = Read-Host("Entrez le nom d'utilisateur du domaine")
#$GuestCrendials = Get-Credential $userID -Message "Please Enter your Domain account password."                     
#$DomainAccountPWD = ($GuestCrendials).GetNetworkCredential().Password
#$server = Read-Host("Entrez le FQDN du serveur ESXI")
#Write-Host "Entrez ici les logins du serveur ESXI"
#Connect-VIServer -Server $server

#$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}

#Invoke-VMScript -ScriptText $script -VM $vm -GuestCredential $GuestCrendials