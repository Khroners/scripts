param(
    [Parameter (Mandatory = $true)]
    [string]$DomainName,
    [string]$DefaultSite,
    [string]$SecurePwd,
    [string]$ServerName
)

Import-Module ADDSDeployment
Install-ADDSForest -DomainName $DomainName -SafeModeAdministratorPassword $SecurePassword -InstallDns -DomainMode WinThreshold -ForestMode WinThreshold -Force
