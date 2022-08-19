# Add domain controller to existing domain
$esxi = Read-Host("Enter IP address of ESXI server")
$NomVM = Read-Host("Enter the name of the VM")
$domainName = Read-Host("Enter the domain name")
$domainUser = Read-Host("Enter the username (AD\user for exemple")
$SecurePassword = Read-Host "Enter DSRM password" -AsSecureString

Connect-VIServer $esxi
$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
Write-Host "Entrez les logins de la VM"
$cred = Get-Credential Administrateur
$userID = $domainUser
$domain = $domainName
Write-Host "Enter domain account password"
$DomainAccountPWD = (Get-Credential $userID -Message "Please Enter your Domain account password.").GetNetworkCredential().Password
 
$cmd = @"
`$domain = "$domain"
`$password = "$DomainAccountPWD" | ConvertTo-SecureString -asPlainText -force;
`$username = "$userID";
`$credential = New-Object System.Management.Automation.PSCredential(`$username, `$password);
`$SecurePassword = $SecurePassword
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment
Install-ADDSDomainController -InstallDns -SafeModeAdministratorPassword `$DSRM -Credential `$credential -DomainName `$domain
"@
 
Invoke-VMScript -VM $vm -ScriptText $cmd -Verbose -GuestCredential $cred