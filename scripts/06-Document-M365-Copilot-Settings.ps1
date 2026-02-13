# Script: 06-Document-M365-Copilot-Settings.ps1
# Purpose: Document M365 Copilot configuration
# Version: 1.1
# Date: 2026-02-09

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     M365 COPILOT CONFIGURATION DOCUMENTATION               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "🔗 M365 Admin Center URL:" -ForegroundColor Cyan
Write-Host "   https://admin.microsoft.com/Adminportal/Home#/Settings/Services" -ForegroundColor White

Write-Host "`n📋 REQUIRED CONFIGURATION:" -ForegroundColor Cyan
Write-Host "1. Navigate to Settings → Org settings → Services" -ForegroundColor Gray
Write-Host "2. Select 'Microsoft 365 Copilot' (if present)" -ForegroundColor Gray
Write-Host "3. Disable ALL settings:" -ForegroundColor Gray
Write-Host "   • Allow users to access Microsoft Copilot → OFF" -ForegroundColor Gray
Write-Host "   • Allow Copilot to access web content → OFF" -ForegroundColor Gray
Write-Host "   • Allow Copilot in Microsoft 365 apps → OFF" -ForegroundColor Gray
Write-Host "4. Click Save" -ForegroundColor Gray

Write-Host "`n📋 LICENSE MANAGEMENT:" -ForegroundColor Cyan
Write-Host "1. Navigate to Billing → Licenses" -ForegroundColor Gray
Write-Host "2. Search for 'Copilot' licenses" -ForegroundColor Gray
Write-Host "3. Remove ALL user assignments" -ForegroundColor Gray
Write-Host "4. Document license counts" -ForegroundColor Gray

Write-Host "`n📸 REQUIRED SCREENSHOTS:" -ForegroundColor Cyan
Write-Host "1. Copilot settings (before)" -ForegroundColor Gray
Write-Host "2. Copilot settings (after - all OFF)" -ForegroundColor Gray
Write-Host "3. License status (showing 0 assignments)" -ForegroundColor Gray

$completed = Read-Host "`nHave you completed all the above steps? (Y/N)"

if ($completed -ne "Y" -and $completed -ne "y") {
    Write-Host "`n⚠️  Configuration not completed. Exiting..." -ForegroundColor Yellow
    exit 0
}

$m365CopilotConfig = [PSCustomObject]@{
    ConfigurationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ConfiguredBy = $env:USERNAME
    CopilotAccess = "Disabled"
    WebContentAccess = "Disabled"
    M365AppsIntegration = "Disabled"
    LicensesAssigned = Read-Host "Enter number of Copilot licenses currently assigned (should be 0)"
    LicensesAvailable = Read-Host "Enter total Copilot licenses available"
    LicensesRemoved = Read-Host "Enter number of license assignments removed"
    ConfigurationMethod = "Manual via M365 Admin Center"
    ConfigurationURL = "https://admin.microsoft.com/Adminportal/Home#/Settings/Services"
    ScreenshotsCaptured = "Before, After, License Status"
    Notes = "All M365 Copilot features disabled"
    ChangeTicket = Read-Host "Enter Change Control Ticket Number (optional)"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\M365_Copilot_Config_$timestamp.csv"
$m365CopilotConfig | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "`n✓ M365 Copilot configuration documented: $exportPath" -ForegroundColor Green

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          CONFIGURATION SUMMARY                             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

$m365CopilotConfig | Format-List

Write-Host "`n✓ M365 Copilot disabled" -ForegroundColor Green
Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
