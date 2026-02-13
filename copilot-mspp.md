# Microsoft Copilot Disable - Build Book

**Document Control**

- **Version:** 1.1
- **Date:** February 9, 2026
- **Author:** CloudStrucc Inc.
- **Classification:** Protected B
- **Review Cycle:** Annual

---

## Executive Summary

This build book provides comprehensive procedures for disabling Microsoft Copilot features across Microsoft 365, Power Platform, and Azure environments to maintain compliance with Protected B data handling requirements and ITSG-33 security controls.

### Purpose

Disable all Copilot functionality that sends organizational data to external Azure OpenAI services, ensuring data residency and classification requirements are maintained for defense contractor operations.

### Scope

- Power Platform tenant-level Copilot settings
- Environment-level Copilot configurations
- Azure AD/Entra ID service principals and app registrations
- M365 Copilot features
- Conditional Access policies
- Ongoing compliance monitoring

### Security Rationale

**Risk:** Microsoft Copilot sends user prompts, metadata, and contextual data to Azure OpenAI services hosted outside controlled data boundaries.

**Impact:**

- Violation of Protected B data residency requirements
- Potential exposure of NATO classified metadata
- Non-compliance with ITSG-33 controls (SC-7, AC-4, SC-8)
- Unauthorized data egress to third-party AI services

**Mitigation:** Complete disablement of Copilot functionality at all organizational levels.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Implementation Procedures](#implementation-procedures)
4. [Verification and Testing](#verification-and-testing)
5. [Monitoring and Compliance](#monitoring-and-compliance)
6. [Troubleshooting](#troubleshooting)
7. [Rollback Procedures](#rollback-procedures)
8. [Appendices](#appendices)

---

## Architecture Overview

### Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Microsoft 365 Tenant                      │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Power Platform Admin Center                │    │
│  │  https://admin.powerplatform.microsoft.com         │    │
│  │  /copilot/settings                                 │    │
│  │  • All Copilot Toggles (OFF)                       │    │
│  │  • Cross-region data movement (OFF)                │    │
│  │  • Environment Settings (All Envs - Copilot OFF)   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Azure AD / Entra ID                         │    │
│  │  • Service Principals (Disabled)                    │    │
│  │  • App Registrations (Identified/Documented)        │    │
│  │  • Conditional Access (Block Copilot AppIDs)        │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         M365 Admin Center                           │    │
│  │  • Copilot Settings (Disabled)                      │    │
│  │  • User License Assignment (Blocked)                │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         │
         │ ✗ BLOCKED
         ▼
    Azure OpenAI Services
    (External to Tenant)
```

### Data Flow (Blocked)

**Before Mitigation:**

```
User Input → Copilot → Azure OpenAI (Internet) → Response
                           │
                           └──> Potential data exposure
                                Canadian data residency violated
                                Protected B boundaries breached
```

**After Mitigation:**

```
User Input → Copilot (DISABLED) → ✗ No external communication
                                    ✗ No data egress
                                    ✓ Protected B boundaries maintained
```

### Security Controls Implemented

| Control ID | Control Name | Implementation |
|------------|-------------|----------------|
| SC-7 | Boundary Protection | Block external AI service communication |
| AC-4 | Information Flow Enforcement | Prevent data egress to Azure OpenAI |
| SC-8 | Transmission Confidentiality | Eliminate uncontrolled encryption paths |
| CM-7 | Least Functionality | Disable unnecessary AI features |
| SI-4 | System Monitoring | Continuous compliance monitoring |
| SC-12 | Data Location | Enforce Canadian data residency |

---

## Prerequisites

### Required Permissions

| System | Required Role | Purpose |
|--------|---------------|---------|
| Power Platform | Power Platform Administrator | Tenant and environment settings |
| Azure AD | Application Administrator | Service principal management |
| Azure AD | Conditional Access Administrator | CA policy creation |
| M365 | Global Administrator | Tenant-wide settings |
| Security | Security Administrator | Compliance monitoring |

### Required PowerShell Modules

```powershell
# Install required modules
Install-Module Microsoft.Graph.Authentication -Force -AllowClobber
Install-Module Microsoft.Graph.Applications -Force -AllowClobber
Install-Module Microsoft.Graph.Identity.SignIns -Force -AllowClobber
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
Install-Module AzureAD -Force -AllowClobber

# Verify installation
Get-Module Microsoft.Graph.* -ListAvailable
Get-Module Microsoft.PowerApps.Administration.PowerShell -ListAvailable
```

### Environment Requirements

- PowerShell 7.x or later
- Network access to Microsoft Graph API endpoints
- Administrative access to Power Platform Admin Center
- Azure Portal access with appropriate RBAC
- Audit logging enabled for all actions

### Pre-Implementation Checklist

- [ ] Backup current tenant settings
- [ ] Document current Copilot usage (if any)
- [ ] Notify stakeholders of pending changes
- [ ] Schedule maintenance window
- [ ] Prepare rollback plan
- [ ] Obtain change approval (CAB/Security)
- [ ] Create change control ticket
- [ ] Verify screenshot storage location accessible

---

## Implementation Procedures

### Phase 1: Discovery and Documentation

#### Step 1.1: Identify Existing Copilot Components

**Purpose:** Catalog all Copilot-related app registrations and service principals before making changes.

**Procedure:**

```powershell
# Script: 01-Discover-CopilotApps.ps1
# Purpose: Identify all Copilot components in the tenant
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

# Connect to Microsoft Graph
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          COPILOT COMPONENT DISCOVERY SCRIPT                  ║" -ForegroundColor Cyan
Write-Host "║                                                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════  ════════╝`n" -ForegroundColor Cyan

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
        # Check if already in discovered apps
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
    
    # Show breakdown by type
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
    Write-Host "This is the expected state for Protected B compliance" -ForegroundColor Gray
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

# Return results for use in subsequent scripts
return $uniqueApps
```

**Expected Output:**

- CSV file with all discovered Copilot components
- JSON summary file with statistics
- Console summary showing counts by type
- Object array for pipeline processing

**Verification:**

- [ ] CSV file created in working directory
- [ ] JSON summary file created
- [ ] All components documented
- [ ] Summary counts reviewed
- [ ] Screenshot of results captured

---

### Phase 2: Power Platform Configuration

#### Step 2.1: Disable Copilot at Tenant Level

**Purpose:** Prevent Copilot from being enabled in any Power Platform environment.

**Direct URL Method (Recommended):**

**Configuration URL:** `https://admin.powerplatform.microsoft.com/copilot/settings`

**Manual Procedure:**

1. **Navigate** to: <https://admin.powerplatform.microsoft.com/copilot/settings>
2. **Authenticate** with Power Platform Administrator credentials
3. **Capture "Before" Screenshot** showing current state
4. **Configure the following settings to OFF:**
   - ☐ **Copilot** (main toggle at top)
   - ☐ **Copilot in Power Apps**
   - ☐ **Copilot in Power Automate**
   - ☐ **Copilot in Power Pages**
   - ☐ **Allow users to analyze data using an AI-powered chat experience in canvas apps**
   - ☐ **Move data across regions** ⚠️ CRITICAL for Canadian data residency
   - ☐ **Bing search** (if present)
   - ☐ **Generative AI features** (if present)
5. **Click Save**
6. **Confirm changes** when prompted
7. **Capture "After" Screenshot** showing disabled state
8. **Capture "Confirmation" Screenshot** of save success message

**Screenshot Storage Location:**

- Network Path: `\\leonardocompany\compliance\M365-SEC-018\PowerPlatform\Tenant\`
- Local Backup: `C:\SecurityCompliance\M365-SEC-018\Screenshots\`

**PowerShell Documentation Script:**

```powershell
# Script: 02-Disable-PowerPlatform-Copilot-Tenant.ps1
# Purpose: Document Copilot tenant-level configuration
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     POWER PLATFORM COPILOT TENANT CONFIGURATION            ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Connect to Power Platform
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

Write-Host "`n📁 Screenshot Storage:" -ForegroundColor Cyan
Write-Host "   \\leonardocompany\compliance\M365-SEC-018\PowerPlatform\Tenant\" -ForegroundColor Gray

Write-Host "`n✅ CONFIGURATION CHECKLIST:" -ForegroundColor Cyan
$checklist = @(
    "Navigate to direct URL",
    "Capture 'Before' screenshot",
    "Disable all 8 settings listed above",
    "Click SAVE button",
    "Confirm save operation",
    "Capture 'After' screenshot",
    "Capture 'Confirmation' screenshot",
    "Store screenshots in compliance folder"
)

foreach ($item in $checklist) {
    Write-Host "   ☐ $item" -ForegroundColor Gray
}

# Pause for manual completion
Write-Host "`n" -NoNewline
$completed = Read-Host "Have you completed all the above steps? (Y/N)"

if ($completed -ne "Y" -and $completed -ne "y") {
    Write-Host "`n⚠️  Configuration not completed. Exiting..." -ForegroundColor Yellow
    Write-Host "Re-run this script after completing the manual steps." -ForegroundColor Gray
    exit 0
}

# Document the configuration
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
    MoveDataAcrossRegions = "OFF - CRITICAL for Canadian data residency"
    BingSearch = "OFF"
    GenerativeAI = "OFF"
    ScreenshotsCaptured = "Before, After, Confirmation"
    ScreenshotLocation = "\\leonardocompany\compliance\M365-SEC-018\PowerPlatform\Tenant\"
    ComplianceControl = "M365-SEC-018"
    ChangeTicket = Read-Host "`nEnter Change Control Ticket Number"
    ApprovedBy = Read-Host "Enter Approver Name"
}

# Export configuration
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\TenantCopilotConfig_$timestamp.csv"
$tenantConfig | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n✓ Configuration documented: $exportPath" -ForegroundColor Green

# Display configuration summary
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              CONFIGURATION SUMMARY                         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

$tenantConfig | Format-List

Write-Host "`n✓ Tenant-level Copilot configuration completed" -ForegroundColor Green
Write-Host "`n⏱️  PROPAGATION TIME:" -ForegroundColor Yellow
Write-Host "   • Most environments: 1-4 hours" -ForegroundColor Gray
Write-Host "   • All environments: Up to 24 hours" -ForegroundColor Gray
Write-Host "   • Verify in Step 2.2 after propagation period" -ForegroundColor Gray

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "   1. Wait 24 hours for full propagation" -ForegroundColor Gray
Write-Host "   2. Run Step 2.2 - Environment-level verification" -ForegroundColor Gray
Write-Host "   3. Update ISME documentation" -ForegroundColor Gray

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
```

**Expected Configuration State:**

| Setting | Required State | Purpose | Protected B Impact |
|---------|---------------|---------|-------------------|
| Copilot (main toggle) | OFF | Master switch for all Copilot features | High - Disables all AI processing |
| Copilot in Power Apps | OFF | Disables AI chat in canvas and model-driven apps | High - Prevents app data exposure |
| Copilot in Power Automate | OFF | Disables flow creation assistant | High - Prevents flow metadata exposure |
| Copilot in Power Pages | OFF | Disables website content generation | High - Prevents portal data exposure |
| AI data analysis | OFF | Disables AI-powered data analysis | High - Prevents Dataverse exposure |
| Move data across regions | OFF | **CRITICAL** - Prevents data from leaving Canadian data centers | **CRITICAL** - Data residency requirement |
| Bing search | OFF | Prevents external search integration | Medium - Prevents external queries |
| Generative AI features | OFF | Disables all AI-powered content generation | High - Prevents content exposure |

**Verification:**

- [ ] Direct URL accessed successfully
- [ ] All eight settings disabled
- [ ] Changes saved without errors
- [ ] Screenshots captured (before/after/confirmation)
- [ ] Screenshots stored in compliance folder
- [ ] Configuration documented in CSV
- [ ] Change control ticket number recorded
- [ ] Approver name documented

**Propagation Time:**

- Most environments: 1-4 hours
- All environments: Up to 24 hours
- Verify in Step 2.2 after 24-hour propagation period

---

#### Step 2.2: Verify and Document Environment-Level Settings

**Purpose:** Ensure no individual environment has Copilot enabled after tenant-level propagation.

**Procedure:**

```powershell
# Script: 03-Verify-Environment-Copilot-Settings.ps1
# Purpose: Verify Copilot settings for all Power Platform environments
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     POWER PLATFORM ENVIRONMENT VERIFICATION                ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Connect to Power Platform
Write-Host "Connecting to Power Platform..." -ForegroundColor Yellow
Add-PowerAppsAccount

# Get all environments
Write-Host "`nRetrieving all environments..." -ForegroundColor Yellow
$environments = Get-AdminPowerAppEnvironment

Write-Host "✓ Found $($environments.Count) environments" -ForegroundColor Green

# Initialize results array
$results = @()

# Process each environment
Write-Host "`n=== VERIFYING ENVIRONMENT COPILOT SETTINGS ===" -ForegroundColor Cyan

foreach ($env in $environments) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "Environment: $($env.DisplayName)" -ForegroundColor Yellow
    Write-Host "Environment ID: $($env.EnvironmentName)" -ForegroundColor Gray
    Write-Host "Type: $($env.EnvironmentType)" -ForegroundColor Gray
    Write-Host "Region: $($env.Location)" -ForegroundColor Gray
    
    # Note: Direct Copilot setting retrieval may not be available via cmdlet
    # Manual verification required per environment
    
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

# Export results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\EnvironmentCopilotVerification_$timestamp.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n✓ Verification report exported to: $exportPath" -ForegroundColor Green

# Generate manual verification guide
$manualGuide = @"

╔════════════════════════════════════════════════════════════╗
║         MANUAL ENVIRONMENT VERIFICATION GUIDE              ║
╚════════════════════════════════════════════════════════════╝

For each environment listed below, perform the following steps:

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

SCREENSHOT STORAGE:
\\leonardocompany\compliance\M365-SEC-018\PowerPlatform\Environments\

VERIFICATION CHECKLIST:
☐ All environments verified
☐ All screenshots captured
☐ CSV updated with verification status
☐ Screenshots stored in compliance folder

"@

Write-Host $manualGuide -ForegroundColor Yellow

# Save manual guide
$guidePath = ".\EnvironmentVerificationGuide_$timestamp.txt"
$manualGuide | Out-File -FilePath $guidePath
Write-Host "`n✓ Manual verification guide saved to: $guidePath" -ForegroundColor Green

# Display summary
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
Write-Host "5. Proceed to Phase 3 (Azure AD Configuration)" -ForegroundColor Gray

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
```

**Manual Verification Steps (Per Environment):**

For each environment in the exported CSV:

1. **Navigate** to environment settings URL (provided in CSV)
2. **Click** Settings → **Features** tab
3. **Verify** the following are **OFF**:
   - Copilot
   - Generative AI features
   - AI Builder (if not required for business operations)
4. **If any are ON:**
   - Disable them
   - Click **Save**
   - Wait for confirmation
5. **Capture screenshot** showing disabled state
6. **Store screenshot** in: `\\leonardocompany\compliance\M365-SEC-018\PowerPlatform\Environments\[EnvironmentName]\`
7. **Update CSV** with "Verified" status and your name

**Verification:**

- [ ] All environments processed
- [ ] Manual verification completed for each environment
- [ ] All screenshots captured and stored
- [ ] CSV updated with verification status and verifier names
- [ ] No environments have Copilot enabled
- [ ] Documentation complete

---

### Phase 3: Azure AD / Entra ID Configuration

#### Step 3.1: Disable Copilot Service Principals

**Purpose:** Prevent existing Copilot service principals from functioning.

**Procedure:**

```powershell
# Script: 04-Disable-Copilot-ServicePrincipals.ps1
# Purpose: Disable Copilot service principals in Azure AD
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     SERVICE PRINCIPAL DISABLE SCRIPT                       ║" -ForegroundColor Cyan
Write-Host "║                                                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Connect to Microsoft Graph
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
    # Re-run discovery
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
            # Attempt to disable
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
            # N/A or unknown state
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
        
        # Check if this is a Microsoft-managed app that can't be modified
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
                Action = "Will be blocked by Conditional Access in Step 3.2"
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

# Export results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\ServicePrincipalDisable_$timestamp.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n✓ Results exported to: $exportPath" -ForegroundColor Green

# Display summary
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  OPERATION SUMMARY                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`nTotal Processed: $($results.Count)" -ForegroundColor White
Write-Host "Successfully Disabled: $successCount" -ForegroundColor Green
Write-Host "Already Disabled: $alreadyDisabledCount" -ForegroundColor Gray
Write-Host "Microsoft-Managed (Cannot Modify): $microsoftManagedCount" -ForegroundColor Yellow
Write-Host "Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) {"Red"} else {"Gray"})

# Generate notes for Microsoft-managed apps
$microsoftManaged = $results | Where-Object {$_.Status -eq "Cannot Modify"}
if ($microsoftManaged.Count -gt 0) {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║     MICROSOFT-MANAGED APPS (Cannot be directly disabled)  ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    $microsoftManaged | ForEach-Object {
        Write-Host "`n• $($_.DisplayName)" -ForegroundColor White
        Write-Host "  App ID: $($_.AppId)" -ForegroundColor Gray
        Write-Host "  Action: Will be blocked via Conditional Access in Step 3.2" -ForegroundColor Gray
    }
    
    Write-Host "`n⚠️  IMPORTANT:" -ForegroundColor Yellow
    Write-Host "These apps are managed by Microsoft and cannot be directly disabled." -ForegroundColor White
    Write-Host "They WILL be blocked via Conditional Access policy in the next step." -ForegroundColor White
    Write-Host "This is expected behavior and does not indicate a failure." -ForegroundColor Gray
}

# Check for failures
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
Write-Host "2. Proceed to Step 3.2 - Create Conditional Access Policy" -ForegroundColor Gray
Write-Host "3. CA policy will block ALL Copilot apps (including Microsoft-managed)" -ForegroundColor Gray

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

return $results
```

**Expected Output:**

- CSV file with disable operation results
- Summary showing success/failure counts
- List of Microsoft-managed apps that cannot be directly disabled
- Guidance for next steps

**Verification:**

- [ ] All modifiable service principals disabled
- [ ] Microsoft-managed apps identified and documented
- [ ] Results exported to CSV
- [ ] No unexpected failures
- [ ] Summary reviewed

---

#### Step 3.2: Create Conditional Access Policy to Block Copilot

**Purpose:** Block access to Copilot applications as an additional security layer, especially for Microsoft-managed apps that cannot be directly disabled.

**Procedure:**

```powershell
# Script: 05-Create-CA-Policy-BlockCopilot.ps1
# Purpose: Create Conditional Access policy to block Copilot apps
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     CONDITIONAL ACCESS POLICY CREATION                     ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Connect to Microsoft Graph
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
    
    # Known Copilot App IDs
    $copilotAppIds = @(
        "0f698dd4-f011-4d23-a33e-b36416dcb1e6",  # Microsoft Copilot
        "4e291c71-d680-4d0e-9640-0a3358e31177",  # Power Platform Advisor
        "2e49aa60-1bd3-43b6-8ab6-03ada3d9f08b",  # Copilot in Power Platform
        "bb2a2e3a-c5e7-4f0a-88e0-8e01fd3fc1f4"   # Copilot for M365
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

# Get break-glass accounts (if any)
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
    # Check if policy already exists
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
        # Create new policy
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
        ComplianceControl = "M365-SEC-018"
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
    Write-Host "  Azure Portal: $($policyDoc.AzurePortalURL)" -ForegroundColor Gray
    
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
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║          MANUAL CREATION REQUIRED                          ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    Write-Host "`nCreate the policy manually in Azure Portal:" -ForegroundColor White
    Write-Host "`n1. Navigate to:" -ForegroundColor Cyan
    Write-Host "   https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess" -ForegroundColor Gray
    
    Write-Host "`n2. Click 'New policy'" -ForegroundColor Cyan
    
    Write-Host "`n3. Configure as follows:" -ForegroundColor Cyan
    Write-Host "   Name: BLOCK - Microsoft Copilot Services" -ForegroundColor Gray
    Write-Host "   Users: All users (exclude break-glass if needed)" -ForegroundColor Gray
    Write-Host "   Target resources: Cloud apps → Select apps" -ForegroundColor Gray
    
    Write-Host "`n4. Add these App IDs:" -ForegroundColor Cyan
    $copilotAppIds | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    
    Write-Host "`n5. Grant: Block access" -ForegroundColor Cyan
    Write-Host "6. Enable policy: On" -ForegroundColor Cyan
    Write-Host "7. Create" -ForegroundColor Cyan
    
    throw
}

Write-Host "`n📋 POLICY EFFECTIVENESS:" -ForegroundColor Cyan
Write-Host "  ✓ Blocks ALL Copilot applications (including Microsoft-managed)" -ForegroundColor Green
Write-Host "  ✓ Prevents user authentication to Copilot services" -ForegroundColor Green
Write-Host "  ✓ Applies to all users except excluded break-glass accounts" -ForegroundColor Green
Write-Host "  ✓ Takes effect immediately" -ForegroundColor Green

Write-Host "`n📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Verify policy in Azure Portal" -ForegroundColor Gray
Write-Host "2. Test with non-admin account (should be blocked)" -ForegroundColor Gray
Write-Host "3. Proceed to Phase 4 - M365 Copilot Settings" -ForegroundColor Gray

Write-Host "`n✓ Conditional Access configuration completed" -ForegroundColor Green
Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
```

**Manual Steps (if automated creation fails):**

1. Navigate to **Azure Portal** → **Azure AD** → **Security** → **Conditional Access**
   - Direct URL: <https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess>
2. Click **+ New policy**
3. Configure:
   - **Name:** BLOCK - Microsoft Copilot Services
   - **Users:** All users (exclude break-glass accounts if required)
   - **Target resources:** Cloud apps → Select apps → Add App IDs from discovery CSV
   - **Grant:** Block access
   - **Enable policy:** On
4. Click **Create**

**Verification:**

- [ ] CA policy created or updated
- [ ] Policy state is "Enabled"
- [ ] All Copilot App IDs included in policy
- [ ] Break-glass accounts excluded (if applicable)
- [ ] Policy documented in CSV
- [ ] Azure Portal URL accessible
- [ ] Policy tested with standard user account

---

### Phase 4: Microsoft 365 Copilot Settings

#### Step 4.1: Disable M365 Copilot via Admin Center

**Purpose:** Disable Microsoft 365 Copilot features (if licensed).

**Manual Procedure:**

1. **Navigate** to **Microsoft 365 Admin Center**: <https://admin.microsoft.com>
2. Go to **Settings** → **Org settings** → **Services**
3. Select **Microsoft 365 Copilot** (if present)
4. **Uncheck:**
   - "Allow users to access Microsoft Copilot"
   - "Allow Copilot to access web content"
   - "Allow Copilot in Microsoft 365 apps"
5. Click **Save**
6. **Capture screenshots** of before/after states

7. **License Management:**
   - Navigate to **Billing** → **Licenses**
   - If Copilot licenses exist:
     - Remove license assignments from all users
     - Document license count for future reference
   - **Capture screenshot** of license status

**Documentation Script:**

```powershell
# Script: 06-Document-M365-Copilot-Settings.ps1
# Purpose: Document M365 Copilot configuration
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     M365 COPILOT CONFIGURATION DOCUMENTATION               ║" -ForegroundColor Cyan
Write-Host "║                                                             ║" -ForegroundColor Cyan
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

# Document configuration
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
    ScreenshotLocation = "\\leonardocompany\compliance\M365-SEC-018\M365\"
    ComplianceControl = "M365-SEC-018"
    Notes = "All M365 Copilot features disabled per Protected B requirements"
    ChangeTicket = Read-Host "Enter Change Control Ticket Number"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\M365_Copilot_Config_$timestamp.csv"
$m365CopilotConfig | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "`n✓ M365 Copilot configuration documented: $exportPath" -ForegroundColor Green

# Display summary
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          CONFIGURATION SUMMARY                             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

$m365CopilotConfig | Format-List

Write-Host "`n✓ Phase 4 Complete - M365 Copilot disabled" -ForegroundColor Green
Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
```

**Verification:**

- [ ] M365 Copilot disabled in org settings
- [ ] All user licenses removed (0 assigned)
- [ ] Configuration documented
- [ ] Screenshots captured (before/after/licenses)
- [ ] Change ticket number recorded

---

## Verification and Testing

### Comprehensive Verification Script

```powershell
# Script: 99-Verify-Copilot-Disabled.ps1
# Purpose: Comprehensive verification that Copilot is disabled
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications, Microsoft.PowerApps.Administration.PowerShell

param(
    [switch]$ExportReport = $true,
    [string]$ReportPath = ".\CopilotComplianceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     COPILOT COMPLIANCE VERIFICATION REPORT                ║" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$results = @()
$overallStatus = "PASS"

# ============================================================
# CHECK 1: Power Platform Tenant Settings
# ============================================================
Write-Host "[1/6] Checking Power Platform tenant settings..." -ForegroundColor Yellow
Write-Host "      Direct URL: https://admin.powerplatform.microsoft.com/copilot/settings" -ForegroundColor Gray

try {
    Add-PowerAppsAccount -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "`n      ⚠️  MANUAL VERIFICATION REQUIRED" -ForegroundColor Yellow
    Write-Host "      Navigate to: https://admin.powerplatform.microsoft.com/copilot/settings" -ForegroundColor White
    Write-Host "`n      Verify ALL of the following are OFF:" -ForegroundColor Yellow
    Write-Host "        • Copilot (main toggle)" -ForegroundColor Gray
    Write-Host "        • Copilot in Power Apps" -ForegroundColor Gray
    Write-Host "        • Copilot in Power Automate" -ForegroundColor Gray
    Write-Host "        • Copilot in Power Pages" -ForegroundColor Gray
    Write-Host "        • AI data analysis" -ForegroundColor Gray
    Write-Host "        • Move data across regions (CRITICAL)" -ForegroundColor Gray
    Write-Host "        • Bing search" -ForegroundColor Gray
    Write-Host "        • Generative AI features" -ForegroundColor Gray
    
    $result = [PSCustomObject]@{
        CheckId = "PP-TENANT-01"
        Category = "Power Platform Tenant"
        Check = "Copilot Tenant Settings"
        Expected = "All toggles OFF"
        Actual = "Manual Verification Required"
        Status = "VERIFY"
        Severity = "Critical"
        Remediation = "Navigate to https://admin.powerplatform.microsoft.com/copilot/settings and verify all 8 settings are OFF"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "`n      Open the URL now for verification? (Y/N): " -NoNewline -ForegroundColor Cyan
    $openURL = Read-Host
    if ($openURL -eq "Y" -or $openURL -eq "y") {
        Start-Process "https://admin.powerplatform.microsoft.com/copilot/settings"
        Write-Host "      Browser opened. Complete manual verification." -ForegroundColor Yellow
        Read-Host "      Press Enter after completing verification"
    }
    
    $overallStatus = "VERIFY"
}
catch {
    $result = [PSCustomObject]@{
        CheckId = "PP-TENANT-01"
        Category = "Power Platform Tenant"
        Check = "Copilot Tenant Settings"
        Expected = "All toggles OFF"
        Actual = "Error: $($_.Exception.Message)"
        Status = "ERROR"
        Severity = "Critical"
        Remediation = "Review error and verify manually at https://admin.powerplatform.microsoft.com/copilot/settings"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "      ✗ Error occurred" -ForegroundColor Red
    $overallStatus = "FAIL"
}

$results += $result

# ============================================================
# CHECK 2: Power Platform Environments
# ============================================================
Write-Host "`n[2/6] Checking Power Platform environments..." -ForegroundColor Yellow

try {
    $environments = Get-AdminPowerAppEnvironment
    Write-Host "      Found $($environments.Count) environments" -ForegroundColor Gray
    
    Write-Host "`n      ⚠️  Each environment requires manual verification:" -ForegroundColor Yellow
    
    $envCount = 0
    foreach ($env in $environments) {
        $envCount++
        $result = [PSCustomObject]@{
            CheckId = "PP-ENV-$($envCount.ToString('00'))"
            Category = "Power Platform Environment"
            Check = "$($env.DisplayName) - Copilot Settings"
            Expected = "Copilot disabled"
            Actual = "Manual Verification Required"
            Status = "VERIFY"
            Severity = "High"
            Remediation = "Verify at: https://admin.powerplatform.microsoft.com/environments/$($env.EnvironmentName)/settings → Features → Copilot OFF"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $results += $result
        
        if ($envCount -le 5) {
            Write-Host "      • $($env.DisplayName)" -ForegroundColor Gray
        }
    }
    
    if ($envCount > 5) {
        Write-Host "      • ... and $($envCount - 5) more environments" -ForegroundColor Gray
    }
    
    Write-Host "`n      ✓ $($environments.Count) environments require manual verification" -ForegroundColor Yellow
}
catch {
    Write-Host "      ✗ Error checking environments: $($_.Exception.Message)" -ForegroundColor Red
}

# ============================================================
# CHECK 3: Service Principals Status
# ============================================================
Write-Host "`n[3/6] Checking Copilot service principals..." -ForegroundColor Yellow

try {
    Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome -ErrorAction Stop
    
    $copilotKeywords = @("Copilot", "AI Builder", "Power Platform Advisor")
    $activeSPs = @()
    
    foreach ($keyword in $copilotKeywords) {
        $sps = Get-MgServicePrincipal -All | Where-Object {
            $_.DisplayName -like "*$keyword*" -and $_.AccountEnabled -eq $true
        }
        $activeSPs += $sps
    }
    
    if ($activeSPs.Count -eq 0) {
        $result = [PSCustomObject]@{
            CheckId = "AAD-SP-01"
            Category = "Azure AD Service Principals"
            Check = "Active Copilot Service Principals"
            Expected = "0 active"
            Actual = "0 active"
            Status = "PASS"
            Severity = "High"
            Remediation = "N/A"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Write-Host "      ✓ No active Copilot service principals found" -ForegroundColor Green
    }
    else {
        $result = [PSCustomObject]@{
            CheckId = "AAD-SP-01"
            Category = "Azure AD Service Principals"
            Check = "Active Copilot Service Principals"
            Expected = "0 active"
            Actual = "$($activeSPs.Count) active"
            Status = "FAIL"
            Severity = "High"
            Remediation = "Disable service principals using script 04-Disable-Copilot-ServicePrincipals.ps1"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Write-Host "      ✗ Found $($activeSPs.Count) active service principals:" -ForegroundColor Red
        $activeSPs | ForEach-Object {
            Write-Host "         - $($_.DisplayName) ($($_.AppId))" -ForegroundColor Gray
        }
        
        $overallStatus = "FAIL"
    }
    
    $results += $result
}
catch {
    $result = [PSCustomObject]@{
        CheckId = "AAD-SP-01"
        Category = "Azure AD Service Principals"
        Check = "Active Copilot Service Principals"
        Expected = "0 active"
        Actual = "Error: $($_.Exception.Message)"
        Status = "ERROR"
        Severity = "High"
        Remediation = "Review error and check manually in Azure AD"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "      ✗ Error occurred" -ForegroundColor Red
    $results += $result
    $overallStatus = "FAIL"
}

# ============================================================
# CHECK 4: Conditional Access Policy
# ============================================================
Write-Host "`n[4/6] Checking Conditional Access policy..." -ForegroundColor Yellow

try {
    Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome -ErrorAction Stop
    
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All
    $copilotCAPolicy = $caPolicies | Where-Object { 
        $_.DisplayName -like "*Copilot*" -and $_.DisplayName -like "*BLOCK*" 
    }
    
    if ($copilotCAPolicy) {
        $policyEnabled = $copilotCAPolicy | Where-Object { $_.State -eq "enabled" }
        
        if ($policyEnabled) {
            $result = [PSCustomObject]@{
                CheckId = "AAD-CA-01"
                Category = "Conditional Access"
                Check = "Copilot Block Policy"
                Expected = "Enabled"
                Actual = "Enabled - $($policyEnabled.DisplayName)"
                Status = "PASS"
                Severity = "High"
                Remediation = "N/A"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            Write-Host "      ✓ Copilot block policy is active: $($policyEnabled.DisplayName)" -ForegroundColor Green
        }
        else {
            $result = [PSCustomObject]@{
                CheckId = "AAD-CA-01"
                Category = "Conditional Access"
                Check = "Copilot Block Policy"
                Expected = "Enabled"
                Actual = "Policy exists but is disabled"
                Status = "FAIL"
                Severity = "High"
                Remediation = "Enable the CA policy in Azure AD → Security → Conditional Access"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            Write-Host "      ✗ Policy exists but is not enabled" -ForegroundColor Red
            $overallStatus = "FAIL"
        }
    }
    else {
        $result = [PSCustomObject]@{
            CheckId = "AAD-CA-01"
            Category = "Conditional Access"
            Check = "Copilot Block Policy"
            Expected = "Enabled"
            Actual = "Policy not found"
            Status = "FAIL"
            Severity = "High"
            Remediation = "Create CA policy using script 05-Create-CA-Policy-BlockCopilot.ps1"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Write-Host "      ✗ No Copilot block policy found" -ForegroundColor Red
        $overallStatus = "FAIL"
    }
    
    $results += $result
}
catch {
    $result = [PSCustomObject]@{
        CheckId = "AAD-CA-01"
        Category = "Conditional Access"
        Check = "Copilot Block Policy"
        Expected = "Enabled"
        Actual = "Error: $($_.Exception.Message)"
        Status = "ERROR"
        Severity = "High"
        Remediation = "Review error and check manually"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "      ✗ Error occurred" -ForegroundColor Red
    $results += $result
    $overallStatus = "FAIL"
}

# ============================================================
# CHECK 5: M365 Copilot Settings
# ============================================================
Write-Host "`n[5/6] Checking M365 Copilot settings..." -ForegroundColor Yellow

$result = [PSCustomObject]@{
    CheckId = "M365-COP-01"
    Category = "Microsoft 365 Copilot"
    Check = "M365 Copilot Disabled"
    Expected = "Disabled, 0 licenses assigned"
    Actual = "Manual Verification Required"
    Status = "VERIFY"
    Severity = "High"
    Remediation = "Verify manually in M365 Admin Center → Settings → Org settings → Microsoft 365 Copilot"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

Write-Host "      ⚠️  Manual verification required" -ForegroundColor Yellow
Write-Host "      Check: https://admin.microsoft.com/Adminportal/Home#/Settings/Services" -ForegroundColor Gray
$results += $result

# ============================================================
# CHECK 6: Documentation Complete
# ============================================================
Write-Host "`n[6/6] Checking documentation..." -ForegroundColor Yellow

$requiredDocs = @(
    "CopilotDiscovery_*.csv",
    "ServicePrincipalDisable_*.csv",
    "CA_Policy_Copilot_*.csv",
    "TenantCopilotConfig_*.csv"
)

$missingDocs = @()
$foundDocs = @()

foreach ($docPattern in $requiredDocs) {
    $found = Get-ChildItem -Path $docPattern -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if ($found) {
        $foundDocs += $found.Name
    }
    else {
        $missingDocs += $docPattern
    }
}

if ($missingDocs.Count -eq 0) {
    $result = [PSCustomObject]@{
        CheckId = "DOC-01"
        Category = "Documentation"
        Check = "Required Documentation"
        Expected = "All present"
        Actual = "All present ($($foundDocs.Count) files)"
        Status = "PASS"
        Severity = "Medium"
        Remediation = "N/A"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "      ✓ All required documentation present ($($foundDocs.Count) files)" -ForegroundColor Green
}
else {
    $result = [PSCustomObject]@{
        CheckId = "DOC-01"
        Category = "Documentation"
        Check = "Required Documentation"
        Expected = "All present"
        Actual = "Missing: $($missingDocs -join ', ')"
        Status = "WARN"
        Severity = "Medium"
        Remediation = "Run all configuration scripts to generate documentation"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "      ⚠️  Missing documentation files:" -ForegroundColor Yellow
    $missingDocs | ForEach-Object {
        Write-Host "         - $_" -ForegroundColor Gray
    }
}

$results += $result

# ============================================================
# GENERATE SUMMARY REPORT
# ============================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   VERIFICATION SUMMARY                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$summary = @{
    TotalChecks = $results.Count
    Passed = ($results | Where-Object {$_.Status -eq "PASS"}).Count
    Failed = ($results | Where-Object {$_.Status -eq "FAIL"}).Count
    Warnings = ($results | Where-Object {$_.Status -eq "WARN"}).Count
    RequireVerification = ($results | Where-Object {$_.Status -eq "VERIFY"}).Count
    Errors = ($results | Where-Object {$_.Status -eq "ERROR"}).Count
}

Write-Host "Check Statistics:" -ForegroundColor White
Write-Host "  Total Checks: $($summary.TotalChecks)" -ForegroundColor Gray
Write-Host "  Passed: $($summary.Passed)" -ForegroundColor Green
Write-Host "  Failed: $($summary.Failed)" -ForegroundColor $(if ($summary.Failed -gt 0) {"Red"} else {"Gray"})
Write-Host "  Warnings: $($summary.Warnings)" -ForegroundColor $(if ($summary.Warnings -gt 0) {"Yellow"} else {"Gray"})
Write-Host "  Require Verification: $($summary.RequireVerification)" -ForegroundColor Yellow
Write-Host "  Errors: $($summary.Errors)" -ForegroundColor $(if ($summary.Errors -gt 0) {"Red"} else {"Gray"})

# Overall status determination
if ($summary.Failed -gt 0 -or $summary.Errors -gt 0) {
    $overallStatus = "FAIL"
    $statusColor = "Red"
    $statusSymbol = "✗"
}
elseif ($summary.RequireVerification -gt 0 -or $summary.Warnings -gt 0) {
    $overallStatus = "VERIFY"
    $statusColor = "Yellow"
    $statusSymbol = "⚠️"
}
else {
    $overallStatus = "PASS"
    $statusColor = "Green"
    $statusSymbol = "✓"
}

Write-Host "`n$statusSymbol Overall Compliance Status: $overallStatus" -ForegroundColor $statusColor

# Export detailed report
if ($ExportReport) {
    $results | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Host "`n✓ Detailed report exported to: $ReportPath" -ForegroundColor Cyan
    
    # Create human-readable HTML report
    $htmlReportPath = $ReportPath -replace "\.csv$", ".html"
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Copilot Compliance Report </title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background-color: #0078d4; color: white; padding: 12px; text-align: left; font-weight: bold; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f1f1f1; }
        .pass { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        .warn { color: orange; font-weight: bold; }
        .verify { color: darkorange; font-weight: bold; }
        .error { color: darkred; font-weight: bold; }
        .summary { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .summary-item { display: inline-block; margin: 10px 20px 10px 0; font-size: 16px; }
        .classification { background-color: #d32f2f; color: white; padding: 5px 15px; border-radius: 3px; display: inline-block; margin-bottom: 20px; font-weight: bold; }
        .critical { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 20px 0; }
        .success { background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="classification">PROTECTED B</div>
    <h1>Microsoft Copilot Compliance Verification Report</h1>
    <p><strong>Report Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <p><strong>Generated By:</strong> $env:USERNAME</p>
    <p><strong>Compliance Control:</strong> M365-SEC-018</p>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <div class="summary-item">Total Checks: <strong>$($summary.TotalChecks)</strong></div>
        <div class="summary-item">Passed: <strong class="pass">$($summary.Passed)</strong></div>
        <div class="summary-item">Failed: <strong class="fail">$($summary.Failed)</strong></div>
        <div class="summary-item">Warnings: <strong class="warn">$($summary.Warnings)</strong></div>
        <div class="summary-item">Require Verification: <strong class="verify">$($summary.RequireVerification)</strong></div>
        <div class="summary-item">Errors: <strong class="error">$($summary.Errors)</strong></div>
        <div style="margin-top: 20px; font-size: 18px;">
            <strong>Overall Compliance Status:</strong> <span class="$($overallStatus.ToLower())">$statusSymbol $overallStatus</span>
        </div>
    </div>
    
    <h2>Detailed Check Results</h2>
    <table>
        <tr>
            <th>Check ID</th>
            <th>Category</th>
            <th>Check</th>
            <th>Expected</th>
            <th>Actual</th>
            <th>Status</th>
            <th>Severity</th>
            <th>Remediation</th>
        </tr>
"@

    foreach ($check in $results) {
        $statusClass = $check.Status.ToLower()
        $htmlReport += @"
        <tr>
            <td>$($check.CheckId)</td>
            <td>$($check.Category)</td>
            <td>$($check.Check)</td>
            <td>$($check.Expected)</td>
            <td>$($check.Actual)</td>
            <td class="$statusClass">$($check.Status)</td>
            <td>$($check.Severity)</td>
            <td>$($check.Remediation)</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h2>Quick Reference URLs</h2>
    <table>
        <tr>
            <th>Component</th>
            <th>URL</th>
        </tr>
        <tr>
            <td>Power Platform Copilot Settings</td>
            <td><a href="https://admin.powerplatform.microsoft.com/copilot/settings" target="_blank">Direct Link</a></td>
        </tr>
        <tr>
            <td>Power Platform Environments</td>
            <td><a href="https://admin.powerplatform.microsoft.com/environments" target="_blank">Environments</a></td>
        </tr>
        <tr>
            <td>Azure AD Service Principals</td>
            <td><a href="https://portal.azure.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade/~/AppAppsPreview" target="_blank">Service Principals</a></td>
        </tr>
        <tr>
            <td>Conditional Access Policies</td>
            <td><a href="https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess/ConditionalAccessBlade/~/Policies" target="_blank">CA Policies</a></td>
        </tr>
        <tr>
            <td>M365 Copilot Settings</td>
            <td><a href="https://admin.microsoft.com/Adminportal/Home#/Settings/Services" target="_blank">Org Settings</a></td>
        </tr>
    </table>
    
    <h2>Next Steps</h2>
"@

    if ($summary.Failed -gt 0) {
        $htmlReport += "<div class='critical'><strong>CRITICAL:</strong> Address all FAILED checks immediately before proceeding.</div>"
    }
    
    $htmlReport += "<ul>"
    
    if ($summary.RequireVerification -gt 0) {
        $htmlReport += "<li>Manually verify all items marked as 'VERIFY' using the URLs provided</li>"
    }
    
    if ($summary.Warnings -gt 0) {
        $htmlReport += "<li>Review and address WARNING items</li>"
    }
    
    $htmlReport += @"
        <li>Update ISME documentation with compliance status</li>
        <li>Schedule monthly re-verification (automated)</li>
        <li>Report status to Security team</li>
        <li>Store this report in: \\leonardocompany\compliance\M365-SEC-018\Reports\</li>
    </ul>
    
    <h2>Security Controls</h2>
    <p>This report verifies implementation of the following ITSG-33 security controls:</p>
    <ul>
        <li><strong>SC-7:</strong> Boundary Protection - Blocking external AI service communication</li>
        <li><strong>AC-4:</strong> Information Flow Enforcement - Preventing data egress to Azure OpenAI</li>
        <li><strong>SC-8:</strong> Transmission Confidentiality - Eliminating uncontrolled encryption paths</li>
        <li><strong>CM-7:</strong> Least Functionality - Disabling unnecessary AI features</li>
        <li><strong>SI-4:</strong> System Monitoring - Continuous compliance monitoring</li>
        <li><strong>SC-12:</strong> Data Location - Enforcing Canadian data residency</li>
    </ul>
"@

    if ($overallStatus -eq "PASS") {
        $htmlReport += "<div class='success'><strong>✓ COMPLIANT:</strong> All automated checks passed. Complete manual verifications and maintain this state.</div>"
    }
    
    $htmlReport += @"
    <p style="margin-top: 40px; font-size: 0.9em; color: #666; border-top: 1px solid #ddd; padding-top: 20px;">    
        <em>Report Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") by $env:USERNAME</em>
    </p>
</body>
</html>
"@

    $htmlReport | Out-File -FilePath $htmlReportPath -Encoding UTF8
    Write-Host "✓ HTML report exported to: $htmlReportPath" -ForegroundColor Cyan
}

# Display failed/warning checks
if ($summary.Failed -gt 0) {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                  FAILED CHECKS                             ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    
    $results | Where-Object {$_.Status -eq "FAIL"} | ForEach-Object {
        Write-Host "`n✗ [$($_.CheckId)] $($_.Check)" -ForegroundColor Red
        Write-Host "  Expected: $($_.Expected)" -ForegroundColor Gray
        Write-Host "  Actual: $($_.Actual)" -ForegroundColor Gray
        Write-Host "  Remediation: $($_.Remediation)" -ForegroundColor Yellow
    }
}

if ($summary.RequireVerification -gt 0) {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║           MANUAL VERIFICATION REQUIRED                     ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    $results | Where-Object {$_.Status -eq "VERIFY"} | ForEach-Object {
        Write-Host "`n⚠️  [$($_.CheckId)] $($_.Check)" -ForegroundColor Yellow
        Write-Host "  Action: $($_.Remediation)" -ForegroundColor Gray
    }
}

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Verification Complete - Review reports and address findings" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

return $results
```

### Acceptance Criteria

**Automated Checks:**

- [ ] All automated checks show PASS status
- [ ] No active Copilot service principals
- [ ] Conditional Access policy active and enforced
- [ ] All documentation generated
- [ ] HTML and CSV reports created

**Manual Verifications:**

- [ ] Power Platform tenant settings verified (all 8 toggles OFF)
- [ ] All environment settings verified (Copilot OFF)
- [ ] M365 Copilot disabled and licenses removed
- [ ] Screenshots captured and stored

**Documentation:**

- [ ] All CSV files generated
- [ ] HTML compliance report generated
- [ ] Screenshots stored in compliance folder
- [ ] Change tickets documented
- [ ] ISME updated

**Overall:**

- [ ] Zero failed compliance checks
- [ ] All manual verifications completed
- [ ] Security team notified
- [ ] Monthly monitoring scheduled

---

## Monitoring and Compliance

### Monthly Compliance Check

Create a scheduled task to run verification monthly:

```powershell
# Script: Create-ScheduledCopilotCheck.ps1
# Purpose: Create scheduled task for monthly Copilot compliance checks
# Classification: Protected B
# Author: CloudStrucc Inc.
# Date: 2026-02-09

$taskName = "Monthly Copilot Compliance Check - Leonardo Company"
$scriptPath = "C:\Scripts\Copilot-Disable\99-Verify-Copilot-Disabled.ps1"
$logPath = "C:\Logs\CopilotCompliance"

# Create log directory if it doesn't exist
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}

# Create scheduled task action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -ExportReport | Out-File -FilePath `"$logPath\LastRun_$(Get-Date -Format 'yyyyMMdd').log`""

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
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "Monthly compliance check for Copilot disable status"
    
    Write-Host "`n✓ Scheduled task created: $taskName" -ForegroundColor Green
    Write-Host "  Schedule: 1st of each month at 6:00 AM" -ForegroundColor Gray
    Write-Host "  Script: $scriptPath" -ForegroundColor Gray
    Write-Host "  Logs: $logPath" -ForegroundColor Gray
}
catch {
    Write-Host "`n✗ Error creating scheduled task: $($_.Exception.Message)" -ForegroundColor Red
}
```

### Continuous Monitoring Integration

Add to existing CloudStrucc compliance monitoring:

```powershell
# Add to existing monitoring scripts
# File: Monitor-M365Security.ps1 (or similar)

function Test-CopilotCompliance {
    <#
    .SYNOPSIS
    Check Copilot compliance status
    
    .DESCRIPTION
    Runs comprehensive Copilot compliance verification and alerts on failures
    
    .PARAMETER AlertOnFailure
    Send email alert if compliance check fails
    
    .PARAMETER AlertRecipients
    Email addresses to receive alerts
    #>
    
    param(
        [switch]$AlertOnFailure,
        [string[]]$AlertRecipients = @("security@leonardocompany.ca", "it-ops@leonardocompany.ca")
    )
    
    # Run verification
    $results = & "C:\Scripts\Copilot-Disable\99-Verify-Copilot-Disabled.ps1" -ExportReport
    
    # Check for failures
    $failures = $results | Where-Object { $_.Status -in @("FAIL", "ERROR") }
    
    if ($failures.Count -gt 0 -and $AlertOnFailure) {
        # Get latest HTML report
        $htmlReport = Get-ChildItem -Path ".\CopilotComplianceReport_*.html" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
        
        # Compose alert email
        $emailBody = @"
ALERT: Microsoft Copilot Compliance Failure Detected
Compliance Control: M365-SEC-018
Severity: HIGH
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

FAILURES DETECTED: $($failures.Count)

Failed Checks:
$($failures | ForEach-Object { "- [$($_.CheckId)] $($_.Check): $($_.Actual)" } | Out-String)

ACTION REQUIRED:
1. Review attached compliance report
2. Remediate failed checks immediately
3. Re-run verification after remediation
4. Update ISME documentation

This is an automated alert from the M365 security monitoring system.
"@
        
        # Send alert
        try {
            Send-MailMessage `
                -To $AlertRecipients `
                -From "m365-security@leonardocompany.ca" `
                -Subject "🚨 ALERT: Copilot Compliance Failure - M365-SEC-018" `
                -Body $emailBody `
                -Attachments $htmlReport.FullName `
                -SmtpServer "smtp.leonardocompany.ca" `
                -Priority High
            
            Write-Host "✓ Alert sent to: $($AlertRecipients -join ', ')" -ForegroundColor Yellow
        }
        catch {
            Write-Host "✗ Failed to send alert: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    return $results
}

# Add to main monitoring script
Write-Host "`nChecking Copilot compliance..." -ForegroundColor Cyan
$copilotCompliance = Test-CopilotCompliance -AlertOnFailure
```

### Integration with ISME

Add the following section to Leonardo Company ISME:

```
═══════════════════════════════════════════════════════════════
SECURITY CONTROL: M365-SEC-018
═══════════════════════════════════════════════════════════════

Control Family: System and Communications Protection (SC)
Control Name: Microsoft Copilot Disabled
ITSG-33 Mapping: SC-7, AC-4, SC-8, CM-7, SI-4, SC-12

═══════════════════════════════════════════════════════════════
IMPLEMENTATION STATEMENT
═══════════════════════════════════════════════════════════════

Microsoft Copilot features are disabled across all Microsoft 365, 
Power Platform, and Azure environments to prevent unauthorized data 
egress to external Azure OpenAI services. This control maintains 
Protected B data residency requirements and compliance with ITSG-33 
security standards.

═══════════════════════════════════════════════════════════════
IMPLEMENTATION DETAILS
═══════════════════════════════════════════════════════════════

Component: Power Platform
• Configuration URL: https://admin.powerplatform.microsoft.com/copilot/settings
• Settings Disabled:
  - Copilot (main toggle)
  - Copilot in Power Apps
  - Copilot in Power Automate
  - Copilot in Power Pages
  - AI data analysis
  - Move data across regions (CRITICAL)
  - Bing search
  - Generative AI features
• Environment-level: Copilot disabled in all environments
• Verification: Manual quarterly, automated monthly

Component: Azure AD / Entra ID
• Service Principals: All Copilot SPs disabled
• Conditional Access: "BLOCK - Microsoft Copilot Services" policy active
• Policy State: Enabled
• Blocked App Count: 4+ (all discovered Copilot apps)
• Verification: Automated monthly

Component: Microsoft 365
• M365 Copilot: Disabled in org settings
• Licenses: 0 assigned (all removed)
• Verification: Manual quarterly

═══════════════════════════════════════════════════════════════
SECURITY RATIONALE
═══════════════════════════════════════════════════════════════

Microsoft Copilot sends user prompts, organizational metadata, and 
contextual data to Azure OpenAI services hosted outside controlled 
data boundaries. This creates unacceptable risks:

• Data Residency: Violates Canadian data residency requirements
  for Protected B information
  
• Data Egress: Creates unauthorized egress path to external AI
  services beyond organizational control
  
• NATO Classification: Incompatible with NATO classified material
  handling procedures
  
• ITSG-33 SC-7: Violates boundary protection by communicating
  with external services
  
• ITSG-33 AC-4: Creates unauthorized information flow to
  third-party AI processing
  
• ITSG-33 SC-8: Establishes uncontrolled encryption paths to
  external services

═══════════════════════════════════════════════════════════════
RELATED CONTROLS
═══════════════════════════════════════════════════════════════

• SC-7: Boundary Protection - Blocks external communication
• AC-4: Information Flow Enforcement - Prevents unauthorized egress
• SC-8: Transmission Confidentiality - Controls encryption paths
• CM-7: Least Functionality - Disables unnecessary features
• SI-4: System Monitoring - Continuous compliance verification
• SC-12: Data Location - Enforces Canadian data residency

═══════════════════════════════════════════════════════════════
VERIFICATION METHOD
═══════════════════════════════════════════════════════════════

Automated:
• Frequency: Monthly (1st of each month, 6:00 AM)
• Method: PowerShell script (99-Verify-Copilot-Disabled.ps1)
• Outputs: CSV report, HTML compliance report
• Alerting: Email notification on failure
• Storage: \\leonardocompany\compliance\M365-SEC-018\Reports\

Manual:
• Frequency: Quarterly
• Method: Direct UI verification of all settings
• Screenshots: Required for audit trail
• Storage: \\leonardocompany\compliance\M365-SEC-018\Screenshots\

═══════════════════════════════════════════════════════════════
IMPLEMENTATION DOCUMENTATION
═══════════════════════════════════════════════════════════════

Build Book: Microsoft Copilot Disable - Build Book v1.1
Location: \\leonardocompany\compliance\M365-SEC-018\BuildBook\
Scripts: \\leonardocompany\compliance\M365-SEC-018\Scripts\

═══════════════════════════════════════════════════════════════
VERIFICATION HISTORY
═══════════════════════════════════════════════════════════════

Last Verified: [DATE]
Verified By: [NAME]
Status: [PASS/FAIL/VERIFY]
Next Automated Check: [1st of next month]
Next Manual Review: [DATE + 3 months]

═══════════════════════════════════════════════════════════════
CHANGE CONTROL
═══════════════════════════════════════════════════════════════

Initial Implementation:
• Date: [IMPLEMENTATION DATE]
• Change Ticket: [TICKET NUMBER]
• Implemented By: [NAME]
• Approved By: [SECURITY LEAD NAME]

Last Update:
• Date: [UPDATE DATE]
• Change Ticket: [TICKET NUMBER]
• Updated By: [NAME]
• Reason: [REASON]

═══════════════════════════════════════════════════════════════
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Service Principal Cannot Be Disabled

**Symptom:**

```
Update-MgServicePrincipal : Insufficient privileges to complete the operation
```

**Root Cause:** Microsoft-managed service principal that cannot be directly modified.

**Solution:**

1. This is **expected behavior** for Microsoft-managed apps
2. Ensure Conditional Access policy is in place to block the app
3. Document the service principal in compliance report as "Cannot Modify - Blocked by CA"
4. No further action required
5. Verify CA policy includes this app's App ID

**Verification:**

```powershell
# Verify app is included in CA policy
$policyId = "[YOUR-CA-POLICY-ID]"
$policy = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId
$policy.Conditions.Applications.IncludeApplications
```

---

#### Issue 2: Copilot Re-appears After Updates

**Symptom:** New Copilot app registrations appear after Microsoft 365 updates or new Copilot services are released.

**Root Cause:** Microsoft may provision new Copilot infrastructure during platform updates.

**Solution:**

1. **Run discovery** to identify new apps:

   ```powershell
   .\01-Discover-CopilotApps.ps1
   ```

2. **Disable new service principals**:

   ```powershell
   .\04-Disable-Copilot-ServicePrincipals.ps1
   ```

3. **Update Conditional Access policy** with new App IDs:

   ```powershell
   .\05-Create-CA-Policy-BlockCopilot.ps1  # Choose "Update" when prompted
   ```

4. **Document in change log**
5. **Verify tenant-level settings** remain disabled

**Prevention:**

- Monthly automated compliance checks will detect this
- Alert configured to notify on new Copilot-related service principals

---

#### Issue 3: Users Report Copilot Features Appearing

**Symptom:** Users see Copilot prompts or features in M365 apps despite configuration.

**Root Cause:**

- Settings not fully propagated (can take up to 24 hours)
- User licensed for Copilot
- Feature toggle in client application
- Browser/app cache

**Solution:**

1. **Verify tenant settings:**
   - Navigate to <https://admin.powerplatform.microsoft.com/copilot/settings>
   - Confirm all toggles are OFF

2. **Check user license:**

   ```powershell
   # Check specific user
   Connect-MgGraph -Scopes "User.Read.All"
   $user = Get-MgUser -UserId "user@leonardocompany.ca"
   Get-MgUserLicenseDetail -UserId $user.Id | Where-Object {
       $_.ServicePlans.ServicePlanName -like "*Copilot*"
   }
   ```

   - Remove any Copilot licenses found

3. **Clear Office cache:**

   ```powershell
   # Run on user's machine
   Stop-Process -Name "WINWORD","EXCEL","POWERPNT","OUTLOOK" -Force -ErrorAction SilentlyContinue
   Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Office\16.0\Wef\*" -Recurse -Force
   ```

4. **Sign out and back in** to M365

5. **Verify Conditional Access** policy is enforced:
   - Check user's sign-in logs in Azure AD
   - Look for blocked sign-ins to Copilot apps

6. **Wait for propagation** (if recently configured):
   - Settings can take up to 24 hours to fully propagate
   - Environment-specific settings may require longer

**Verification:**

- [ ] Tenant settings verified
- [ ] User has no Copilot licenses
- [ ] Office cache cleared
- [ ] User signed out and back in
- [ ] CA policy enforced
- [ ] User confirms Copilot prompts gone

---

#### Issue 4: PowerShell Module Not Found

**Symptom:**

```
The term 'Get-AdminPowerAppEnvironment' is not recognized as the name of a cmdlet
```

**Root Cause:** Power Platform Admin PowerShell module not installed or outdated.

**Solution:**

```powershell
# Check current version
Get-Module Microsoft.PowerApps.Administration.PowerShell -ListAvailable

# Uninstall old version
Uninstall-Module Microsoft.PowerApps.Administration.PowerShell -AllVersions -Force

# Install latest version
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber -Scope CurrentUser

# Verify installation
Get-Module Microsoft.PowerApps.Administration.PowerShell -ListAvailable

# Import module
Import-Module Microsoft.PowerApps.Administration.PowerShell

# Test connection
Add-PowerAppsAccount
Get-AdminPowerAppEnvironment | Select-Object -First 1
```

**If installation fails:**

```powershell
# Run PowerShell as Administrator
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Update PowerShellGet
Install-Module PowerShellGet -Force -AllowClobber

# Retry module installation
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
```

---

#### Issue 5: Graph API Authentication Fails

**Symptom:**

```
Connect-MgGraph : The user or administrator has not consented to use the application
```

**Root Cause:** Insufficient permissions or consent not granted.

**Solution:**

1. **Ensure you have required role:**
   - Global Administrator, or
   - Application Administrator (for app operations)
   - Conditional Access Administrator (for CA policies)

2. **Connect with proper scopes:**

   ```powershell
   Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess"
   ```

3. **Complete admin consent** in browser when prompted

4. **If using app registration** (for automation):

   ```powershell
   # In Azure Portal
   # 1. Go to Azure AD → App registrations → Your App
   # 2. API permissions → Add:
   #    - Application.ReadWrite.All
   #    - Directory.ReadWrite.All
   #    - Policy.ReadWrite.ConditionalAccess
   # 3. Click "Grant admin consent for [tenant]"
   ```

5. **Verify connection:**

   ```powershell
   Get-MgContext
   # Should show scopes you requested
   ```

**Alternative - Use certificate authentication:**

```powershell
$tenantId = "your-tenant-id"
$clientId = "your-app-id"
$certThumbprint = "your-cert-thumbprint"

Connect-MgGraph -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $certThumbprint
```

---

#### Issue 6: Conditional Access Policy Not Blocking

**Symptom:** Users can still access Copilot despite CA policy being "Enabled".

**Root Cause:**

- Policy misconfigured
- Users excluded from policy
- App IDs incorrect or incomplete
- Policy in report-only mode

**Solution:**

1. **Verify policy configuration:**

   ```powershell
   $policy = Get-MgIdentityConditionalAccessPolicy -All | 
       Where-Object { $_.DisplayName -like "*Copilot*" }
   
   # Check state
   Write-Host "State: $($policy.State)"  # Should be "enabled"
   
   # Check target apps
   Write-Host "Target Apps: $($policy.Conditions.Applications.IncludeApplications.Count)"
   $policy.Conditions.Applications.IncludeApplications
   
   # Check users
   Write-Host "Include Users: $($policy.Conditions.Users.IncludeUsers)"  # Should be "All"
   Write-Host "Exclude Users: $($policy.Conditions.Users.ExcludeUsers)"
   ```

2. **Check sign-in logs:**

   ```powershell
   # In Azure Portal
   # Azure AD → Sign-in logs
   # Filter: Application = [Copilot App ID]
   # Look for blocked sign-ins
   ```

3. **Common fixes:**

   **If state is not "enabled":**

   ```powershell
   Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -State "enabled"
   ```

   **If users are excluded:**

   ```powershell
   # Remove user exclusions (except break-glass)
   $policy.Conditions.Users.ExcludeUsers = @()  # Or keep break-glass only
   Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -BodyParameter @{
       conditions = @{
           users = @{
               includeUsers = @("All")
               excludeUsers = @()  # Or break-glass only
           }
       }
   }
   ```

   **If app IDs missing:**

   ```powershell
   # Get all Copilot app IDs
   $copilotApps = Import-Csv ".\CopilotDiscovery_[latest].csv"
   $appIds = $copilotApps.AppId | Where-Object { $_ -and $_ -ne "N/A" }
   
   # Update policy
   Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -BodyParameter @{
       conditions = @{
           applications = @{
               includeApplications = $appIds
           }
       }
   }
   ```

4. **Test with user account:**
   - Sign in as test user (not admin)
   - Attempt to access M365 Copilot
   - Should receive access blocked message

**Verification:**

- [ ] Policy state is "enabled"
- [ ] All users included (except break-glass)
- [ ] All Copilot app IDs in policy
- [ ] Test user blocked from accessing Copilot
- [ ] Sign-in logs show blocked attempts

---

#### Issue 7: "Move data across regions" Toggle Not Visible

**Symptom:** Cannot find "Move data across regions" setting in Power Platform Copilot settings.

**Root Cause:**

- Setting may not be available in all tenants
- Depends on tenant region and Copilot licensing
- May be under different name or location

**Solution:**

1. **Check current location:**
   - URL: <https://admin.powerplatform.microsoft.com/copilot/settings>
   - Look for any data residency or region-related settings
   - May be named:
     - "Move data across regions"
     - "Cross-region data movement"
     - "Data processing outside region"

2. **If not present:**
   - This setting may not apply to Canadian tenants
   - Canadian data residency is enforced by default in some configurations
   - Document in compliance report as "Not applicable - Canadian tenant"

3. **Verify data residency:**

   ```powershell
   # Check tenant region
   Get-MgOrganization | Select-Object CountryLetterCode, PreferredDataLocation
   ```

4. **Alternative verification:**
   - Contact Microsoft Support to confirm data residency settings
   - Request written confirmation that data stays in Canada
   - Document response in compliance folder

**Documentation:**

- [ ] Screenshot showing available settings
- [ ] Note in compliance report
- [ ] Microsoft confirmation (if obtained)

---

## Rollback Procedures

### Emergency Rollback (If Required)

**⚠️ WARNING:** Rollback violates Protected B requirements. Obtain security exception approval before proceeding.

**Scenario:** Business requirement changes and Copilot must be re-enabled.

#### Step 1: Document Rollback Justification

```powershell
# Script: Rollback-CopilotDisable-Documentation.ps1

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║              COPILOT ROLLBACK DOCUMENTATION                ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Red

Write-Host "⚠️  WARNING: This rollback violates Protected B requirements" -ForegroundColor Yellow
Write-Host "Security exception approval is MANDATORY before proceeding`n" -ForegroundColor Yellow

$rollbackDoc = [PSCustomObject]@{
    RollbackDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    RequestedBy = Read-Host "Requester Name"
    RequesterRole = Read-Host "Requester Role"
    BusinessJustification = Read-Host "Business Justification (detailed)"
    SecurityExceptionNumber = Read-Host "Security Exception Number"
    SecurityLeadApproval = Read-Host "Security Lead Name (Approver)"
    RiskOfficerApproval = Read-Host "Risk Officer Name (Approver)"
    Type = Read-Host "Temporary or Permanent? (T/P)"
    RevertDate = ""
    ITSGControlsAffected = "SC-7, AC-4, SC-8, CM-7, SI-4, SC-12"
    ComplianceImpact = "Protected B data residency requirements violated"
    RiskAcceptance = "Documented in security exception"
}

if ($rollbackDoc.Type -eq "T") {
    $rollbackDoc.RevertDate = Read-Host "Scheduled Revert Date (yyyy-MM-dd)"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\CopilotRollback_$timestamp.csv"
$rollbackDoc | Export-Csv -Path $exportPath -NoTypeInformation

Write-Host "`n✓ Rollback documentation created: $exportPath" -ForegroundColor Green
Write-Host "`n⚠️  REQUIRED NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Obtain all required approvals" -ForegroundColor Gray
Write-Host "2. Update ISME with security exception" -ForegroundColor Gray
Write-Host "3. Notify Security team" -ForegroundColor Gray
Write-Host "4. Proceed with rollback only after approvals" -ForegroundColor Gray
```

#### Step 2: Re-enable Power Platform Copilot

**Manual Procedure:**

1. Navigate to: <https://admin.powerplatform.microsoft.com/copilot/settings>
2. **Enable** required Copilot features:
   - Copilot (main toggle) → ON
   - Copilot in Power Apps → ON (if needed)
   - Copilot in Power Automate → ON (if needed)
   - Copilot in Power Pages → ON (if needed)
3. **CRITICAL:** Leave "Move data across regions" → **OFF** (maintain Canadian data residency)
4. Click **Save**
5. **Document** with screenshots

#### Step 3: Re-enable Service Principals

```powershell
# Script: Rollback-Enable-ServicePrincipals.ps1

# Load disabled service principals from original disable operation
$disablePath = Get-ChildItem -Path ".\ServicePrincipalDisable_*.csv" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if (-not $disablePath) {
    Write-Host "✗ No service principal disable record found" -ForegroundColor Red
    exit 1
}

$disabledSPs = Import-Csv -Path $disablePath.FullName
$toEnable = $disabledSPs | Where-Object {$_.NewState -eq "Disabled" -and $_.Status -eq "Success"}

Write-Host "`nRe-enabling $($toEnable.Count) service principals..." -ForegroundColor Yellow

Connect-MgGraph -Scopes "Application.ReadWrite.All"

foreach ($sp in $toEnable) {
    try {
        Update-MgServicePrincipal -ServicePrincipalId $sp.ObjectId -AccountEnabled:$true
        Write-Host "✓ Re-enabled: $($sp.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error re-enabling: $($sp.DisplayName)" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Gray
    }
}
```

#### Step 4: Disable or Delete Conditional Access Policy

```powershell
# Script: Rollback-CA-Policy.ps1

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

# Find Copilot block policy
$policy = Get-MgIdentityConditionalAccessPolicy -All | 
    Where-Object { $_.DisplayName -like "*Copilot*" -and $_.DisplayName -like "*BLOCK*" }

if ($policy) {
    Write-Host "`nCopilot block policy found: $($policy.DisplayName)" -ForegroundColor Yellow
    Write-Host "Policy ID: $($policy.Id)" -ForegroundColor Gray
    
    Write-Host "`nChoose action:" -ForegroundColor Cyan
    Write-Host "1. Disable policy (recommended for temporary rollback)" -ForegroundColor Gray
    Write-Host "2. Delete policy" -ForegroundColor Gray
    $choice = Read-Host "Enter choice (1 or 2)"
    
    if ($choice -eq "1") {
        # Disable policy
        Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -State "disabled"
        Write-Host "✓ Policy disabled" -ForegroundColor Green
    }
    elseif ($choice -eq "2") {
        # Delete policy
        $confirm = Read-Host "Are you sure you want to DELETE the policy? (Y/N)"
        if ($confirm -eq "Y") {
            Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id
            Write-Host "✓ Policy deleted" -ForegroundColor Green
        }
    }
}
else {
    Write-Host "No Copilot block policy found" -ForegroundColor Gray
}
```

#### Step 5: Re-enable M365 Copilot (if licensed)

1. Navigate to: <https://admin.microsoft.com/Adminportal/Home#/Settings/Services>
2. Select **Microsoft 365 Copilot**
3. **Enable** required features
4. **Assign licenses** to approved users
5. **Document** changes

#### Step 6: Update Security Documentation

```
SECURITY EXCEPTION RECORD

Exception ID: [EXCEPTION-NUMBER]
Control Affected: M365-SEC-018 (Microsoft Copilot Disabled)
Exception Type: [Temporary / Permanent]
Granted Date: [DATE]
Expiration: [DATE if temporary]

Business Justification:
[DETAILED JUSTIFICATION]

Risk Assessment:
• Data Residency: Canadian data may be processed by Azure OpenAI services
• Data Egress: Organizational data sent to external AI services
• Compliance Impact: Violation of standard Protected B handling procedures

Mitigation Measures:
• [List any additional controls implemented]
• Enhanced monitoring of Copilot usage
• User training on data classification before using Copilot
• Periodic review of Copilot interactions

Approved By:
• Security Lead: [NAME], Date: [DATE]
• Risk Officer: [NAME], Date: [DATE]
• IT Director: [NAME], Date: [DATE]

Review Schedule:
• [If temporary: Monthly until revert]
• [If permanent: Quarterly]
```

**CRITICAL:** Any rollback must be:

- [ ] Fully documented with security exception
- [ ] Approved by Security Lead and Risk Officer
- [ ] Recorded in ISME
- [ ] Monitored with enhanced controls
- [ ] Reviewed regularly for reversion

---

## Appendices

### Appendix A: Known Copilot App IDs

| App ID | Display Name | Purpose | Can Be Disabled |
|--------|--------------|---------|-----------------|
| 0f698dd4-f011-4d23-a33e-b36416dcb1e6 | Microsoft Copilot | Main Copilot service | Via CA only |
| 4e291c71-d680-4d0e-9640-0a3358e31177 | Power Platform Advisor | Power Platform Copilot backend | Yes |
| 2e49aa60-1bd3-43b6-8ab6-03ada3d9f08b | Copilot in Power Platform | Power Platform integration | Yes |
| bb2a2e3a-c5e7-4f0a-88e0-8e01fd3fc1f4 | Copilot for Microsoft 365 | M365 Copilot integration | Via CA only |

**Note:** Microsoft may add new Copilot services. Always run discovery before disabling to ensure complete coverage.

---

### Appendix B: ITSG-33 Control Mapping

| ITSG-33 Control | Control Name | Copilot Impact | Implementation |
|-----------------|-------------|----------------|----------------|
| SC-7 | Boundary Protection | Copilot sends data to external Azure OpenAI - **BLOCKS** boundary protection | Disable Copilot to prevent external communication |
| AC-4 | Information Flow Enforcement | Copilot creates unauthorized egress path - **VIOLATES** flow enforcement | Disable Copilot to eliminate egress path |
| SC-8 | Transmission Confidentiality | Copilot uses TLS but to external services - **OUTSIDE** controlled channels | Disable Copilot to maintain controlled channels only |
| CM-7 | Least Functionality | Copilot is unnecessary for mission functions - **VIOLATES** least functionality | Disable Copilot as unnecessary feature |
| SI-4 | System Monitoring | Copilot data flows not fully monitorable - **REDUCES** monitoring effectiveness | Disable Copilot to ensure complete monitoring |
| SC-12 | Data Location | Copilot may process data outside Canada - **VIOLATES** data residency | Disable Copilot and "Move data across regions" to enforce Canadian data residency |

---

### Appendix C: Script Inventory

| Script File | Purpose | Required Permissions | Est. Runtime |
|-------------|---------|---------------------|--------------|
| 01-Discover-CopilotApps.ps1 | Identify all Copilot components | Application.Read.All, Directory.Read.All | 2-5 min |
| 02-Disable-PowerPlatform-Copilot-Tenant.ps1 | Document PP tenant settings | Power Platform Administrator | Manual |
| 03-Verify-Environment-Copilot-Settings.ps1 | Verify PP environment settings | Power Platform Administrator | 5-10 min |
| 04-Disable-Copilot-ServicePrincipals.ps1 | Disable service principals | Application.ReadWrite.All | 2-5 min |
| 05-Create-CA-Policy-BlockCopilot.ps1 | Create Conditional Access policy | Policy.ReadWrite.ConditionalAccess | 1-2 min |
| 06-Document-M365-Copilot-Settings.ps1 | Document M365 settings | N/A (documentation only) | Manual |
| 99-Verify-Copilot-Disabled.ps1 | Comprehensive compliance verification | All read permissions | 10-15 min |
| Create-ScheduledCopilotCheck.ps1 | Create monthly monitoring task | Local Administrator | 1 min |

**Total Implementation Time:** Approximately 2-3 hours (including manual steps and verification)

---

### Appendix D: Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-05 | CloudStrucc Inc. | Initial build book created |
| 1.1 | 2026-02-09 | CloudStrucc Inc. | Updated with direct Copilot settings URL (<https://admin.powerplatform.microsoft.com/copilot/settings>), improved verification scripts, added quick reference URLs appendix |

---

### Appendix E: References

- [Microsoft Power Platform Admin Documentation](https://docs.microsoft.com/power-platform/admin/)
- [Power Platform Copilot Settings Direct URL](https://admin.powerplatform.microsoft.com/copilot/settings)
- [Microsoft Graph API Reference](https://docs.microsoft.com/graph/api/overview)
- [Azure AD Conditional Access](https://docs.microsoft.com/azure/active-directory/conditional-access/)
- [ITSG-33 Security Controls](https://cyber.gc.ca/en/guidance/it-security-risk-management-lifecycle-approach-itsg-33)
- [Protected B Handling Guidelines](https://www.tpsgc-pwgsc.gc.ca/esc-src/protection-safeguarding/niveaux-levels-eng.html)
- [Canadian Data Residency Requirements](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/)

---

### Appendix F: Contact Information

**Technical Lead:**
**Email:**
**Website:**

**Security Contact:**
**Escalation:** Security Operations Manager  
**IT Support:**

---

### Appendix G: Quick Reference URLs

#### Power Platform Admin Center - Copilot Settings

**Direct URL:** <https://admin.powerplatform.microsoft.com/copilot/settings>

**What it controls:**

- Master Copilot toggle
- Copilot in Power Apps (canvas & model-driven)
- Copilot in Power Automate (flow generation)
- Copilot in Power Pages (website content)
- Generative AI features
- Cross-region data movement (**CRITICAL** for Protected B)
- Bing search integration
- AI data analysis

**Required State for Protected B:** **ALL settings OFF**

**Access Required:** Power Platform Administrator role

**Propagation Time:** Up to 24 hours for all environments

---

#### Other Important URLs

| Purpose | URL | Required Role |
|---------|-----|---------------|
| **Power Platform Environments** | <https://admin.powerplatform.microsoft.com/environments> | Power Platform Admin |
| **Azure AD Service Principals** | <https://portal.azure.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade/~/AppAppsPreview> | Application Admin |
| **Conditional Access Policies** | <https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess/ConditionalAccessBlade/~/Policies> | Conditional Access Admin |
| **M365 Copilot Settings** | <https://admin.microsoft.com/Adminportal/Home#/Settings/Services> | Global Admin |
| **M365 License Management** | <https://admin.microsoft.com/Adminportal/Home#/licenses> | License Admin |
| **Azure AD Sign-in Logs** | <https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/SignIns> | Security Reader |
| **Microsoft Graph Explorer** | <https://developer.microsoft.com/graph/graph-explorer> | N/A (testing) |

**💡 Tip:** Bookmark these URLs for quick access during compliance checks and audits.

---

### Appendix H: Compliance Checklist Summary

Use this checklist for quick verification:

#### Phase 1: Discovery

- [ ] All Copilot components discovered and documented
- [ ] CSV export generated
- [ ] Summary reviewed

#### Phase 2: Power Platform

- [ ] Tenant Copilot settings disabled (all 8 toggles)
- [ ] "Move data across regions" disabled (**CRITICAL**)
- [ ] Screenshots captured (before/after/confirmation)
- [ ] All environments verified (Copilot OFF)
- [ ] Environment screenshots captured

#### Phase 3: Azure AD

- [ ] All modifiable service principals disabled
- [ ] Microsoft-managed apps identified
- [ ] Conditional Access policy created/enabled
- [ ] Policy includes all Copilot App IDs
- [ ] Test user blocked from Copilot

#### Phase 4: M365

- [ ] M365 Copilot disabled in org settings
- [ ] All Copilot licenses removed (0 assigned)
- [ ] Screenshots captured

#### Verification

- [ ] Comprehensive verification run
- [ ] CSV and HTML reports generated
- [ ] All automated checks PASS
- [ ] Manual verifications completed
- [ ] Reports stored in compliance folder

#### Documentation

- [ ] All scripts executed
- [ ] All CSV files generated
- [ ] Screenshots stored properly
- [ ] Change tickets documented
- [ ] ISME updated
- [ ] Security team notified

#### Ongoing

- [ ] Monthly automated check scheduled
- [ ] Alert recipients configured
- [ ] Monitoring integrated with existing systems
- [ ] Quarterly manual review scheduled
