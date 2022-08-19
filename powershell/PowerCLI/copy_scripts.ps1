$NomVM = Read-Host("Entrez le nom de la VM")
$FiltreVM = "*" + $NomVM + "*"

Write-Host "Entrez ici les logins de la VM"

$userID = Read-Host("Entrez le nom d'utilisateur du domaine")
$GuestCrendials = Get-Credential $userID -Message "Please Enter your Domain account password."
#$DomainAccountPWD = ($GuestCrendials).GetNetworkCredential().Password
$server = Read-Host("Entrez le FQDN du serveur ESXI")
#Write-Host "Entrez ici les logins du serveur ESXI"
Connect-VIServer -Server $server


$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}

Copy-VMGuestFile -Source "C:\Users\alexi\OneDrive\Documents\DOCUMENTS\PRO\Scripts\Scripts Powershell\lab_deployment" -Destination "c:\lab_deployment" -VM $vm -LocalToGuest -GuestCredential $GuestCrendials -Force
#Invoke-VMScript -vm $vm -ScriptText $script -GuestCredential $DomainAccountPWD