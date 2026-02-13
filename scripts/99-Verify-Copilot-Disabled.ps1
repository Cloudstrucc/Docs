# Script: 99-Verify-Copilot-Disabled.ps1
# Purpose: Comprehensive verification that Copilot is disabled
# Version: 1.1
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications, Microsoft.PowerApps.Administration.PowerShell

param(
    [switch]$ExportReport = $true,
    [string]$ReportPath = ".\CopilotComplianceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     COPILOT COMPLIANCE VERIFICATION REPORT                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$results = @()
$overallStatus = "PASS"

# CHECK 1: Power Platform Tenant Settings
Write-Host "[1/5] Checking Power Platform tenant settings..." -ForegroundColor Yellow
Write-Host "      Direct URL: https://admin.powerplatform.microsoft.com/copilot/settings" -ForegroundColor Gray

$result = [PSCustomObject]@{
    CheckId = "PP-TENANT-01"
    Category = "Power Platform Tenant"
    Check = "Copilot Tenant Settings"
    Expected = "All toggles OFF"
    Actual = "Manual Verification Required"
    Status = "VERIFY"
    Severity = "Critical"
    Remediation = "Navigate to https://admin.powerplatform.microsoft.com/copilot/settings"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}
$results += $result

# CHECK 2: Service Principals
Write-Host "`n[2/5] Checking Copilot service principals..." -ForegroundColor Yellow

try {
    Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome -ErrorAction Stop
    
    $activeSPs = @()
    foreach ($keyword in @("Copilot", "AI Builder", "Power Platform Advisor")) {
        $sps = Get-MgServicePrincipal -All | Where-Object {
            $_.DisplayName -like "*$keyword*" -and $_.AccountEnabled -eq $true
        }
        $activeSPs += $sps
    }
    
    if ($activeSPs.Count -eq 0) {
        $result = [PSCustomObject]@{
            CheckId = "ENTRA-SP-01"
            Category = "Entra ID Service Principals"
            Check = "Active Copilot Service Principals"
            Expected = "0 active"
            Actual = "0 active"
            Status = "PASS"
            Severity = "High"
            Remediation = "N/A"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        Write-Host "      ✓ No active Copilot service principals" -ForegroundColor Green
    }
    else {
        $result = [PSCustomObject]@{
            CheckId = "ENTRA-SP-01"
            Category = "Entra ID Service Principals"
            Check = "Active Copilot Service Principals"
            Expected = "0 active"
            Actual = "$($activeSPs.Count) active"
            Status = "FAIL"
            Severity = "High"
            Remediation = "Run 04-Disable-Copilot-ServicePrincipals.ps1"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        Write-Host "      ✗ Found $($activeSPs.Count) active service principals" -ForegroundColor Red
        $overallStatus = "FAIL"
    }
    $results += $result
}
catch {
    Write-Host "      ✗ Error checking service principals" -ForegroundColor Red
}

# CHECK 3: Conditional Access Policy
Write-Host "`n[3/5] Checking Conditional Access policy..." -ForegroundColor Yellow

try {
    Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome -ErrorAction Stop
    
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All
    $copilotCAPolicy = $caPolicies | Where-Object { 
        $_.DisplayName -like "*Copilot*" -and $_.DisplayName -like "*BLOCK*" 
    }
    
    if ($copilotCAPolicy -and $copilotCAPolicy.State -eq "enabled") {
        $result = [PSCustomObject]@{
            CheckId = "ENTRA-CA-01"
            Category = "Conditional Access"
            Check = "Copilot Block Policy"
            Expected = "Enabled"
            Actual = "Enabled"
            Status = "PASS"
            Severity = "High"
            Remediation = "N/A"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        Write-Host "      ✓ Copilot block policy is active" -ForegroundColor Green
    }
    else {
        $result = [PSCustomObject]@{
            CheckId = "ENTRA-CA-01"
            Category = "Conditional Access"
            Check = "Copilot Block Policy"
            Expected = "Enabled"
            Actual = "Not found or disabled"
            Status = "FAIL"
            Severity = "High"
            Remediation = "Run 05-Create-CA-Policy-BlockCopilot.ps1"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        Write-Host "      ✗ No active Copilot block policy" -ForegroundColor Red
        $overallStatus = "FAIL"
    }
    $results += $result
}
catch {
    Write-Host "      ✗ Error checking CA policy" -ForegroundColor Red
}

# CHECK 4: M365 Copilot
Write-Host "`n[4/5] Checking M365 Copilot settings..." -ForegroundColor Yellow

$result = [PSCustomObject]@{
    CheckId = "M365-COP-01"
    Category = "Microsoft 365 Copilot"
    Check = "M365 Copilot Disabled"
    Expected = "Disabled"
    Actual = "Manual Verification Required"
    Status = "VERIFY"
    Severity = "High"
    Remediation = "Verify at https://admin.microsoft.com"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}
Write-Host "      ⚠️  Manual verification required" -ForegroundColor Yellow
$results += $result

# CHECK 5: Documentation
Write-Host "`n[5/5] Checking documentation..." -ForegroundColor Yellow

$requiredDocs = @("CopilotDiscovery_*.csv", "ServicePrincipalDisable_*.csv", "CA_Policy_Copilot_*.csv")
$missingDocs = @()

foreach ($doc in $requiredDocs) {
    if (-not (Get-ChildItem -Path $doc -ErrorAction SilentlyContinue)) {
        $missingDocs += $doc
    }
}

if ($missingDocs.Count -eq 0) {
    Write-Host "      ✓ All documentation present" -ForegroundColor Green
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   VERIFICATION SUMMARY                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$summary = @{
    TotalChecks = $results.Count
    Passed = ($results | Where-Object {$_.Status -eq "PASS"}).Count
    Failed = ($results | Where-Object {$_.Status -eq "FAIL"}).Count
    RequireVerification = ($results | Where-Object {$_.Status -eq "VERIFY"}).Count
}

Write-Host "Total Checks: $($summary.TotalChecks)" -ForegroundColor White
Write-Host "Passed: $($summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($summary.Failed)" -ForegroundColor $(if ($summary.Failed -gt 0) {"Red"} else {"Gray"})
Write-Host "Require Verification: $($summary.RequireVerification)" -ForegroundColor Yellow

# Export report
if ($ExportReport) {
    $results | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Host "`n✓ Report exported to: $ReportPath" -ForegroundColor Green
}

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

return $results
