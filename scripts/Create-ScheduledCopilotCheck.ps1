# Script: Create-ScheduledCopilotCheck.ps1
# Purpose: Create scheduled task for monthly Copilot compliance checks
# Version: 1.1
# Date: 2026-02-09

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     SCHEDULED TASK CREATION - MONTHLY COMPLIANCE           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$taskName = "Monthly Copilot Compliance Check"
$scriptPath = "C:\Scripts\Copilot-Disable\99-Verify-Copilot-Disabled.ps1"
$logPath = "C:\Logs\CopilotCompliance"

Write-Host "Task Configuration:" -ForegroundColor Cyan
Write-Host "  Name: $taskName" -ForegroundColor White
Write-Host "  Script: $scriptPath" -ForegroundColor White
Write-Host "  Logs: $logPath" -ForegroundColor White
Write-Host "  Schedule: 1st of each month at 6:00 AM" -ForegroundColor White

# Verify script path
Write-Host "`nVerifying script path..." -ForegroundColor Yellow
$currentLocation = Read-Host "Enter the full path to 99-Verify-Copilot-Disabled.ps1"
if (-not (Test-Path $currentLocation)) {
    Write-Host "`n✗ Script not found at: $currentLocation" -ForegroundColor Red
    Write-Host "Please ensure the script exists and try again" -ForegroundColor Yellow
    exit 1
}

$scriptPath = $currentLocation

# Create log directory if it doesn't exist
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    Write-Host "✓ Created log directory: $logPath" -ForegroundColor Green
}

# Create scheduled task action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -ExportReport | Out-File -FilePath `"$logPath\LastRun_`$(Get-Date -Format 'yyyyMMdd').log`""

# Create trigger (1st of each month at 6 AM)
$trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 6am

# Create principal (run as SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

# Create settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

# Register scheduled task
try {
    Write-Host "`nRegistering scheduled task..." -ForegroundColor Yellow
    
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "Monthly compliance check for Copilot disable status"
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          SCHEDULED TASK CREATED SUCCESSFULLY               ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nTask Details:" -ForegroundColor Cyan
    Write-Host "  Name: $taskName" -ForegroundColor White
    Write-Host "  Schedule: 1st of each month at 6:00 AM" -ForegroundColor White
    Write-Host "  Script: $scriptPath" -ForegroundColor White
    Write-Host "  Logs: $logPath" -ForegroundColor White
    Write-Host "  Next Run: 1st of next month" -ForegroundColor White
    
    Write-Host "`n📋 VERIFICATION:" -ForegroundColor Cyan
    Write-Host "View task in Task Scheduler: taskschd.msc" -ForegroundColor Gray
    Write-Host "Task location: Task Scheduler Library" -ForegroundColor Gray
    
    Write-Host "`n📋 TESTING:" -ForegroundColor Cyan
    Write-Host "To test immediately, run:" -ForegroundColor Gray
    Write-Host "  Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
    
}
catch {
    Write-Host "`n✗ Error creating scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease ensure you are running PowerShell as Administrator" -ForegroundColor Yellow
}

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
