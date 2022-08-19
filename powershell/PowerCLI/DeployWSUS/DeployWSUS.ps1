# Install WSUS & configuration & Report Viewer install

$Site = Read-Host("Entrez le site AD du WSUS (RENNES par exemple)")
$NomVM = Read-Host("Entrez le nom de la VM")
Write-Host "Entrez ici les logins de la VM"
$userID = Read-Host("Entrez le nom d'utilisateur du domaine")
$GuestCrendials = Get-Credential $userID -Message "Please Enter your Domain account password."

$server = Read-Host("Entrez le FQDN du serveur ESXI")
Write-Host "Entrez ici les logins du serveur ESXI"
Connect-VIServer -Server $server

$script = @"
    Install-WindowsFeature -Name UpdateServices -IncludeManagementTools
    New-Item -Path C: -Name temp -ItemType Directory
    New-Item -Path E: -Name WSUS -ItemType Directory
    & "C:\temp\CLR_RV.ps1
    & "C:\Program Files\Update Services\Tools\wsusutil.exe" postinstall CONTENT_DIR=E:\WSUS
    `$wsus = Get-WSUSServer
    `$wsusConfig = `$wsus.GetConfiguration()
    Set-WsusServerSynchronization -SyncFromMU
    `$wsusConfig.AllUpdateLanguagesEnabled = `$false           
    `$wsusConfig.SetEnabledUpdateLanguages("fr")
    `$wsusConfig.TargetingMode = "Client"         
    `$wsusConfig.Save()
    `$subscription = `$wsus.GetSubscription()
    `$subscription.StartSynchronizationForCategoryOnly()
    While (`$subscription.GetSynchronizationStatus() -ne "NotProcessing") {

        Write-Host "." -NoNewline

        Start-Sleep -Seconds 5

    }
    Write-Host "La synchronisation est terminé."

    # Configure the Platforms that we want WSUS to receive updates
    Write-Host "Il faut encore selectionner manuellement les produits. Les classifications sont déjà sélectionnées."
    
    #Configure the Classifications
    
    Get-WsusClassification | Where-Object {
        `$_.Classification.Title -in (
        "Applications",
        "Ensemble de mises à jour",
        "Feature Pack",
        "Mise à jour",
        "Mise à jour de la sécurité",
        "Mise à jour critique",
        "Mises à jour de définitions",
        "Outil",
        "Service Pack",
        "Upgrades")
    } | Set-WsusClassification
    
    # Create Computer Target Groups 
    # Inclure ici une boucle qui va parcourir la variable SITE (avec split virgule et array)
    `$wsus.CreateComputerTargetGroup("$Site")
    `$group = `$wsus.GetComputerTargetGroups() | Where {`$_.Name -eq "$Site"}
    `$wsus.CreateComputerTargetGroup("Servers",`$group)
    `$wsus.CreateComputerTargetGroup("Direction",`$group)
    `$wsus.CreateComputerTargetGroup("Helpdesk",`$group)
    `$wsus.CreateComputerTargetGroup("IT",`$group)
    `$wsus.CreateComputerTargetGroup("Marketing",`$group)
    `$wsus.CreateComputerTargetGroup("Production",`$group)
    
    #Configure Synchronizations
    
    `$subscription.SynchronizeAutomatically=`$true
    
    #Set synchronization scheduled for midnight each night
    
    `$subscription.SynchronizeAutomaticallyTimeOfDay= (New-TimeSpan -Hours 0)
    
    `$subscription.NumberOfSynchronizationsPerDay=1
    
    `$subscription.Save()

    #Kick off a synchronization
    
    `$subscription.StartSynchronization()
"@

$FiltreVM = "*" + $NomVM + "*"
$vm = Get-VM | Where-Object {$_.Name -like $FiltreVM}
$secondscript = $PSScriptRoot + "\" + "CLR_RV.ps1"
Copy-VMGuestFile -vm $vm -Source $secondscript -Destination "c:\temp\CRL_RV.ps1" -LocalToGuest -GuestCredential $GuestCrendials -Force
Invoke-VMScript -vm $vm -ScriptText $script -GuestCredential $GuestCrendials -ScriptType PowerShell