param(
    [Parameter (Mandatory = $true)]
    [string]$IPAddr,
    [string]$Mask,
    [string]$Gtw,
    [string]$DNSServer,
    [string]$DNSSuffix,
    [string]$ServerName,
    [string]$Domain,
    [string]$SourceDC,
    [string]$Site
)

$InterfaceIndex = $(Get-NetIPAddress | Where-Object {$_.InterfaceAlias -like "Ethernet*" -and $_.AddressFamily -like "IPv4"}).InterfaceIndex
$InterfaceAlias = $(Get-NetIPAddress | Where-Object {$_.InterfaceIndex -like $InterfaceIndex}).InterfaceAlias

New-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -IPAddress $IPAddr -PrefixLength $Mask -DefaultGateway $Gtw
Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses $DNSServer
Set-DnsClient -InterfaceIndex $InterfaceIndex -ConnectionSpecificSuffix $DNSSuffix
# Desactiver ipv6
Disable-NetAdapterBinding -InterfaceAlias $InterfaceAlias -ComponentID ms_tcpip6

Rename-Computer -NewName $ServerName -Force -Passthru
Restart-Computer

# AJOUTER WORKFLOW

Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

# Promote DC02 to a Domain Controller #
Import-Module ADDSDeployment
Install-ADDSDomainController `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-Credential (Get-Credential) `
-CriticalReplicationOnly:$false `
-DomainName $Domain `
-InstallDns:$true `
-NoRebootOnCompletion:$false `
-ReplicationSourceDC $SourceDC `
-SiteName $Site `
-Force:$true

# Login after the reboot and run the post DC Promo script
