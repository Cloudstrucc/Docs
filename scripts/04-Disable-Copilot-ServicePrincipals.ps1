# Script: 04-Disable-Copilot-ServicePrincipals.ps1
# Purpose: Disable Copilot service principals in Entra ID
# Version: 1.1
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     SERVICE PRINCIPAL DISABLE SCRIPT                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All"

# Load discovered apps from Phase 1
$discoveredAppsPath = Get-ChildItem -Path ".\CopilotDiscovery_*.csv" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($discoveredAppsPath) {
    Write-Host "✓ Loading discovered apps from: $($discoveredAppsPath.Name)" -ForegroundColor Green
    $copilotApps = Import-Csv -Path $discoveredAppsPath.FullName
}
else {
    Write-Host "⚠️  No discovery file found. Running discovery first..." -ForegroundColor Yellow
    & ".\01-Discover-CopilotApps.ps1"
    $discoveredAppsPath = Get-ChildItem -Path ".\CopilotDiscovery_*.csv" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    $copilotApps = Import-Csv -Path $discoveredAppsPath.FullName
}

# Filter for service principals
$servicePrincipals = $copilotApps | Where-Object { $_.Type -like "*ServicePrincipal*" }

if ($servicePrincipals.Count -eq 0) {
    Write-Host "`n✓ No Copilot service principals found to disable" -ForegroundColor Green
    Write-Host "This is the expected state for a clean tenant" -ForegroundColor Gray
    exit 0
}

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║     DISABLING COPILOT SERVICE PRINCIPALS                   ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Write-Host "`nFound $($servicePrincipals.Count) service principals to process" -ForegroundColor Cyan

$results = @()
$successCount = 0
$alreadyDisabledCount = 0
$microsoftManagedCount = 0
$failedCount = 0

foreach ($sp in $servicePrincipals) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "Processing: $($sp.DisplayName)" -ForegroundColor Yellow
    Write-Host "  App ID: $($sp.AppId)" -ForegroundColor Gray
    Write-Host "  Object ID: $($sp.ObjectId)" -ForegroundColor Gray
    Write-Host "  Current Status: $($sp.AccountEnabled)" -ForegroundColor Gray
    
    try {
        if ($sp.AccountEnabled -eq "True") {
            Update-MgServicePrincipal -ServicePrincipalId $sp.ObjectId -AccountEnabled:$false
            
            $result = [PSCustomObject]@{
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.ObjectId
                PreviousState = $sp.AccountEnabled
                NewState = "Disabled"
                Status = "Success"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ProcessedBy = $env:USERNAME
                ErrorMessage = ""
                Action = "Disabled via Graph API"
            }
            
            Write-Host "  ✓ Successfully disabled" -ForegroundColor Green
            $successCount++
        }
        elseif ($sp.AccountEnabled -eq "False") {
            $result = [PSCustomObject]@{
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.ObjectId
                PreviousState = $sp.AccountEnabled
                NewState = "Disabled"
                Status = "Already Disabled"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ProcessedBy = $env:USERNAME
                ErrorMessage = ""
                Action = "No action required"
            }
            
            Write-Host "  ○ Already disabled" -ForegroundColor Gray
            $alreadyDisabledCount++
        }
        else {
            $result = [PSCustomObject]@{
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.ObjectId
                PreviousState = $sp.AccountEnabled
                NewState = "Unknown"
                Status = "Skipped"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ProcessedBy = $env:USERNAME
                ErrorMessage = "AccountEnabled state is N/A or unknown"
                Action = "Skipped - state unknown"
            }
            
            Write-Host "  ⊘ Skipped (state unknown)" -ForegroundColor Yellow
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        
        if ($errorMsg -like "*insufficient privileges*" -or 
            $errorMsg -like "*Access Denied*" -or 
            $errorMsg -like "*Forbidden*" -or
            $errorMsg -like "*does not have permissions*") {
            
            $result = [PSCustomObject]@{
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.ObjectId
                PreviousState = $sp.AccountEnabled
                NewState = "Microsoft-Managed"
                Status = "Cannot Modify"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ProcessedBy = $env:USERNAME
                ErrorMessage = "Microsoft-managed application - cannot be disabled directly"
                Action = "Will be blocked by Conditional Access in next step"
            }
            
            Write-Host "  ⚠ Cannot disable (Microsoft-managed)" -ForegroundColor Yellow
            Write-Host "    This will be blocked by Conditional Access" -ForegroundColor Gray
            $microsoftManagedCount++
        }
        else {
            $result = [PSCustomObject]@{
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.ObjectId
                PreviousState = $sp.AccountEnabled
                NewState = "Error"
                Status = "Failed"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ProcessedBy = $env:USERNAME
                ErrorMessage = $errorMsg
                Action = "Manual intervention required"
            }
            
            Write-Host "  ✗ Error: $errorMsg" -ForegroundColor Red
            $failedCount++
        }
    }
    
    $results += $result
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\ServicePrincipalDisable_$timestamp.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n✓ Results exported to: $exportPath" -ForegroundColor Green

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  OPERATION SUMMARY                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`nTotal Processed: $($results.Count)" -ForegroundColor White
Write-Host "Successfully Disabled: $successCount" -ForegroundColor Green
Write-Host "Already Disabled: $alreadyDisabledCount" -ForegroundColor Gray
Write-Host "Microsoft-Managed (Cannot Modify): $microsoftManagedCount" -ForegroundColor Yellow
Write-Host "Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) {"Red"} else {"Gray"})

$microsoftManaged = $results | Where-Object {$_.Status -eq "Cannot Modify"}
if ($microsoftManaged.Count -gt 0) {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║     MICROSOFT-MANAGED APPS (Cannot be directly disabled)  ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    $microsoftManaged | ForEach-Object {
        Write-Host "`n• $($_.DisplayName)" -ForegroundColor White
        Write-Host "  App ID: $($_.AppId)" -ForegroundColor Gray
        Write-Host "  Action: Will be blocked via Conditional Access in next step" -ForegroundColor Gray
    }
    
    Write-Host "`n⚠️  IMPORTANT:" -ForegroundColor Yellow
    Write-Host "These apps are managed by Microsoft and cannot be directly disabled." -ForegroundColor White
    Write-Host "They WILL be blocked via Conditional Access policy in the next step." -ForegroundColor White
    Write-Host "This is expected behavior and does not indicate a failure." -ForegroundColor Gray
}

if ($failedCount -gt 0) {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                    FAILURES DETECTED                       ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    
    $failures = $results | Where-Object {$_.Status -eq "Failed"}
    $failures | ForEach-Object {
        Write-Host "`n• $($_.DisplayName)" -ForegroundColor Red
        Write-Host "  Error: $($_.ErrorMessage)" -ForegroundColor Gray
    }
    
    Write-Host "`n⚠️  Manual intervention required for failed items" -ForegroundColor Yellow
}

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Review disable operation results" -ForegroundColor Gray
Write-Host "2. Run 05-Create-CA-Policy-BlockCopilot.ps1" -ForegroundColor Gray
Write-Host "3. CA policy will block ALL Copilot apps (including Microsoft-managed)" -ForegroundColor Gray

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

return $results
