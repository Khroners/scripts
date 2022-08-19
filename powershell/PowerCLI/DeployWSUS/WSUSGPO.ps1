# GPO for WSUS

$wsusFQDN = Read-Host("Entrez le fqdn du serveur wsus")
New-GPO -Name "RN-FP-O-WsusLocation"
Set-GPRegistryValue -Name "RN-FP-O-WsusLocation" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "UseWUServer" -Value 1 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WsusLocation" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "WUServer" -Value "http://$wsusFQDN`:8530" -Type String
Set-GPRegistryValue -Name "RN-FP-O-WsusLocation" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "WUStatusServer" -Value "http://$wsusFQDN`:8530" -Type String

# Detection frequency, Configure automatic updates, Download Mode

New-GPO -Name "RN-FP-O-WUWorkstations"
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -ValueName "DODownloadMode" -Value 1 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "DetectionFrequencyEnabled" -Value 1 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "DetectionFrequency" -Value 4 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "NoAutoUpdate" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AUOptions" -Value 4 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AutomaticMaintenanceEnabled" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallDay" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallTime" -Value 12 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AllowMUUpdateService" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallEveryWeek" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallFirstWeek" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallSecondWeek" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallThirdWeek" -Value 0 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "ScheduledInstallFourthWeek" -Value 0 -Type DWord

# Targeting

Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "TargetGroupEnabled" -Value 1 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "TargetGroup" -Value "RN-Workstations" -Type String

# Specify deadlines for automatic updates and restarts

Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "SetComplianceDeadline" -Value 1 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ConfigureDeadlineForQualityUpdates" -Value 3 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ConfigureDeadlineForFeatureUpdates" -Value 7 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ConfigureDeadlineGracePeriod" -Value 2 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ConfigureDeadlineGracePeriodForFeatureUpdates" -Value 2 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ConfigureDeadlineNoAutoReboot" -Value 0 -Type DWord

# Display options for update notifications / Options d'affichage des notifications de mise à jour

Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "SetUpdateNotificationLevel" -Value 1 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "UpdateNotificationLevel" -Value 1 -Type DWord

# Active Hours

Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "SetActiveHours" -Value 1 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ActiveHoursStart" -Value 8 -Type DWord
Set-GPRegistryValue -Name "RN-FP-O-WUWorkstations" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ActiveHoursEnd" -Value 18 -Type DWord


