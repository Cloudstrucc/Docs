# Microsoft Copilot Disable - Build Book

**Document Control**
- **Version:** 1.0
- **Date:** February 5, 2026
- **Author:** CloudStrucc Inc.
- **Classification:** Protected B
- **Organization:** Leonardo Company Canada
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
│  │  • Tenant Settings (Copilot Disabled)              │    │
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
```

**After Mitigation:**
```
User Input → Copilot (DISABLED) → ✗ No external communication
```

### Security Controls Implemented

| Control ID | Control Name | Implementation |
|------------|-------------|----------------|
| SC-7 | Boundary Protection | Block external AI service communication |
| AC-4 | Information Flow Enforcement | Prevent data egress to Azure OpenAI |
| SC-8 | Transmission Confidentiality | Eliminate uncontrolled encryption paths |
| CM-7 | Least Functionality | Disable unnecessary AI features |
| SI-4 | System Monitoring | Continuous compliance monitoring |

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

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All"

# Define search criteria
$copilotKeywords = @(
    "Copilot",
    "AI Builder",
    "Power Platform Advisor",
    "Dataverse AI",
    "Power Apps AI",
    "Power Automate AI",
    "Microsoft 365 Copilot"
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
        }
    }
}

# Search by known App IDs
Write-Host "`nSearching by known App IDs..." -ForegroundColor Yellow
foreach ($appId in $knownCopilotAppIds) {
    $sp = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
    if ($sp) {
        $discoveredApps += [PSCustomObject]@{
            Type = "ServicePrincipal (Known)"
            DisplayName = $sp.DisplayName
            AppId = $sp.AppId
            ObjectId = $sp.Id
            AccountEnabled = $sp.AccountEnabled
            PublisherName = $sp.PublisherName
            CreatedDateTime = $sp.CreatedDateTime
            SignInAudience = $sp.SignInAudience
        }
    }
}

# Remove duplicates
$uniqueApps = $discoveredApps | Sort-Object -Property AppId -Unique

# Display results
Write-Host "`n=== DISCOVERED COPILOT COMPONENTS ===" -ForegroundColor Green
Write-Host "Total unique components found: $($uniqueApps.Count)" -ForegroundColor Cyan
$uniqueApps | Format-Table Type, DisplayName, AppId, AccountEnabled -AutoSize

# Export to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = ".\CopilotDiscovery_$timestamp.csv"
$uniqueApps | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`nExported to: $exportPath" -ForegroundColor Green

# Generate summary report
$summary = @{
    TotalComponents = $uniqueApps.Count
    ServicePrincipals = ($uniqueApps | Where-Object {$_.Type -like "*ServicePrincipal*"}).Count
    AppRegistrations = ($uniqueApps | Where-Object {$_.Type -eq "AppRegistration"}).Count
    EnabledComponents = ($uniqueApps | Where-Object {$_.AccountEnabled -eq $true}).Count
    DisabledComponents = ($uniqueApps | Where-Object {$_.AccountEnabled -eq $false}).Count
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
$summary.GetEnumerator() | ForEach-Object {
    Write-Host "$($_.Key): $($_.Value)" -ForegroundColor White
}

# Return results for use in subsequent scripts
return $uniqueApps
```

**Expected Output:**
- CSV file with all discovered Copilot components
- Console summary showing counts by type
- Object array for pipeline processing

**Verification:**
- [ ] CSV file created in working directory
- [ ] All components documented
- [ ] Summary counts reviewed

---

### Phase 2: Power Platform Configuration

#### Step 2.1: Disable Copilot at Tenant Level

**Purpose:** Prevent Copilot from being enabled in any Power Platform environment.

**Procedure:**

```powershell
# Script: 02-Disable-PowerPlatform-Copilot-Tenant.ps1
# Purpose: Disable Copilot at Power Platform tenant level
# Classification: Protected B

#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

# Connect to Power Platform
Write-Host "Connecting to Power Platform..." -ForegroundColor Cyan
Add-PowerAppsAccount

# Get current tenant settings
Write-Host "`nRetrieving current tenant settings..." -ForegroundColor Yellow
try {
    # Note: Exact cmdlet may vary based on PowerShell version
    # Use web interface if cmdlet not available
    
    # Display warning
    Write-Host "`n=== MANUAL STEP REQUIRED ===" -ForegroundColor Red
    Write-Host "Due to API limitations, tenant-level Copilot settings must be configured via web UI" -ForegroundColor Yellow
    Write-Host "`nNavigate to:" -ForegroundColor Cyan
    Write-Host "https://admin.powerplatform.microsoft.com/settings/tenant" -ForegroundColor White
    Write-Host "`nPerform the following actions:" -ForegroundColor Cyan
    Write-Host "1. Navigate to 'Copilot' section" -ForegroundColor White
    Write-Host "2. Set 'Copilot in Power Apps' to OFF" -ForegroundColor White
    Write-Host "3. Set 'Copilot in Power Automate' to OFF" -ForegroundColor White
    Write-Host "4. Set 'Copilot in Power Pages' to OFF" -ForegroundColor White
    Write-Host "5. Set 'AI Builder' to OFF (optional - blocks all AI features)" -ForegroundColor White
    Write-Host "6. Click 'Save'" -ForegroundColor White
    
    # Pause for manual completion
    Read-Host "`nPress Enter after completing the above steps"
    
    Write-Host "`n✓ Tenant-level Copilot configuration completed" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Document the change
$tenantConfig = [PSCustomObject]@{
    ConfiguredBy = $env:USERNAME
    ConfiguredDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Setting = "Power Platform Tenant - Copilot Disabled"
    Method = "Manual via Admin Center"
    Status = "Completed"
}

$tenantConfig | Export-Csv -Path ".\TenantCopilotConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation
Write-Host "`nConfiguration documented" -ForegroundColor Green
```

**Manual Steps (Power Platform Admin Center):**

1. Navigate to https://admin.powerplatform.microsoft.com
2. Click **Settings** → **Tenant settings**
3. Scroll to **Copilot** section
4. Configure the following settings to **OFF**:
   - Copilot in Power Apps
   - Copilot in Power Automate  
   - Copilot in Power Pages
   - Users can enable Microsoft Copilot for their conversations
   - Generative AI features
5. Click **Save**

**Screenshot locations for documentation:**
- Tenant settings page (before)
- Tenant settings page (after)
- Save confirmation

**Verification:**
- [ ] All Copilot toggles set to OFF
- [ ] Changes saved successfully
- [ ] Screenshots captured and stored

---

#### Step 2.2: Disable Copilot for All Environments

**Purpose:** Ensure no individual environment has Copilot enabled.

**Procedure:**

```powershell
# Script: 03-Disable-PowerPlatform-Copilot-Environments.ps1
# Purpose: Disable Copilot for all Power Platform environments
# Classification: Protected B

#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

# Connect to Power Platform
Write-Host "Connecting to Power Platform..." -ForegroundColor Cyan
Add-PowerAppsAccount

# Get all environments
Write-Host "`nRetrieving all environments..." -ForegroundColor Yellow
$environments = Get-AdminPowerAppEnvironment

Write-Host "Found $($environments.Count) environments" -ForegroundColor Cyan

# Initialize results array
$results = @()

# Process each environment
Write-Host "`n=== DISABLING COPILOT FOR ALL ENVIRONMENTS ===" -ForegroundColor Cyan

foreach ($env in $environments) {
    Write-Host "`nProcessing: $($env.DisplayName)" -ForegroundColor Yellow
    Write-Host "  Environment ID: $($env.EnvironmentName)" -ForegroundColor Gray
    Write-Host "  Type: $($env.EnvironmentType)" -ForegroundColor Gray
    
    try {
        # Attempt to disable Copilot using admin cmdlet
        # Note: This cmdlet may not exist in all versions
        # Manual configuration may be required
        
        # Check if environment is managed
        $envDetails = Get-AdminPowerAppEnvironment -EnvironmentName $env.EnvironmentName
        
        # For each environment, Copilot settings are typically in Features
        # Manual step required via UI
        
        $result = [PSCustomObject]@{
            EnvironmentName = $env.DisplayName
            EnvironmentId = $env.EnvironmentName
            EnvironmentType = $env.EnvironmentType
            Status = "Manual Configuration Required"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ConfiguredBy = $env:USERNAME
        }
        
        Write-Host "  ⚠ Manual configuration required" -ForegroundColor Yellow
        Write-Host "     Navigate to: https://admin.powerplatform.microsoft.com/environments/$($env.EnvironmentName)/settings" -ForegroundColor Gray
        
    }
    catch {
        $result = [PSCustomObject]@{
            EnvironmentName = $env.DisplayName
            EnvironmentId = $env.EnvironmentName
            EnvironmentType = $env.EnvironmentType
            Status = "Error: $($_.Exception.Message)"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ConfiguredBy = $env:USERNAME
        }
        
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $results += $result
}

# Export results
$exportPath = ".\EnvironmentCopilotConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n=== Configuration report exported to: $exportPath ===" -ForegroundColor Green

# Display summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Environments: $($environments.Count)" -ForegroundColor White
Write-Host "Requires Manual Config: $($results.Count)" -ForegroundColor Yellow

# Generate manual configuration guide
$manualSteps = @"

=== MANUAL CONFIGURATION REQUIRED ===

For each environment listed below, perform the following steps:

1. Navigate to Power Platform Admin Center
2. Go to Environments → [Environment Name] → Settings
3. Click on 'Features' tab
4. Disable the following:
   - Copilot
   - Generative AI features
   - AI Builder (optional)
5. Click 'Save'

Environments requiring configuration:
$($results | ForEach-Object { "  - $($_.EnvironmentName) ($($_.EnvironmentId))`n     URL: https://admin.powerplatform.microsoft.com/environments/$($_.EnvironmentId)/settings" } | Out-String)

"@

Write-Host $manualSteps -ForegroundColor Yellow

# Save manual steps to file
$manualSteps | Out-File -FilePath ".\EnvironmentCopilot_ManualSteps.txt"
Write-Host "`nManual steps guide saved to: .\EnvironmentCopilot_ManualSteps.txt" -ForegroundColor Green
```

**Manual Steps (Per Environment):**

For each environment in the exported CSV:

1. Navigate to **Power Platform Admin Center**
2. Click **Environments** → Select environment
3. Click **Settings** → **Features**
4. Disable:
   - Copilot
   - Generative AI features
   - AI Builder credits (if not needed)
5. Click **Save**
6. Document completion in tracking spreadsheet

**Verification:**
- [ ] All environments processed
- [ ] Manual configuration completed for each
- [ ] Documentation updated

---

### Phase 3: Azure AD / Entra ID Configuration

#### Step 3.1: Disable Copilot Service Principals

**Purpose:** Prevent existing Copilot service principals from functioning.

**Procedure:**

```powershell
# Script: 04-Disable-Copilot-ServicePrincipals.ps1
# Purpose: Disable Copilot service principals in Azure AD
# Classification: Protected B

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All"

# Load discovered apps from Phase 1 or rediscover
$discoveredAppsPath = Get-ChildItem -Path ".\CopilotDiscovery_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($discoveredAppsPath) {
    Write-Host "Loading discovered apps from: $($discoveredAppsPath.Name)" -ForegroundColor Yellow
    $copilotApps = Import-Csv -Path $discoveredAppsPath.FullName
}
else {
    Write-Host "No discovery file found. Running discovery..." -ForegroundColor Yellow
    # Re-run discovery
    & ".\01-Discover-CopilotApps.ps1"
    $discoveredAppsPath = Get-ChildItem -Path ".\CopilotDiscovery_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $copilotApps = Import-Csv -Path $discoveredAppsPath.FullName
}

# Filter for service principals
$servicePrincipals = $copilotApps | Where-Object { $_.Type -like "*ServicePrincipal*" }

Write-Host "`n=== DISABLING COPILOT SERVICE PRINCIPALS ===" -ForegroundColor Cyan
Write-Host "Found $($servicePrincipals.Count) service principals to process" -ForegroundColor Yellow

$results = @()

foreach ($sp in $servicePrincipals) {
    Write-Host "`nProcessing: $($sp.DisplayName)" -ForegroundColor Yellow
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
            }
            
            Write-Host "  ✓ Successfully disabled" -ForegroundColor Green
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
            }
            
            Write-Host "  - Already disabled" -ForegroundColor Gray
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
            }
            
            Write-Host "  ⊘ Skipped (state unknown)" -ForegroundColor Yellow
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        
        # Check if this is a Microsoft-managed app that can't be modified
        if ($errorMsg -like "*insufficient privileges*" -or $errorMsg -like "*Access Denied*" -or $errorMsg -like "*Forbidden*") {
            $result = [PSCustomObject]@{
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.ObjectId
                PreviousState = $sp.AccountEnabled
                NewState = "Microsoft-Managed"
                Status = "Cannot Modify"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ProcessedBy = $env:USERNAME
                ErrorMessage = "Microsoft-managed application - cannot be disabled"
            }
            
            Write-Host "  ⚠ Cannot disable (Microsoft-managed)" -ForegroundColor Yellow
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
            }
            
            Write-Host "  ✗ Error: $errorMsg" -ForegroundColor Red
        }
    }
    
    $results += $result
}

# Export results
$exportPath = ".\ServicePrincipalDisable_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "`n=== Results exported to: $exportPath ===" -ForegroundColor Green

# Display summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
$summary = @{
    Total = $results.Count
    Success = ($results | Where-Object {$_.Status -eq "Success"}).Count
    AlreadyDisabled = ($results | Where-Object {$_.Status -eq "Already Disabled"}).Count
    MicrosoftManaged = ($results | Where-Object {$_.Status -eq "Cannot Modify"}).Count
    Failed = ($results | Where-Object {$_.Status -eq "Failed"}).Count
    Skipped = ($results | Where-Object {$_.Status -eq "Skipped"}).Count
}

$summary.GetEnumerator() | ForEach-Object {
    $color = switch ($_.Key) {
        "Success" { "Green" }
        "Failed" { "Red" }
        "MicrosoftManaged" { "Yellow" }
        default { "White" }
    }
    Write-Host "$($_.Key): $($_.Value)" -ForegroundColor $color
}

# Generate notes for Microsoft-managed apps
$microsoftManaged = $results | Where-Object {$_.Status -eq "Cannot Modify"}
if ($microsoftManaged.Count -gt 0) {
    Write-Host "`n=== MICROSOFT-MANAGED APPS (Cannot be disabled) ===" -ForegroundColor Yellow
    $microsoftManaged | ForEach-Object {
        Write-Host "  - $($_.DisplayName) ($($_.AppId))" -ForegroundColor Gray
    }
    Write-Host "`nNote: These apps are managed by Microsoft and cannot be directly disabled." -ForegroundColor Yellow
    Write-Host "They will be blocked via Conditional Access policy in the next step." -ForegroundColor Yellow
}

return $results
```

**Expected Output:**
- CSV file with disable operation results
- Summary showing success/failure counts
- List of Microsoft-managed apps that cannot be directly disabled

**Verification:**
- [ ] All modifiable service principals disabled
- [ ] Microsoft-managed apps identified
- [ ] Results documented

---

#### Step 3.2: Create Conditional Access Policy to Block Copilot

**Purpose:** Block access to Copilot applications as an additional security layer, especially for Microsoft-managed apps that cannot be directly disabled.

**Procedure:**

```powershell
# Script: 05-Create-CA-Policy-BlockCopilot.ps1
# Purpose: Create Conditional Access policy to block Copilot apps
# Classification: Protected B

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Application.Read.All"

# Load discovered Copilot apps
$discoveredAppsPath = Get-ChildItem -Path ".\CopilotDiscovery_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($discoveredAppsPath) {
    $copilotApps = Import-Csv -Path $discoveredAppsPath.FullName
    $copilotAppIds = $copilotApps | Select-Object -ExpandProperty AppId -Unique | Where-Object { $_ }
}
else {
    Write-Host "ERROR: No discovery file found. Run 01-Discover-CopilotApps.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== CREATING CONDITIONAL ACCESS POLICY ===" -ForegroundColor Cyan
Write-Host "Policy Name: BLOCK - Microsoft Copilot Services" -ForegroundColor Yellow
Write-Host "Target App IDs: $($copilotAppIds.Count)" -ForegroundColor Yellow

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
            excludeUsers = @()  # Add break-glass accounts if needed
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
        Write-Host "⚠ Policy already exists: $($existingPolicy.DisplayName)" -ForegroundColor Yellow
        Write-Host "Policy ID: $($existingPolicy.Id)" -ForegroundColor Gray
        
        $updateChoice = Read-Host "`nDo you want to update the existing policy? (Y/N)"
        if ($updateChoice -eq "Y" -or $updateChoice -eq "y") {
            Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $existingPolicy.Id -BodyParameter $policyParams
            Write-Host "✓ Policy updated successfully" -ForegroundColor Green
            $policyId = $existingPolicy.Id
        }
        else {
            Write-Host "Policy creation skipped" -ForegroundColor Yellow
            $policyId = $existingPolicy.Id
        }
    }
    else {
        # Create new policy
        Write-Host "`nCreating new Conditional Access policy..." -ForegroundColor Yellow
        $newPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $policyParams
        Write-Host "✓ Policy created successfully" -ForegroundColor Green
        Write-Host "Policy ID: $($newPolicy.Id)" -ForegroundColor Gray
        $policyId = $newPolicy.Id
    }
    
    # Document the policy
    $policyDoc = [PSCustomObject]@{
        PolicyName = $policyParams.displayName
        PolicyId = $policyId
        State = $policyParams.state
        TargetAppCount = $copilotAppIds.Count
        TargetAppIds = ($copilotAppIds -join "; ")
        CreatedBy = $env:USERNAME
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Status = "Active"
    }
    
    $exportPath = ".\CA_Policy_Copilot_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $policyDoc | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "`nPolicy documentation exported to: $exportPath" -ForegroundColor Green
    
    # Verify policy
    Write-Host "`nVerifying policy creation..." -ForegroundColor Yellow
    $verifyPolicy = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId
    
    if ($verifyPolicy.State -eq "enabled") {
        Write-Host "✓ Policy is ENABLED and active" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ Policy state: $($verifyPolicy.State)" -ForegroundColor Yellow
    }
    
    Write-Host "`n=== POLICY DETAILS ===" -ForegroundColor Cyan
    Write-Host "Name: $($verifyPolicy.DisplayName)" -ForegroundColor White
    Write-Host "ID: $($verifyPolicy.Id)" -ForegroundColor White
    Write-Host "State: $($verifyPolicy.State)" -ForegroundColor White
    Write-Host "Target Apps: $($verifyPolicy.Conditions.Applications.IncludeApplications.Count)" -ForegroundColor White
    Write-Host "Grant Control: Block" -ForegroundColor White
    
}
catch {
    Write-Host "✗ Error creating CA policy: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host "`n=== MANUAL CREATION REQUIRED ===" -ForegroundColor Yellow
    Write-Host "Create the policy manually in Azure Portal:" -ForegroundColor White
    Write-Host "1. Navigate to Azure AD → Security → Conditional Access" -ForegroundColor Gray
    Write-Host "2. Create new policy with name: BLOCK - Microsoft Copilot Services" -ForegroundColor Gray
    Write-Host "3. Under 'Cloud apps or actions', select these App IDs:" -ForegroundColor Gray
    $copilotAppIds | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    Write-Host "4. Under 'Users', select 'All users'" -ForegroundColor Gray
    Write-Host "5. Under 'Grant', select 'Block access'" -ForegroundColor Gray
    Write-Host "6. Enable the policy" -ForegroundColor Gray
    
    throw
}

Write-Host "`n✓ Conditional Access configuration completed" -ForegroundColor Green
```

**Manual Steps (if automated creation fails):**

1. Navigate to **Azure Portal** → **Azure AD** → **Security** → **Conditional Access**
2. Click **+ New policy**
3. Configure:
   - **Name:** BLOCK - Microsoft Copilot Services
   - **Users:** All users (exclude break-glass accounts if needed)
   - **Target resources:** Cloud apps → Select apps → Add App IDs from discovery CSV
   - **Grant:** Block access
   - **Enable policy:** On
4. Click **Create**

**Verification:**
- [ ] CA policy created/updated
- [ ] Policy state is "Enabled"
- [ ] All Copilot App IDs included
- [ ] Policy documented

---

### Phase 4: Microsoft 365 Copilot Settings

#### Step 4.1: Disable M365 Copilot via Admin Center

**Purpose:** Disable Microsoft 365 Copilot features (if licensed).

**Manual Procedure:**

1. Navigate to **Microsoft 365 Admin Center** (https://admin.microsoft.com)
2. Go to **Settings** → **Org settings** → **Services**
3. Select **Microsoft 365 Copilot**
4. Uncheck:
   - "Allow users to access Microsoft Copilot"
   - "Allow Copilot to access web content"
   - "Allow Copilot in Microsoft 365 apps"
5. Click **Save**

6. Navigate to **Billing** → **Licenses**
7. If Copilot licenses exist:
   - Remove license assignments from all users
   - Document license count for future reference

**Documentation:**

```powershell
# Script: 06-Document-M365-Copilot-Settings.ps1
# Purpose: Document M365 Copilot configuration
# Classification: Protected B

$m365CopilotConfig = [PSCustomObject]@{
    ConfigurationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ConfiguredBy = $env:USERNAME
    CopilotAccess = "Disabled"
    WebContentAccess = "Disabled"
    M365AppsIntegration = "Disabled"
    LicensesAssigned = 0  # Update this manually
    LicensesAvailable = 0  # Update this manually
    ConfigurationMethod = "Manual via M365 Admin Center"
    Notes = "All M365 Copilot features disabled per Protected B requirements"
}

$exportPath = ".\M365_Copilot_Config_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$m365CopilotConfig | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "M365 Copilot configuration documented: $exportPath" -ForegroundColor Green
```

**Verification:**
- [ ] M365 Copilot disabled in org settings
- [ ] All user licenses removed
- [ ] Configuration documented

---

## Verification and Testing

### Verification Script - Complete System Check

```powershell
# Script: 99-Verify-Copilot-Disabled.ps1
# Purpose: Comprehensive verification that Copilot is disabled
# Classification: Protected B

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications, Microsoft.PowerApps.Administration.PowerShell

param(
    [switch]$ExportReport = $true,
    [string]$ReportPath = ".\CopilotComplianceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     COPILOT COMPLIANCE VERIFICATION REPORT                ║" -ForegroundColor Cyan
Write-Host "║     Leonardo Company Canada - Protected B Environment     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$results = @()
$overallStatus = "PASS"

# ============================================================
# CHECK 1: Power Platform Tenant Settings
# ============================================================
Write-Host "`n[1/6] Checking Power Platform tenant settings..." -ForegroundColor Yellow

try {
    Add-PowerAppsAccount -ErrorAction SilentlyContinue | Out-Null
    
    # Note: May require manual verification due to API limitations
    $result = [PSCustomObject]@{
        CheckId = "PP-TENANT-01"
        Category = "Power Platform Tenant"
        Check = "Copilot Tenant Settings"
        Expected = "Disabled"
        Actual = "Manual Verification Required"
        Status = "VERIFY"
        Severity = "High"
        Remediation = "Verify manually in Power Platform Admin Center → Settings → Tenant Settings → Copilot"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "  ⚠ Manual verification required" -ForegroundColor Yellow
    $overallStatus = "VERIFY"
}
catch {
    $result = [PSCustomObject]@{
        CheckId = "PP-TENANT-01"
        Category = "Power Platform Tenant"
        Check = "Copilot Tenant Settings"
        Expected = "Disabled"
        Actual = "Error: $($_.Exception.Message)"
        Status = "ERROR"
        Severity = "High"
        Remediation = "Review error and verify manually"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "  ✗ Error occurred" -ForegroundColor Red
    $overallStatus = "FAIL"
}

$results += $result

# ============================================================
# CHECK 2: Power Platform Environments
# ============================================================
Write-Host "`n[2/6] Checking Power Platform environments..." -ForegroundColor Yellow

try {
    $environments = Get-AdminPowerAppEnvironment
    Write-Host "  Found $($environments.Count) environments" -ForegroundColor Gray
    
    foreach ($env in $environments) {
        # Note: Actual Copilot settings may require manual check
        $result = [PSCustomObject]@{
            CheckId = "PP-ENV-01"
            Category = "Power Platform Environment"
            Check = "$($env.DisplayName) - Copilot Settings"
            Expected = "Disabled"
            Actual = "Manual Verification Required"
            Status = "VERIFY"
            Severity = "High"
            Remediation = "Verify in environment settings: https://admin.powerplatform.microsoft.com/environments/$($env.EnvironmentName)/settings"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $results += $result
    }
    
    Write-Host "  ⚠ $($environments.Count) environments require manual verification" -ForegroundColor Yellow
}
catch {
    Write-Host "  ✗ Error checking environments: $($_.Exception.Message)" -ForegroundColor Red
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
        
        Write-Host "  ✓ No active Copilot service principals found" -ForegroundColor Green
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
        
        Write-Host "  ✗ Found $($activeSPs.Count) active service principals" -ForegroundColor Red
        $activeSPs | ForEach-Object {
            Write-Host "     - $($_.DisplayName) ($($_.AppId))" -ForegroundColor Gray
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
    
    Write-Host "  ✗ Error occurred" -ForegroundColor Red
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
    $copilotCAPolicy = $caPolicies | Where-Object { $_.DisplayName -like "*Copilot*" -and $_.DisplayName -like "*BLOCK*" }
    
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
            
            Write-Host "  ✓ Copilot block policy is active" -ForegroundColor Green
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
            
            Write-Host "  ✗ Policy exists but is not enabled" -ForegroundColor Red
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
        
        Write-Host "  ✗ No Copilot block policy found" -ForegroundColor Red
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
    
    Write-Host "  ✗ Error occurred" -ForegroundColor Red
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
    Expected = "Disabled"
    Actual = "Manual Verification Required"
    Status = "VERIFY"
    Severity = "High"
    Remediation = "Verify manually in M365 Admin Center → Settings → Org settings → Microsoft 365 Copilot"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

Write-Host "  ⚠ Manual verification required" -ForegroundColor Yellow
$results += $result

# ============================================================
# CHECK 6: Documentation Complete
# ============================================================
Write-Host "`n[6/6] Checking documentation..." -ForegroundColor Yellow

$requiredDocs = @(
    "CopilotDiscovery_*.csv",
    "ServicePrincipalDisable_*.csv",
    "CA_Policy_Copilot_*.csv"
)

$missingDocs = @()
foreach ($docPattern in $requiredDocs) {
    if (-not (Get-ChildItem -Path $docPattern -ErrorAction SilentlyContinue)) {
        $missingDocs += $docPattern
    }
}

if ($missingDocs.Count -eq 0) {
    $result = [PSCustomObject]@{
        CheckId = "DOC-01"
        Category = "Documentation"
        Check = "Required Documentation"
        Expected = "All present"
        Actual = "All present"
        Status = "PASS"
        Severity = "Medium"
        Remediation = "N/A"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Host "  ✓ All required documentation present" -ForegroundColor Green
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
    
    Write-Host "  ⚠ Missing documentation files" -ForegroundColor Yellow
}

$results += $result

# ============================================================
# GENERATE SUMMARY REPORT
# ============================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   VERIFICATION SUMMARY                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$summary = @{
    TotalChecks = $results.Count
    Passed = ($results | Where-Object {$_.Status -eq "PASS"}).Count
    Failed = ($results | Where-Object {$_.Status -eq "FAIL"}).Count
    Warnings = ($results | Where-Object {$_.Status -eq "WARN"}).Count
    RequireVerification = ($results | Where-Object {$_.Status -eq "VERIFY"}).Count
    Errors = ($results | Where-Object {$_.Status -eq "ERROR"}).Count
}

Write-Host "`nCheck Statistics:" -ForegroundColor White
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
}
elseif ($summary.RequireVerification -gt 0 -or $summary.Warnings -gt 0) {
    $overallStatus = "VERIFY"
    $statusColor = "Yellow"
}
else {
    $overallStatus = "PASS"
    $statusColor = "Green"
}

Write-Host "`nOverall Status: $overallStatus" -ForegroundColor $statusColor

# Export detailed report
if ($ExportReport) {
    $results | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Host "`nDetailed report exported to: $ReportPath" -ForegroundColor Cyan
    
    # Create human-readable report
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Copilot Compliance Report - Leonardo Company Canada</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background-color: #0078d4; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f1f1f1; }
        .pass { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        .warn { color: orange; font-weight: bold; }
        .verify { color: darkorange; font-weight: bold; }
        .error { color: darkred; font-weight: bold; }
        .summary { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .summary-item { display: inline-block; margin: 10px 20px 10px 0; }
        .classification { background-color: #d32f2f; color: white; padding: 5px 15px; border-radius: 3px; display: inline-block; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="classification">PROTECTED B</div>
    <h1>Microsoft Copilot Compliance Report</h1>
    <p><strong>Organization:</strong> Leonardo Company Canada</p>
    <p><strong>Report Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <p><strong>Generated By:</strong> $env:USERNAME</p>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <div class="summary-item">Total Checks: <strong>$($summary.TotalChecks)</strong></div>
        <div class="summary-item">Passed: <strong class="pass">$($summary.Passed)</strong></div>
        <div class="summary-item">Failed: <strong class="fail">$($summary.Failed)</strong></div>
        <div class="summary-item">Warnings: <strong class="warn">$($summary.Warnings)</strong></div>
        <div class="summary-item">Require Verification: <strong class="verify">$($summary.RequireVerification)</strong></div>
        <div class="summary-item">Errors: <strong class="error">$($summary.Errors)</strong></div>
        <div style="margin-top: 20px;">
            <strong>Overall Compliance Status:</strong> <span class="$($overallStatus.ToLower())">$overallStatus</span>
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
    
    <h2>Next Steps</h2>
    <ul>
"@

    if ($summary.Failed -gt 0) {
        $htmlReport += "<li><strong>CRITICAL:</strong> Address all FAILED checks immediately</li>"
    }
    
    if ($summary.RequireVerification -gt 0) {
        $htmlReport += "<li>Manually verify all items marked as 'VERIFY'</li>"
    }
    
    if ($summary.Warnings -gt 0) {
        $htmlReport += "<li>Review and address WARNING items</li>"
    }
    
    $htmlReport += @"
        <li>Update ISME documentation with compliance status</li>
        <li>Schedule monthly re-verification</li>
        <li>Report status to Security team</li>
    </ul>
    
    <h2>Security Controls</h2>
    <p>This report verifies implementation of the following security controls:</p>
    <ul>
        <li><strong>SC-7:</strong> Boundary Protection - Blocking external AI service communication</li>
        <li><strong>AC-4:</strong> Information Flow Enforcement - Preventing data egress to Azure OpenAI</li>
        <li><strong>SC-8:</strong> Transmission Confidentiality - Eliminating uncontrolled encryption paths</li>
        <li><strong>CM-7:</strong> Least Functionality - Disabling unnecessary AI features</li>
        <li><strong>SI-4:</strong> System Monitoring - Continuous compliance monitoring</li>
    </ul>
    
    <p style="margin-top: 40px; font-size: 0.9em; color: #666;">
        <em>This document contains Protected B information and must be handled according to Leonardo Company Canada security policies.</em>
    </p>
</body>
</html>
"@

    $htmlReportPath = $ReportPath -replace "\.csv$", ".html"
    $htmlReport | Out-File -FilePath $htmlReportPath -Encoding UTF8
    Write-Host "HTML report exported to: $htmlReportPath" -ForegroundColor Cyan
}

# Display failed/warning checks
if ($summary.Failed -gt 0) {
    Write-Host "`n❌ FAILED CHECKS:" -ForegroundColor Red
    $results | Where-Object {$_.Status -eq "FAIL"} | ForEach-Object {
        Write-Host "  [$($_.CheckId)] $($_.Check)" -ForegroundColor Red
        Write-Host "     Remediation: $($_.Remediation)" -ForegroundColor Gray
    }
}

if ($summary.RequireVerification -gt 0) {
    Write-Host "`n⚠️  MANUAL VERIFICATION REQUIRED:" -ForegroundColor Yellow
    $results | Where-Object {$_.Status -eq "VERIFY"} | ForEach-Object {
        Write-Host "  [$($_.CheckId)] $($_.Check)" -ForegroundColor Yellow
        Write-Host "     Action: $($_.Remediation)" -ForegroundColor Gray
    }
}

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Verification Complete" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

return $results
```

### Acceptance Criteria

- [ ] All automated checks show PASS status
- [ ] Manual verification items completed and documented
- [ ] No active Copilot service principals
- [ ] Conditional Access policy active and enforced
- [ ] All documentation generated
- [ ] HTML and CSV reports created
- [ ] Zero failed compliance checks

---

## Monitoring and Compliance

### Monthly Compliance Check

Create a scheduled task to run verification monthly:

```powershell
# Script: Create-ScheduledCopilotCheck.ps1
# Purpose: Create scheduled task for monthly Copilot compliance checks

$taskName = "Monthly Copilot Compliance Check"
$scriptPath = "C:\Scripts\Copilot-Disable\99-Verify-Copilot-Disabled.ps1"

# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 6am

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings -Description "Monthly compliance check for Copilot disable status"

Write-Host "✓ Scheduled task created: $taskName" -ForegroundColor Green
```

### Continuous Monitoring Script

Add to existing CloudStrucc compliance monitoring:

```powershell
# Add to existing monitoring scripts

function Test-CopilotCompliance {
    param(
        [switch]$AlertOnFailure
    )
    
    # Run verification
    $results = & ".\99-Verify-Copilot-Disabled.ps1" -ExportReport
    
    # Check for failures
    $failures = $results | Where-Object { $_.Status -in @("FAIL", "ERROR") }
    
    if ($failures.Count -gt 0 -and $AlertOnFailure) {
        # Send alert (integrate with existing alerting system)
        Send-MailMessage -To "security@leonardocompany.ca" `
            -From "compliance@leonardocompany.ca" `
            -Subject "ALERT: Copilot Compliance Failure Detected" `
            -Body "Copilot compliance check failed. $($failures.Count) issues detected. Review report immediately." `
            -Attachments (Get-ChildItem ".\CopilotComplianceReport_*.html" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    }
    
    return $results
}
```

### Integration with ISME

Add the following section to Leonardo Company ISME:

```
SECURITY CONTROL: M365-SEC-018
Control Family: System and Communications Protection (SC)
Control Name: Microsoft Copilot Disabled

Implementation Statement:
Microsoft Copilot features are disabled across all Microsoft 365, Power Platform, and Azure environments to prevent unauthorized data egress to external Azure OpenAI services. This control maintains Protected B data residency requirements and compliance with ITSG-33 security standards.

Implementation Details:
- Power Platform: Copilot disabled at tenant and environment levels
- Azure AD: Service principals disabled, Conditional Access blocking enforced
- M365: Copilot features and licenses removed
- Monitoring: Monthly automated compliance verification

Security Rationale:
Microsoft Copilot sends user prompts, organizational metadata, and contextual data to Azure OpenAI services hosted outside controlled data boundaries. This creates unacceptable risks for Protected B and NATO classified information handling.

Related Controls:
- SC-7: Boundary Protection
- AC-4: Information Flow Enforcement
- SC-8: Transmission Confidentiality
- CM-7: Least Functionality

Verification Method:
Automated monthly PowerShell compliance scan with manual quarterly audit

Last Verified: [DATE]
Verified By: [NAME]
Next Review: [DATE + 1 month]
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
1. This is expected behavior for Microsoft-managed apps
2. Ensure Conditional Access policy is in place to block the app
3. Document the service principal in compliance report
4. No further action required

---

#### Issue 2: Copilot Re-appears After Updates

**Symptom:** New Copilot app registrations appear after Microsoft 365 updates.

**Root Cause:** Microsoft may provision new Copilot infrastructure during platform updates.

**Solution:**
1. Run discovery script to identify new apps
2. Disable new service principals
3. Update Conditional Access policy with new App IDs
4. Document in change log
5. Verify tenant-level settings remain disabled

**Prevention:** 
- Monthly automated compliance checks will detect this
- Alert on new Copilot-related service principals

---

#### Issue 3: Users Report Copilot Features Appearing

**Symptom:** Users see Copilot prompts or features in M365 apps.

**Root Cause:** 
- Settings not propagated fully
- User licensed for Copilot
- Feature toggle in client app

**Solution:**
1. Verify tenant settings disabled
2. Check user license assignments - remove Copilot licenses
3. Clear user's Office cache:
   ```
   Delete: %localappdata%\Microsoft\Office\16.0\Wef\*
   ```
4. Sign out and back in to M365
5. Verify Conditional Access policy is enforced

---

#### Issue 4: PowerShell Module Not Found

**Symptom:**
```
The term 'Get-AdminPowerAppEnvironment' is not recognized
```

**Root Cause:** Power Platform Admin PowerShell module not installed or outdated.

**Solution:**
```powershell
# Uninstall old version
Uninstall-Module Microsoft.PowerApps.Administration.PowerShell -Force

# Install latest
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber

# Verify
Get-Module Microsoft.PowerApps.Administration.PowerShell -ListAvailable
```

---

#### Issue 5: Graph API Authentication Fails

**Symptom:**
```
Connect-MgGraph : The user or administrator has not consented
```

**Root Cause:** Insufficient permissions or consent not granted.

**Solution:**
1. Ensure you have Global Administrator or Application Administrator role
2. Run with proper scopes:
   ```powershell
   Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All"
   ```
3. Complete admin consent in browser when prompted
4. If using app registration, ensure API permissions granted and admin consented in Azure Portal

---

## Rollback Procedures

### Emergency Rollback (If Required)

**Scenario:** Business requirement changes and Copilot must be re-enabled.

**⚠️ WARNING:** Rollback violates Protected B requirements. Obtain security exception approval before proceeding.

#### Step 1: Document Rollback Justification

```powershell
$rollbackDoc = [PSCustomObject]@{
    RollbackDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    RequestedBy = "[NAME]"
    ApprovedBy = "[SECURITY LEAD NAME]"
    Justification = "[BUSINESS JUSTIFICATION]"
    SecurityException = "[EXCEPTION NUMBER]"
    RiskAcceptance = "[RISK OFFICER NAME]"
    TemporaryOrPermanent = "Temporary/Permanent"
    RevertDate = "[DATE IF TEMPORARY]"
}

$rollbackDoc | Export-Csv -Path ".\CopilotRollback_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation
```

#### Step 2: Re-enable Power Platform Copilot

1. Power Platform Admin Center → Settings → Tenant Settings → Copilot
2. Enable required Copilot features
3. Per environment: Settings → Features → Enable Copilot
4. Document changes

#### Step 3: Re-enable Service Principals

```powershell
# Load disabled service principals
$disabledSPs = Import-Csv -Path ".\ServicePrincipalDisable_[TIMESTAMP].csv"

Connect-MgGraph -Scopes "Application.ReadWrite.All"

foreach ($sp in $disabledSPs | Where-Object {$_.NewState -eq "Disabled"}) {
    try {
        Update-MgServicePrincipal -ServicePrincipalId $sp.ObjectId -AccountEnabled:$true
        Write-Host "✓ Re-enabled: $($sp.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error re-enabling: $($sp.DisplayName)" -ForegroundColor Red
    }
}
```

#### Step 4: Disable or Delete Conditional Access Policy

```powershell
# Option 1: Disable policy (recommended)
Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId "[POLICY-ID]" -State "disabled"

# Option 2: Delete policy
Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId "[POLICY-ID]"
```

#### Step 5: Update Security Documentation

- Update ISME with security exception
- Document risk acceptance
- Set review/revert date
- Notify security team

---

## Appendices

### Appendix A: Known Copilot App IDs

| App ID | Display Name | Purpose |
|--------|--------------|---------|
| 0f698dd4-f011-4d23-a33e-b36416dcb1e6 | Microsoft Copilot | Main Copilot service |
| 4e291c71-d680-4d0e-9640-0a3358e31177 | Power Platform Advisor | Power Platform Copilot backend |
| 2e49aa60-1bd3-43b6-8ab6-03ada3d9f08b | Copilot in Power Platform | Power Platform integration |
| bb2a2e3a-c5e7-4f0a-88e0-8e01fd3fc1f4 | Copilot for Microsoft 365 | M365 Copilot integration |

### Appendix B: ITSG-33 Control Mapping

| ITSG-33 Control | Implementation | Copilot Impact |
|-----------------|----------------|----------------|
| SC-7 | Boundary Protection | Copilot sends data to external Azure OpenAI - BLOCKS boundary protection |
| AC-4 | Information Flow Enforcement | Copilot creates unauthorized egress path - VIOLATES flow enforcement |
| SC-8 | Transmission Confidentiality | Copilot uses TLS but to external services - OUTSIDE controlled channels |
| CM-7 | Least Functionality | Copilot is unnecessary for mission functions - VIOLATES least functionality |
| SI-4 | System Monitoring | Copilot data flows not fully monitorable - REDUCES monitoring effectiveness |

### Appendix C: Script Inventory

| Script File | Purpose | Required Permissions |
|-------------|---------|---------------------|
| 01-Discover-CopilotApps.ps1 | Identify all Copilot components | Application.Read.All, Directory.Read.All |
| 02-Disable-PowerPlatform-Copilot-Tenant.ps1 | Disable PP tenant settings | Power Platform Administrator |
| 03-Disable-PowerPlatform-Copilot-Environments.ps1 | Disable PP environment settings | Power Platform Administrator |
| 04-Disable-Copilot-ServicePrincipals.ps1 | Disable service principals | Application.ReadWrite.All |
| 05-Create-CA-Policy-BlockCopilot.ps1 | Create Conditional Access policy | Policy.ReadWrite.ConditionalAccess |
| 06-Document-M365-Copilot-Settings.ps1 | Document M365 settings | N/A (documentation only) |
| 99-Verify-Copilot-Disabled.ps1 | Compliance verification | All read permissions |

### Appendix D: Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-05 | CloudStrucc Inc. | Initial build book created for Leonardo Company Canada |

### Appendix E: References

- [Microsoft Power Platform Admin Documentation](https://docs.microsoft.com/power-platform/admin/)
- [Microsoft Graph API Reference](https://docs.microsoft.com/graph/api/overview)
- [Azure AD Conditional Access](https://docs.microsoft.com/azure/active-directory/conditional-access/)
- [ITSG-33 Security Controls](https://cyber.gc.ca/en/guidance/it-security-risk-management-lifecycle-approach-itsg-33)
- [Protected B Handling](https://www.tpsgc-pwgsc.gc.ca/esc-src/protection-safeguarding/niveaux-levels-eng.html)

### Appendix F: Contact Information

**Technical Lead:** CloudStrucc Inc.  
**Security Contact:** Leonardo Company Canada Security Team  
**Escalation:** [Security Operations Manager]

---

## Document Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Technical Lead | | | |
| Security Lead | | | |
| IT Manager | | | |
| Compliance Officer | | | |

---

**END OF BUILD BOOK**

---

**Classification:** Protected B  
**Distribution:** Authorized Personnel Only  
**Review Date:** Annual  
**Next Review:** February 2027