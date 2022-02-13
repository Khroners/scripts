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

    New-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -IPAddress $IPAddr -PrefixLength $Mask -DefaultGateway $Gtw
    Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses $DNSServer
    Set-DnsClient -InterfaceIndex $InterfaceIndex -ConnectionSpecificSuffix $DNSSuffix
    # Desactiver ipv6
    Disable-NetAdapterBinding -InterfaceAlias $InterfaceAlias -ComponentID ms_tcpip6

    Rename-Computer -NewName $ServerName -Force -Passthru
    Restart-Computer -Wait

    Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
    
    InlineScript
    {
        & "$env:USERPROFILE\Downloads\InstallForest.ps1 -DomainName $DomainName -DefaultSite $DefaultSite -SecurePwd $SecurePwd -ServerName $ServerName"
    }
    InlineScript
    {
        & "$env:USERPROFILE\Downloads\PostConfig.ps1 -DefaultSite $DefaultSite -Network $Network -ServerName $ServerName -Domaine $DomainName"
    }
    InlineScript
    {
        & "$env:USERPROFILE\Downloads\OUStructure.ps1 -Dom $Dom -EXT $EXT"
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

$InstallForestPS1 = @"
param(
    [Parameter (Mandatory = $true)]
    [string]$DomainName,
    [string]$DefaultSite,
    [string]$SecurePwd,
    [string]$ServerName
)

Import-Module ADDSDeployment
Install-ADDSForest -DomainName $DomainName -SafeModeAdministratorPassword $SecurePassword -InstallDns -DomainMode WinThreshold -ForestMode WinThreshold -Force
"@

$InstallForestPS1 | out-file -FilePath "$env:USERPROFILE\Downloads\InstallForest.ps1" -Force

$PostConfigPS1 = @"
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

    $domain = $Domaine.split(".")
    $Dom = $domain[0]
    $Ext = $domain[1]

    # Activer la corbeille AD
    Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $DomainName
"@

$PostConfigPS1 | out-file -FilePath "$env:USERPROFILE\Downloads\PostConfig.ps1" -Force

$OUStructurePS1 = @"
    param(
        [Parameter (Mandatory = $true)]
        [string]$Dom,
        [string]$EXT
    )
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
"@

$OUStructurePS1 | out-file -FilePath "$env:USERPROFILE\Downloads\OUStructure.ps1" -Force

# Run Workflow

New-ServerSetup -JobName NewSrvSetup -Network $Reseau -IPAddr $IP -Mask $Masque -Gtw $Gateway -DNSServer $DNS -DNSSuffix $SuffixeDNS -DomainName $Domaine -DefaultSite $SiteDefault -SecurePwd $SecurePassword -ServerName $NomServeur
