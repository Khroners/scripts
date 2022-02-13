Workflow New-ServerSetup # Workflow a remplacer par DSC
{
    param(
        [Parameter (Mandatory = $true)]
        [string]$Network,
        [string]$IPAddr,
        [string]$Mask,
        [string]$Gtw,
        [string]$DNSServer,
        [string]$DNSSuffix,
        [string]$DomainName,
        [string]$DefaultSite,
        [string]$SecurePwd,
        [string]$ServerName
    )
    # Network configuration
    $InterfaceIndex = $(Get-NetIPAddress | Where-Object {$_.InterfaceAlias -like "Ethernet*"}).InterfaceIndex
    $InterfaceAlias = $(Get-NetIPAddress | Where-Object {$_.InterfaceIndex -like $InterfaceIndex}).InterfaceAlias

    New-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -IPAddress $IP -PrefixLength $Masque -DefaultGateway $Gateway
    Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses $DNS
    Set-DnsClient -InterfaceIndex $InterfaceIndex -ConnectionSpecificSuffix $SuffixeDNS
    # Desactiver ipv6
    Disable-NetAdapterBinding -InterfaceAlias $InterfaceAlias -ComponentID ms_tcpip6

    Rename-Computer -NewName $NomServeur -Force -Passthru
    Restart-Computer -Wait

    Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
    Install-ADDSForest -DomainName $Domaine -SafeModeAdministratorPassword $SecurePassword -InstallDns -DomainMode WinThreshold -ForestMode WinThreshold -Force
    Add-DnsServerPrimaryZone -DynamicUpdate Secure -NetworkId $Reseau -ReplicationScope Domain

    New-ADReplicationSite -Name $SiteDefault -Description $SiteDefault
    New-ADReplicationSubnet -Name $Reseau -Site $SiteDefault
    # New-ADReplicationSiteLink -Name 'SL-Site1-Site2' -SitesIncluded Site1,Site2 -Cost 100 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
    Move-ADDirectoryServer -Identity $NomServeur -Site $SiteDefault
    Remove-ADReplicationSite -Identity "Default-First-Site-Name" -confirm:$false

    $domain = $Domaine.split(".")
    $Dom = $domain[0]
    $Ext = $domain[1]

    # Activer la corbeille AD
    Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $Domaine

    $Sites = ("RENNES","VANNES","BREST","SAINT-BRIEUC")
    $Bases = ("Groups","Users","Workstations","Servers","Printers")
    $Services = ("Production","Marketing","IT","Direction","Helpdesk")
    $FirstOU = "Sites"

    New-ADOrganizationalUnit -Name $FirstOU -Description $FirstOU -Path "DC=$Dom,DC=$EXT"


    foreach ($S in $Sites)
    {
            New-ADOrganizationalUnit -Name $S -Description "$S" -Path "OU=$FirstOU,DC=$Dom,DC=$EXT"

        foreach ($Base in $Bases)
        {
            New-ADOrganizationalUnit -Name $Base -Description "$Base" -Path "OU=$S,OU=$FirstOU,DC=$Dom,DC=$EXT"

            foreach ($Serv in $Services)
            {
                New-ADOrganizationalUnit -Name $Serv -Description "$S $Serv" -Path "OU=Users,OU=$S,OU=$FirstOU,DC=$Dom,DC=$EXT"
            }
        }
    }

    Unregister-ScheduledJob -Name NewServerSetupResume
}

$AtStartup = New-JobTrigger -AtStartup
Register-ScheduledJob -Name NewServerSetupResume `
                      -Trigger $AtStartup `
                      -ScriptBlock {Import-Module PSWorkflow; `
                            Get-Job -Name NewSrvSetup -State Suspended `
                            | Resume-Job}


$Reseau = Read-Host("Entrez l'adresse reseau (10.0.0.0/24 par ex)")
$IP = Read-Host("Entrez l'adresse IP")
$Masque = Read-Host("Entrez le masque (Ex: 24 pour /24)")
$Gateway = Read-Host("Entrez l'adresse IP de la passerelle")
$DNS = Read-Host("Entrez le serveur DNS")
$SuffixeDNS = Read-Host("Entrez le suffixe DNS")
$Domaine = Read-Host("Entrez le nom de domaine Active Directory")
$SiteDefault = Read-Host("Entrez le site AD par defaut")
$SecurePassword = Read-Host("Entrez le mot de passe DSRM") | ConvertTo-SecureString -AsPlainText -Force
$NomServeur = Read-Host("Entrez le nom du serveur")

# Run Workflow



New-ServerSetup -JobName NewSrvSetup -Network $Reseau -IPAddr $IP -Mask $Masque -Gtw $Gateway -DNSServer $DNS -DNSSuffix $SuffixeDNS -DomainName $Domaine -DefaultSite $SiteDefault -SecurePwd $SecurePassword -ServerName $NomServeur
