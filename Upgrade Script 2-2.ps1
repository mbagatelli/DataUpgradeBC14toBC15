###################### Parameters ######################
$DatabaseServer       = "ARQ-MBG"
#$DatabaseInstance     = "BC150"
$DatabaseName         = "GTOGHERMIGRATEDBV14" 
$ServiceName          = "BC150"
$DeveloperLicenseFile = "C:\Temp\MSDynLicenses\5190281 - D365BC 150 DEV.flf"
$BC15Version          = "15.8.43801.0"
$BaseAppPath          = "C:\Temp\Dynamics.365.BC.43801.W1.DVD\applications\BaseApp\Source\Microsoft_Base Application.app"
$SystemAppPath        = "C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\150\AL Development Environment\System.app"
$MicrosoftSysPath     = "C:\Temp\Dynamics.365.BC.43801.W1.DVD\applications\system application\source\Microsoft_System Application.app"
$MicrosoftApplicPath  = "C:\Temp\Dynamics.365.BC.43801.W1.DVD\applications\Application\Source\Microsoft_Application.app"
$CustomAppPath        = "C:\Users\Marco Bagatelli\Documents\AL\BC14toBC15\Growing Together_BC14toBC15_3.0.0.10.app"
$CustomAppVersion     = "3.0.0.10"
$ServerInstance       = "BC150"

##################################################################

Write-Host "1. Importing BC15 Powershell Module"
Import-Module 'C:\Program Files\Microsoft Dynamics 365 Business Central\150\Service\NavAdminTool.ps1'

Write-Host "2. Executing Application Database Conversion"
Invoke-NAVApplicationDatabaseConversion -DatabaseName $DatabaseName -DatabaseServer $DatabaseServer -Force

Write-Host "3. Checking Service Status and Start if not started"
$ServiceStatus = Get-NAVServerInstance -ServerInstance $ServerInstance

If ($ServiceStatus.State -eq "Stopped")
{
    Start-NAVServerInstance -ServerInstance $ServerInstance
}

Write-Host "4. Setting Service Parameters & Load License"
Set-NAVServerConfiguration -ServerInstance $ServerInstance -KeyName DatabaseServer -KeyValue $DatabaseServer
Set-NAVServerConfiguration -ServerInstance $ServerInstance -KeyName DatabaseInstance -KeyValue $DatabaseInstance
Set-NAVServerConfiguration -ServerInstance $ServerInstance -KeyName DatabaseName -KeyValue $DatabaseName
Set-NavServerConfiguration -ServerInstance $ServerInstance -KeyName "EnableTaskScheduler" -KeyValue false
Import-NAVServerLicense  -ServerInstance $ServerInstance -LicenseFile $DeveloperLicenseFile

Write-Host "5. Restarting NAV Service"
ReStart-NAVServerInstance -ServerInstance $ServerInstance

Write-Host "6. Publishing System App Symbols"
Publish-NAVApp -ServerInstance $ServerInstance -Path "C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\150\AL Development Environment\System.app" -PackageType SymbolsOnly

Write-Host "7. Extensions Migration"
Set-NAVServerConfiguration -ServerInstance $ServerInstance -KeyName "DestinationAppsForMigration" -KeyValue '[{"appId":"63ca2fa4-4f03-4f2b-a480-172fef340d3f", "name":"System Application", "publisher": "Microsoft"}, {"appId":"437dbf0e-84ff-417a-965d-ed2bb9650972", "name":"Base Application", "publisher": "Microsoft"}]'

Write-Host "8.Restart-NAVServerInstance -ServerInstance BC150"
Restart-NAVServerInstance -ServerInstance $ServerInstance

Write-Host "9. Application Build Increase"
Set-NAVApplication -ServerInstance $ServerInstance -ApplicationVersion $BC15Version -Force

Write-Host "10. Publishing Symbols & Extensions"
Publish-NAVApp -ServerInstance $ServerInstance -Path $SystemAppPath -PackageType SymbolsOnly
Publish-NAVApp -ServerInstance $ServerInstance -Path $MicrosoftSysPath
Publish-NAVApp -ServerInstance $ServerInstance -Path $BaseAppPath -SkipVerification
Publish-NAVApp -ServerInstance $ServerInstance -Path $MicrosoftApplicPath
Publish-NAVApp -ServerInstance $ServerInstance -Path $CustomAppPath –SkipVerification
Restart-NAVServerInstance -ServerInstance $ServerInstance

Write-Host "11. Sync"
Sync-NAVTenant -ServerInstance $ServerInstance  -Mode Sync -Force

Write-Host "12. Sync Apps"
Sync-NAVApp -ServerInstance $ServerInstance -Name "System Application" -Version $BC15Version 
Sync-NAVApp -ServerInstance $ServerInstance -Name "Base Application" -Version $BC15Version 
Sync-NAVApp -ServerInstance $ServerInstance -Name "Application" -Version $BC15Version 
Sync-NAVApp -ServerInstance $ServerInstance -Name "BC14toBC15" -Version $CustomAppVersion

Write-Host "13. Upgrade Data"
Start-NAVDataUpgrade -ServerInstance $ServerInstance -FunctionExecutionMode Serial -Force

## It will stop here, need to wait 3-5m for the data process to finish
Write-Host "Pausing for 4minutes"
Start-Sleep -Seconds 240

Write-Host "14. Install 3rd party"
Install-NAVApp -ServerInstance $ServerInstance -Name "BC14toBC15" -Version $CustomAppVersion

Write-Host "15. Enable task scheduler"
Set-NavServerConfiguration -ServerInstance $ServerInstance -KeyName "EnableTaskScheduler" -KeyValue true

Write-Host "16. Restart instance"
Restart-NAVServerInstance -ServerInstance $ServerInstance






