param(
    [Parameter (Mandatory = $true)]
    [string]$SousDom,
    [string]$Dom,
    [string]$EXT
)
$Sites = ("RENNES","VANNES","BREST","SAINT-BRIEUC")
$Bases = ("Groups","Users","Workstations","Servers","Printers")
$Services = ("Production","Marketing","IT","Direction","Helpdesk")
$FirstOU = "Sites"

New-ADOrganizationalUnit -Name $FirstOU -Description $FirstOU -Path "DC=$SousDom,DC=$Dom,DC=$EXT"

# Inclure ici les services OU dans workstations
foreach ($S in $Sites)
{
        New-ADOrganizationalUnit -Name $S -Description "$S" -Path "OU=$FirstOU,DC=$SousDom,DC=$Dom,DC=$EXT"

    foreach ($Base in $Bases)
    {
        New-ADOrganizationalUnit -Name $Base -Description "$Base" -Path "OU=$S,OU=$FirstOU,DC=$SousDom,DC=$Dom,DC=$EXT"

        foreach ($Serv in $Services)
        {
            New-ADOrganizationalUnit -Name $Serv -Description "$S $Serv" -Path "OU=Users,OU=$S,OU=$FirstOU,DC=$SousDom,DC=$Dom,DC=$EXT"
        }
    }
}