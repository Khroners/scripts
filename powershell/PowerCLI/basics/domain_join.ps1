# Join Server to AD Domain

$NomVM = Read-Host("Entrez le nom de la VM")
$server = Read-Host("Entrez le FQDN du serveur ESXI")
Write-Host "Entrez ici les logins du serveur ESXI"
Connect-VIServer -Server $server

$Domaine = Read-Host("Entrez le domaine")
$userID = Read-Host("Entrez le nom d'utilisateur du domaine")
$DomainAccountPWD = (Get-Credential $userID -Message "Please Enter your Domain account password.").GetNetworkCredential().Password

$script = @"
    `$domain = "$Domaine"
    `$username = "$userID"
    `$password = "$DomainAccountPWD" | ConvertTo-SecureString -asPlainText -force;
    `$credential = New-Object System.Management.Automation.PSCredential(`$username, `$password)
    Add-Computer -DomainName $Domaine -Credential `$credential -Restart
"@

$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
Write-Host "Entrez ici les logins de la VM"
$GuestCrendials = Get-Credential
Invoke-VMScript -vm $vm -ScriptText $script -GuestCredential $GuestCrendials