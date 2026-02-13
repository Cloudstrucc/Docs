# Script: 03-Verify-Environment-Copilot-Settings.ps1
# Purpose: Verify Copilot settings for all Power Platform environments
# Version: 1.1
# Date: 2026-02-09

#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     POWER PLATFORM ENVIRONMENT VERIFICATION                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Connecting to Power Platform..." -ForegroundColor Yellow
Add-PowerAppsAccount

Write-Host "`nRetrieving all environments..." -ForegroundColor Yellow
$environments = Get-AdminPowerAppEnvironment

Write-Host "✓ Found $($environments.Count) environments" -ForegroundColor Green

$results = @()

Write-Host "`n=== VERIFYING ENVIRONMENT COPILOT SETTINGS ===" -ForegroundColor Cyan

foreach ($env in $environments) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "Environment: $($env.DisplayName)" -ForegroundColor Yellow
    Write-Host "Environment ID: $($env.EnvironmentName)" -ForegroundColor Gray
    Write-Host "Type: $($env.EnvironmentType)" -ForegroundColor Gray
    Write-Host "Region: $($env.Location)" -ForegroundColor Gray
    
    $envSettingsURL = "https://admin.powerplatform.microsoft.com/environments/$($env.EnvironmentName)/settings"
    
    $result = [PSCustomObject]@{
        EnvironmentName = $env.DisplayName
        EnvironmentId = $env.EnvironmentName
        EnvironmentType = $env.EnvironmentType
        Region = $env.Location
        SettingsURL = $envSettingsURL
        CopilotStatus = "Manual Verification Required"
        VerificationMethod = "Web UI - Settings → Features"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        VerifiedBy = ""
        Notes = "Verify Copilot is OFF in environment Features settings"
    }
    
    Write-Host "Settings URL: $envSettingsURL" -ForegroundColor Cyan
    Write-Host "⚠️  Manual verification required" -ForegroundColor Yellow
    
    $results += $result
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\EnvironmentCopilotVerification_$timestamp.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n✓ Verification report exported to: $exportPath" -ForegroundColor Green

$manualGuide = @"

╔════════════════════════════════════════════════════════════╗
║         MANUAL ENVIRONMENT VERIFICATION GUIDE              ║
╚════════════════════════════════════════════════════════════╝

For each environment, perform the following steps:

1. Navigate to the Settings URL provided
2. Click on 'Features' tab
3. Verify the following are DISABLED:
   • Copilot
   • Generative AI features
   • AI Builder (if not required)
4. If any are ENABLED, disable them and click Save
5. Capture screenshot showing disabled state
6. Update the verification CSV with 'Verified' status

ENVIRONMENTS REQUIRING VERIFICATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@

foreach ($result in $results) {
    $manualGuide += @"

Environment: $($result.EnvironmentName)
Type: $($result.EnvironmentType)
URL: $($result.SettingsURL)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@
}

$manualGuide += @"

VERIFICATION CHECKLIST:
☐ All environments verified
☐ All screenshots captured
☐ CSV updated with verification status
☐ Screenshots stored in documentation folder

"@

Write-Host $manualGuide -ForegroundColor Yellow

$guidePath = ".\EnvironmentVerificationGuide_$timestamp.txt"
$manualGuide | Out-File -FilePath $guidePath
Write-Host "`n✓ Manual verification guide saved to: $guidePath" -ForegroundColor Green

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   VERIFICATION SUMMARY                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`nTotal Environments: $($environments.Count)" -ForegroundColor White
Write-Host "Require Manual Verification: $($results.Count)" -ForegroundColor Yellow

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Review verification guide: $guidePath" -ForegroundColor Gray
Write-Host "2. Manually verify each environment using Settings URLs" -ForegroundColor Gray
Write-Host "3. Update CSV with verification status" -ForegroundColor Gray
Write-Host "4. Capture and store screenshots" -ForegroundColor Gray
Write-Host "5. Run 04-Disable-Copilot-ServicePrincipals.ps1" -ForegroundColor Gray

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
