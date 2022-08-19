# OK

$FQDNpremierDHCP = Read-Host("Entrez le FQDN du premier serveur DHCP (maitre)")
$NomVM = Read-Host("Entrez le nom de la VM")
Write-Host "Entrez ici les logins de la VM"
$userID = Read-Host("Entrez le nom d'utilisateur du domaine")
$GuestCrendials = Get-Credential $userID -Message "Please Enter your Domain account password."
$DomainAccountPWD = ($GuestCrendials).GetNetworkCredential().Password

# decommenter si vous n'etes pas encore connecté

# $server = Read-Host("Entrez le FQDN du serveur ESXI")
# Write-Host "Entrez ici les logins du serveur ESXI"
# Connect-VIServer -Server $server

$script = @"
    `$InterfaceIndex = `$(Get-NetIPAddress | Where-Object {`$_.InterfaceAlias -like "Ethernet*" -and `$_.AddressFamily -like "IPv4"}).InterfaceIndex
    `$IPaddr = Get-NetIPAddress -InterfaceIndex `$InterfaceIndex
    `$FQDN = [System.Net.Dns]::GetHostByName((hostname)).HostName
    `$DomainName = `$env:USERDNSDOMAIN.toLower()
    `$username = "$userID"
    `$password = "$DomainAccountPWD" | ConvertTo-SecureString -asPlainText -force
    `$credential = New-Object System.Management.Automation.PSCredential(`$username, `$password)
    Install-WindowsFeature DHCP -IncludeManagementTools
    netsh dhcp add securitygroups
    Restart-Service dhcpserver
    Add-DhcpServerInDC -DnsName `$FQDN -IPAddress `$IPaddr.IPAddress
    Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2
    Set-DhcpServerv4DnsSetting -ComputerName `$FQDN -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry `$True
    Set-DhcpServerDnsCredential -Credential `$credential -ComputerName `$FQDN
    Add-DhcpServerv4Failover -ComputerName $FQDNpremierDHCP -PartnerServer `$FQDN -Name dhcp1-dhcp2 -ScopeID 10.35.0.0 -LoadBalancePercent 50 -SharedSecret A4C1f5ggrt5gcz9PaNu47IJIkl478AgW4 -Force
"@

$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
Invoke-VMScript -vm $vm -ScriptText $script -GuestCredential $GuestCrendials