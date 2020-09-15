Import-Module 'C:\Program Files\Microsoft Dynamics 365 Business Central\150\Service\NavAdminTool.ps1'

$ServerInstance = "BC150"
$VersionAppOld  = "4.0.0.0"
$VersionApp     = "4.0.0.1"


Write-Host "16. Upgrade Extension and Uninstall Old Version of App."
# Publish New Version of App.
Publish-NAVApp -ServerInstance $ServerInstance -Path "C:\Users\Marco Bagatelli\Documents\AL\BC14toBC15\Growing Together_BC14toBC15_$VersionApp.app" -SkipVerification

# Sync New Version of App.
Sync-NAVApp -ServerInstance $ServerInstance -Name "BC14toBC15" -Version $VersionApp #Add <ForceSync> if table remove erros appear

# Start NAV Data Upgrade of App.
Start-NAVAppDataUpgrade -ServerInstance $ServerInstance -Name "BC14toBC15" -Version $VersionApp

# Unpublish Old Version of App.
Unpublish-NAVApp -ServerInstance $ServerInstance -Name "BC14toBC15" -Version $VersionAppOld
