# Deploiement de WSUS par PowerShell et PowerCLI

Ces deux scripts permettent de déployer WSUS via un script PowerShell sur une VM Windows Server en français présente sur un ESXI.

# Prérequis

- PowerCLI sur votre machine
- VM installée sur un ESXI
- VMware Tools d'installés
- Compte Administrateur de la VM
- Compte sur l'ESXI avec les permissions de l'API

# Usage
```ps1
./DeployWSUS.ps1
```
# Notes
- Le script utilise le lecteur E: pour WSUS
- Il reste nécessaire de manuellement sélectionner les produits (les classifications sont choisies automatiquement via le script)
- La fréquence de synchronisation est fixée à 00h00, toutes les 24H.
