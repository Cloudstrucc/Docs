# Script: 01-Discover-CopilotApps.ps1
# Purpose: Identify all Copilot components in the tenant
# Version: 1.1
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          COPILOT COMPONENT DISCOVERY SCRIPT                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All"

# Define search criteria
$copilotKeywords = @(
    "Copilot",
    "AI Builder",
    "Power Platform Advisor",
    "Dataverse AI",
    "Power Apps AI",
    "Power Automate AI",
    "Microsoft 365 Copilot",
    "Microsoft Copilot"
)

# Known Microsoft Copilot App IDs
$knownCopilotAppIds = @(
    "0f698dd4-f011-4d23-a33e-b36416dcb1e6",  # Microsoft Copilot
    "4e291c71-d680-4d0e-9640-0a3358e31177",  # Power Platform Advisor
    "2e49aa60-1bd3-43b6-8ab6-03ada3d9f08b",  # Copilot in Power Platform
    "bb2a2e3a-c5e7-4f0a-88e0-8e01fd3fc1f4"   # Copilot for M365
)

# Initialize results array
$discoveredApps = @()

# Search by display name
Write-Host "`n=== Searching for Copilot Components ===" -ForegroundColor Cyan
foreach ($keyword in $copilotKeywords) {
    Write-Host "Searching for: $keyword" -ForegroundColor Yellow
    
    # Service Principals
    $servicePrincipals = Get-MgServicePrincipal -All | Where-Object {
        $_.DisplayName -like "*$keyword*"
    }
    
    foreach ($sp in $servicePrincipals) {
        $discoveredApps += [PSCustomObject]@{
            Type = "ServicePrincipal"
            DisplayName = $sp.DisplayName
            AppId = $sp.AppId
            ObjectId = $sp.Id
            AccountEnabled = $sp.AccountEnabled
            PublisherName = $sp.PublisherName
            CreatedDateTime = $sp.CreatedDateTime
            SignInAudience = $sp.SignInAudience
            ServicePrincipalType = $sp.ServicePrincipalType
        }
    }
    
    # App Registrations
    $appRegistrations = Get-MgApplication -All | Where-Object {
        $_.DisplayName -like "*$keyword*"
    }
    
    foreach ($app in $appRegistrations) {
        $discoveredApps += [PSCustomObject]@{
            Type = "AppRegistration"
            DisplayName = $app.DisplayName
            AppId = $app.AppId
            ObjectId = $app.Id
            AccountEnabled = "N/A"
            PublisherName = $app.PublisherDomain
            CreatedDateTime = $app.CreatedDateTime
            SignInAudience = $app.SignInAudience
            ServicePrincipalType = "N/A"
        }
    }
}

# Search by known App IDs
Write-Host "`nSearching by known App IDs..." -ForegroundColor Yellow
foreach ($appId in $knownCopilotAppIds) {
    $sp = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
    if ($sp) {
        $exists = $discoveredApps | Where-Object { $_.AppId -eq $sp.AppId }
        if (-not $exists) {
            $discoveredApps += [PSCustomObject]@{
                Type = "ServicePrincipal (Known)"
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.Id
                AccountEnabled = $sp.AccountEnabled
                PublisherName = $sp.PublisherName
                CreatedDateTime = $sp.CreatedDateTime
                SignInAudience = $sp.SignInAudience
                ServicePrincipalType = $sp.ServicePrincipalType
            }
        }
    }
}

# Remove duplicates
$uniqueApps = $discoveredApps | Sort-Object -Property AppId -Unique

# Display results
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          DISCOVERED COPILOT COMPONENTS                     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "`nTotal unique components found: $($uniqueApps.Count)" -ForegroundColor Cyan

if ($uniqueApps.Count -gt 0) {
    $uniqueApps | Format-Table Type, DisplayName, AppId, AccountEnabled -AutoSize
    
    Write-Host "`n=== COMPONENT BREAKDOWN ===" -ForegroundColor Cyan
    $servicePrincipals = ($uniqueApps | Where-Object {$_.Type -like "*ServicePrincipal*"}).Count
    $appRegistrations = ($uniqueApps | Where-Object {$_.Type -eq "AppRegistration"}).Count
    $enabled = ($uniqueApps | Where-Object {$_.AccountEnabled -eq $true}).Count
    $disabled = ($uniqueApps | Where-Object {$_.AccountEnabled -eq $false}).Count
    
    Write-Host "Service Principals: $servicePrincipals" -ForegroundColor White
    Write-Host "App Registrations: $appRegistrations" -ForegroundColor White
    Write-Host "Enabled: $enabled" -ForegroundColor $(if ($enabled -gt 0) {"Red"} else {"Green"})
    Write-Host "Disabled: $disabled" -ForegroundColor Gray
}
else {
    Write-Host "`n✓ No Copilot components found in tenant" -ForegroundColor Green
}

# Export to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\CopilotDiscovery_$timestamp.csv"
$uniqueApps | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n✓ Exported to: $exportPath" -ForegroundColor Green

# Generate summary report
$summary = @{
    DiscoveryDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ExecutedBy = $env:USERNAME
    TotalComponents = $uniqueApps.Count
    ServicePrincipals = ($uniqueApps | Where-Object {$_.Type -like "*ServicePrincipal*"}).Count
    AppRegistrations = ($uniqueApps | Where-Object {$_.Type -eq "AppRegistration"}).Count
    EnabledComponents = ($uniqueApps | Where-Object {$_.AccountEnabled -eq $true}).Count
    DisabledComponents = ($uniqueApps | Where-Object {$_.AccountEnabled -eq $false}).Count
}

Write-Host "`n=== DISCOVERY SUMMARY ===" -ForegroundColor Cyan
$summary.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host "$($_.Key): $($_.Value)" -ForegroundColor White
}

# Export summary
$summaryPath = ".\CopilotDiscoverySummary_$timestamp.json"
$summary | ConvertTo-Json | Out-File -FilePath $summaryPath
Write-Host "`n✓ Summary exported to: $summaryPath" -ForegroundColor Green

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Discovery Complete - Review results before proceeding" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

return $uniqueApps
