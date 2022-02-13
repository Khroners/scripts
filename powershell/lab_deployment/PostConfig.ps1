param(
    [Parameter (Mandatory = $true)]
    [string]$DefaultSite,
    [string]$Network,
    [string]$ServerName,
    [string]$Domaine
)
Add-DnsServerPrimaryZone -DynamicUpdate Secure -NetworkId $Network -ReplicationScope Domain

New-ADReplicationSite -Name $DefaultSite -Description $DefaultSite
New-ADReplicationSubnet -Name $Network -Site $DefaultSite
# New-ADReplicationSiteLink -Name 'SL-Site1-Site2' -SitesIncluded Site1,Site2 -Cost 100 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
Move-ADDirectoryServer -Identity $ServerName -Site $DefaultSite
Remove-ADReplicationSite -Identity "Default-First-Site-Name" -confirm:$false

# Activer la corbeille AD
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $Domaine