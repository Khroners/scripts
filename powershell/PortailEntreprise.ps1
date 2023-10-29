$Desktop = "$env:USERPROFILE\OneDrive - MSFT\Bureau"
$ShortcutName = "Portail d'entreprise"
$shortcutFile = "$Desktop\$ShortcutName.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutFile)
$shortcut.TargetPath = "shell:AppsFolder\Microsoft.CompanyPortal_8wekyb3d8bbwe!App"
$shortcut.Save()
