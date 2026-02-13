# Script: 02-Disable-PowerPlatform-Copilot-Tenant.ps1
# Purpose: Document Copilot tenant-level configuration
# Version: 1.1
# Date: 2026-02-09

#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     POWER PLATFORM COPILOT TENANT CONFIGURATION            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Connecting to Power Platform..." -ForegroundColor Yellow
Add-PowerAppsAccount

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║              MANUAL CONFIGURATION REQUIRED                 ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red

Write-Host "`n🔗 DIRECT CONFIGURATION URL:" -ForegroundColor Cyan
Write-Host "   https://admin.powerplatform.microsoft.com/copilot/settings" -ForegroundColor White

Write-Host "`n⚠️  CRITICAL SETTINGS TO DISABLE:" -ForegroundColor Yellow
$settingsToDisable = @(
    "1. Copilot (main toggle at top) → OFF",
    "2. Copilot in Power Apps → OFF",
    "3. Copilot in Power Automate → OFF",
    "4. Copilot in Power Pages → OFF",
    "5. Allow users to analyze data using AI chat → OFF",
    "6. Move data across regions → OFF ⚠️ CRITICAL",
    "7. Bing search → OFF (if present)",
    "8. Generative AI features → OFF (if present)"
)

foreach ($setting in $settingsToDisable) {
    Write-Host "   $setting" -ForegroundColor White
}

Write-Host "`n📸 REQUIRED SCREENSHOTS:" -ForegroundColor Cyan
Write-Host "   1. Before configuration (all settings visible)" -ForegroundColor Gray
Write-Host "   2. After configuration (all settings OFF)" -ForegroundColor Gray
Write-Host "   3. Save confirmation message" -ForegroundColor Gray

Write-Host "`n✅ CONFIGURATION CHECKLIST:" -ForegroundColor Cyan
$checklist = @(
    "Navigate to direct URL",
    "Capture 'Before' screenshot",
    "Disable all 8 settings listed above",
    "Click SAVE button",
    "Confirm save operation",
    "Capture 'After' screenshot",
    "Capture 'Confirmation' screenshot",
    "Store screenshots in documentation folder"
)

foreach ($item in $checklist) {
    Write-Host "   ☐ $item" -ForegroundColor Gray
}

Write-Host "`n" -NoNewline
$completed = Read-Host "Have you completed all the above steps? (Y/N)"

if ($completed -ne "Y" -and $completed -ne "y") {
    Write-Host "`n⚠️  Configuration not completed. Exiting..." -ForegroundColor Yellow
    Write-Host "Re-run this script after completing the manual steps." -ForegroundColor Gray
    exit 0
}

Write-Host "`nDocumenting configuration..." -ForegroundColor Yellow

$tenantConfig = [PSCustomObject]@{
    ConfiguredBy = $env:USERNAME
    ConfiguredDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ConfigurationURL = "https://admin.powerplatform.microsoft.com/copilot/settings"
    Setting = "Power Platform Tenant - All Copilot Features Disabled"
    Method = "Manual via Direct Copilot Settings URL"
    Status = "Completed"
    CopilotMainToggle = "OFF"
    CopilotPowerApps = "OFF"
    CopilotPowerAutomate = "OFF"
    CopilotPowerPages = "OFF"
    AIDataAnalysis = "OFF"
    MoveDataAcrossRegions = "OFF - CRITICAL for data residency"
    BingSearch = "OFF"
    GenerativeAI = "OFF"
    ScreenshotsCaptured = "Before, After, Confirmation"
    ChangeTicket = Read-Host "`nEnter Change Control Ticket Number (optional)"
    ApprovedBy = Read-Host "Enter Approver Name (optional)"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\TenantCopilotConfig_$timestamp.csv"
$tenantConfig | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n✓ Configuration documented: $exportPath" -ForegroundColor Green

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              CONFIGURATION SUMMARY                         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

$tenantConfig | Format-List

Write-Host "`n✓ Tenant-level Copilot configuration completed" -ForegroundColor Green
Write-Host "`n⏱️  PROPAGATION TIME:" -ForegroundColor Yellow
Write-Host "   • Most environments: 1-4 hours" -ForegroundColor Gray
Write-Host "   • All environments: Up to 24 hours" -ForegroundColor Gray
Write-Host "   • Verify in next step after propagation period" -ForegroundColor Gray

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "   1. Wait 24 hours for full propagation" -ForegroundColor Gray
Write-Host "   2. Run 03-Verify-Environment-Copilot-Settings.ps1" -ForegroundColor Gray
Write-Host "   3. Update your documentation" -ForegroundColor Gray

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
