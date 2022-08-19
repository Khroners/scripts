# OK

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
    `$IPaddr = Get-NetIPAddress -InterfaceIndex 8
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
    # Etendue
    Add-DhcpServerv4Scope -name "RENNES1" -StartRange 10.35.0.1 -EndRange 10.35.0.254 -SubnetMask 255.255.255.0 -State "Active"
    Add-DhcpServerv4ExclusionRange -ScopeID 10.35.0.0 -StartRange 10.35.0.1 -EndRange 10.35.0.49
    Add-DhcpServerv4ExclusionRange -ScopeID 10.35.0.0 -StartRange 10.35.0.200 -EndRange 10.35.0.254
    Set-DhcpServerv4OptionValue -OptionID 3 -Value 10.35.0.254 -ScopeID 10.35.0.0 -ComputerName `$FQDN
    Set-DhcpServerv4OptionValue -DnsDomain `$DomainName -DnsServer 10.35.0.1, 10.35.0.2 -ScopeID 10.35.0.0
"@

$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
Invoke-VMScript -vm $vm -ScriptText $script -GuestCredential $GuestCrendials