param(
    [Parameter (Mandatory = $true)]
    [string]$DomainName,
    [string]$MdpAD,
    [string]$SecurePwd
)

Import-Module ADDSDeployment
$SecurePassword = $SecurePwd | ConvertTo-SecureString -AsPlainText -Force
$MotdepasseAD = $MdpAD | ConvertTo-SecureString -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ("AD\Administrateur", $MotdepasseAD)
Install-ADDSDomainController -InstallDns -SafeModeAdministratorPassword $SecurePassword -Credential $Cred -DomainName $DomainName