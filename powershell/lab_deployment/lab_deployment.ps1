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

    $domain = $DomainName.split(".")
    $Dom = $domain[0]
    $Ext = $domain[1]

    # Network configuration
    $InterfaceIndex = $(Get-NetIPAddress | Where-Object {$_.InterfaceAlias -like "Ethernet*" -and $_.AddressFamily -like "IPv4"}).InterfaceIndex
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
                            Get-Job -Name NewSrvSetup `
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