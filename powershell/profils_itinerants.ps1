$OUpath = 'ou=Users,ou=Accounts,ou=Littoral1,dc=littoral1,dc=fr'
$Users = Get-ADUser -Filter 'enabled -eq $true' -SearchBase $OUpath -Properties ProfilePath | Select-Object Name, SamAccountName, ProfilePath

Foreach($User in $Users){
    $ProfilePath = "\\CPD01\Profils_itinerants$\"
    $Profilepath = $ProfilePath + $User.samaccountname
    $HomeDirectory = "\\CPD01\Utilisateurs$\"
    $Homedirectory = $HomeDirectory + $User.samaccountname
    Set-ADUser $User.samaccountname -ProfilePath $ProfilePath -HomeDirectory $HomeDirectory -HomeDrive U    
}
