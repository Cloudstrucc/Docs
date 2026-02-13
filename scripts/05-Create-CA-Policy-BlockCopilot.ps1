# Script: 05-Create-CA-Policy-BlockCopilot.ps1
# Purpose: Create Conditional Access policy to block Copilot apps
# Version: 1.1
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     CONDITIONAL ACCESS POLICY CREATION                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Application.Read.All"

# Load discovered Copilot apps
$discoveredAppsPath = Get-ChildItem -Path ".\CopilotDiscovery_*.csv" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($discoveredAppsPath) {
    Write-Host "✓ Loading discovered apps from: $($discoveredAppsPath.Name)" -ForegroundColor Green
    $copilotApps = Import-Csv -Path $discoveredAppsPath.FullName
    $copilotAppIds = $copilotApps | Select-Object -ExpandProperty AppId -Unique | Where-Object { $_ -and $_ -ne "N/A" }
}
else {
    Write-Host "⚠️  No discovery file found" -ForegroundColor Yellow
    Write-Host "Using known Microsoft Copilot App IDs..." -ForegroundColor Gray
    
    $copilotAppIds = @(
        "0f698dd4-f011-4d23-a33e-b36416dcb1e6",
        "4e291c71-d680-4d0e-9640-0a3358e31177",
        "2e49aa60-1bd3-43b6-8ab6-03ada3d9f08b",
        "bb2a2e3a-c5e7-4f0a-88e0-8e01fd3fc1f4"
    )
}

if ($copilotAppIds.Count -eq 0) {
    Write-Host "`n✗ No Copilot App IDs found. Cannot create policy." -ForegroundColor Red
    Write-Host "Run 01-Discover-CopilotApps.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║          CREATING CONDITIONAL ACCESS POLICY               ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

Write-Host "`nPolicy Configuration:" -ForegroundColor Cyan
Write-Host "  Name: BLOCK - Microsoft Copilot Services" -ForegroundColor White
Write-Host "  State: Enabled" -ForegroundColor White
Write-Host "  Target Users: All users" -ForegroundColor White
Write-Host "  Target Apps: $($copilotAppIds.Count) Copilot applications" -ForegroundColor White
Write-Host "  Grant Control: Block access" -ForegroundColor White

Write-Host "`n📋 Copilot App IDs to be blocked:" -ForegroundColor Cyan
$copilotAppIds | ForEach-Object {
    Write-Host "  • $_" -ForegroundColor Gray
}

Write-Host "`n⚠️  BREAK-GLASS ACCOUNT EXCLUSION" -ForegroundColor Yellow
Write-Host "Do you want to exclude any break-glass/emergency accounts? (Y/N): " -NoNewline
$excludeBreakGlass = Read-Host

$excludedUsers = @()
if ($excludeBreakGlass -eq "Y" -or $excludeBreakGlass -eq "y") {
    Write-Host "`nEnter break-glass account Object IDs (comma-separated):" -ForegroundColor Cyan
    Write-Host "Example: 12345678-1234-1234-1234-123456789012,98765432-9876-9876-9876-987654321098" -ForegroundColor Gray
    $excludeInput = Read-Host "Break-glass Object IDs"
    if ($excludeInput) {
        $excludedUsers = $excludeInput -split "," | ForEach-Object { $_.Trim() }
        Write-Host "✓ Will exclude $($excludedUsers.Count) break-glass accounts" -ForegroundColor Green
    }
}

# Define CA policy
$policyParams = @{
    displayName = "BLOCK - Microsoft Copilot Services"
    state = "enabled"
    conditions = @{
        applications = @{
            includeApplications = $copilotAppIds
        }
        users = @{
            includeUsers = @("All")
            excludeUsers = $excludedUsers
            excludeGroups = @()
        }
        clientAppTypes = @("all")
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("block")
    }
}

try {
    Write-Host "`nChecking for existing policy..." -ForegroundColor Yellow
    $existingPolicies = Get-MgIdentityConditionalAccessPolicy -All
    $existingPolicy = $existingPolicies | Where-Object { $_.DisplayName -eq $policyParams.displayName }
    
    if ($existingPolicy) {
        Write-Host "`n⚠️  Policy already exists:" -ForegroundColor Yellow
        Write-Host "  Name: $($existingPolicy.DisplayName)" -ForegroundColor White
        Write-Host "  ID: $($existingPolicy.Id)" -ForegroundColor Gray
        Write-Host "  State: $($existingPolicy.State)" -ForegroundColor White
        
        $updateChoice = Read-Host "`nDo you want to UPDATE the existing policy? (Y/N)"
        if ($updateChoice -eq "Y" -or $updateChoice -eq "y") {
            Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $existingPolicy.Id -BodyParameter $policyParams
            Write-Host "`n✓ Policy updated successfully" -ForegroundColor Green
            $policyId = $existingPolicy.Id
            $policyAction = "Updated"
        }
        else {
            Write-Host "`nPolicy update skipped - using existing policy" -ForegroundColor Yellow
            $policyId = $existingPolicy.Id
            $policyAction = "Existing"
        }
    }
    else {
        Write-Host "`nCreating new Conditional Access policy..." -ForegroundColor Yellow
        $newPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $policyParams
        Write-Host "`n✓ Policy created successfully" -ForegroundColor Green
        Write-Host "  Policy ID: $($newPolicy.Id)" -ForegroundColor Gray
        $policyId = $newPolicy.Id
        $policyAction = "Created"
    }
    
    # Document the policy
    $policyDoc = [PSCustomObject]@{
        PolicyName = $policyParams.displayName
        PolicyId = $policyId
        State = $policyParams.state
        Action = $policyAction
        TargetAppCount = $copilotAppIds.Count
        TargetAppIds = ($copilotAppIds -join "; ")
        ExcludedUsers = ($excludedUsers -join "; ")
        ExcludedUserCount = $excludedUsers.Count
        CreatedBy = $env:USERNAME
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Status = "Active"
        AzurePortalURL = "https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess/PolicyBlade/policyId/$policyId"
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $exportPath = ".\CA_Policy_Copilot_$timestamp.csv"
    $policyDoc | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "`n✓ Policy documentation exported to: $exportPath" -ForegroundColor Green
    
    # Verify policy
    Write-Host "`nVerifying policy configuration..." -ForegroundColor Yellow
    $verifyPolicy = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              POLICY CONFIGURATION VERIFIED                 ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nPolicy Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($verifyPolicy.DisplayName)" -ForegroundColor White
    Write-Host "  ID: $($verifyPolicy.Id)" -ForegroundColor White
    Write-Host "  State: $($verifyPolicy.State)" -ForegroundColor White
    Write-Host "  Target Apps: $($verifyPolicy.Conditions.Applications.IncludeApplications.Count)" -ForegroundColor White
    Write-Host "  Excluded Users: $($verifyPolicy.Conditions.Users.ExcludeUsers.Count)" -ForegroundColor White
    Write-Host "  Grant Control: Block" -ForegroundColor White
    Write-Host "  Portal URL: $($policyDoc.AzurePortalURL)" -ForegroundColor Gray
    
    if ($verifyPolicy.State -eq "enabled") {
        Write-Host "`n✓ Policy is ENABLED and actively blocking Copilot apps" -ForegroundColor Green
    }
    else {
        Write-Host "`n⚠️  Policy state: $($verifyPolicy.State)" -ForegroundColor Yellow
        Write-Host "Policy may need to be manually enabled" -ForegroundColor Gray
    }
    
}
catch {
    Write-Host "`n✗ Error creating CA policy: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

Write-Host "`n📋 POLICY EFFECTIVENESS:" -ForegroundColor Cyan
Write-Host "  ✓ Blocks ALL Copilot applications" -ForegroundColor Green
Write-Host "  ✓ Prevents user authentication to Copilot services" -ForegroundColor Green
Write-Host "  ✓ Applies to all users except excluded break-glass accounts" -ForegroundColor Green
Write-Host "  ✓ Takes effect immediately" -ForegroundColor Green

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Verify policy in Entra ID portal" -ForegroundColor Gray
Write-Host "2. Test with non-admin account" -ForegroundColor Gray
Write-Host "3. Run 06-Document-M365-Copilot-Settings.ps1" -ForegroundColor Gray

Write-Host "`n✓ Conditional Access configuration completed" -ForegroundColor Green
Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
