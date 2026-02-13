# Microsoft Copilot Disable Scripts

**Version:** 1.1
**Last Updated:** February 9, 2026

## Overview

This package contains PowerShell scripts to completely disable Microsoft Copilot across Power Platform, Entra ID, and Microsoft 365 environments to maintain organizational security and data governance requirements.

## Prerequisites

### Required PowerShell Modules

```powershell
# Install required modules
Install-Module Microsoft.Graph.Authentication -Force -AllowClobber
Install-Module Microsoft.Graph.Applications -Force -AllowClobber
Install-Module Microsoft.Graph.Identity.SignIns -Force -AllowClobber
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
```

### Required Permissions

- **Power Platform Administrator** - For tenant and environment settings
- **Application Administrator** - For service principal management
- **Conditional Access Administrator** - For CA policy creation
- **Global Administrator** - For M365 settings (or specific service admin roles)

## Script Execution Order

### Step 1: Discovery

**Script:** `01-Discover-CopilotApps.ps1`**Purpose:** Identify all Copilot components in your tenant**Runtime:** 2-5 minutes**Outputs:**

- `CopilotDiscovery_[timestamp].csv`
- `CopilotDiscoverySummary_[timestamp].json`

```powershell
.\01-Discover-CopilotApps.ps1
```

### Step 2 2: Power Platform Configuration

**Script:** `02-Disable-PowerPlatform-Copilot-Tenant.ps1`**Purpose:** Document Power Platform tenant-level Copilot configuration**Runtime:** Manual**Action Required:**

1. Navigate to https://admin.powerplatform.microsoft.com/copilot/settings
2. Disable all 8 Copilot settings
3. Capture screenshots

**Outputs:** `TenantCopilotConfig_[timestamp].csv`

```powershell
.\02-Disable-PowerPlatform-Copilot-Tenant.ps1
```

**Script:** `03-Verify-Environment-Copilot-Settings.ps1`**Purpose:** Generate environment verification checklist**Runtime:** 5-10 minutes**Outputs:**

- `EnvironmentCopilotVerification_[timestamp].csv`
- `EnvironmentVerificationGuide_[timestamp].txt`

```powershell
.\03-Verify-Environment-Copilot-Settings.ps1
```

### Step 3: Entra ID Configuration

**Script:** `04-Disable-Copilot-ServicePrincipals.ps1`
**Purpose:** Disable Copilot service principals
**Runtime:** 2-5 minutes
**Outputs:** `ServicePrincipalDisable_[timestamp].csv`

```powershell
.\04-Disable-Copilot-ServicePrincipals.ps1
```

**Script:** `05-Create-CA-Policy-BlockCopilot.ps1`
**Purpose:** Create Conditional Access policy to block Copilot
**Runtime:** 1-2 minutes
**Outputs:** `CA_Policy_Copilot_[timestamp].csv`

```powershell
.\05-Create-CA-Policy-BlockCopilot.ps1
```

### Step 4: M365 Configuration

**Script:** `06-Document-M365-Copilot-Settings.ps1`**Purpose:** Document M365 Copilot configuration**Runtime:** Manual**Action Required:**

1. Navigate to M365 Admin Center
2. Disable M365 Copilot settings
3. Remove all Copilot licenses

**Outputs:** `M365_Copilot_Config_[timestamp].csv`

```powershell
.\06-Document-M365-Copilot-Settings.ps1
```

### Verification

**Script:** `99-Verify-Copilot-Disabled.ps1`**Purpose:** Comprehensive compliance verification**Runtime:** 10-15 minutes**Outputs:**

- `CopilotComplianceReport_[timestamp].csv`
- `CopilotComplianceReport_[timestamp].html`

```powershell
.\99-Verify-Copilot-Disabled.ps1
```

### Optional: Scheduled Monitoring

**Script:** `Create-ScheduledCopilotCheck.ps1`
**Purpose:** Create monthly automated compliance check
**Runtime:** 1 minute

```powershell
.\Create-ScheduledCopilotCheck.ps1
```

## Automated Monitoring with Microsoft Purview/Defender

### Option 1: Create Automation Runbook (Recommended for Daily Monitoring)

Microsoft Purview and Defender for Cloud Apps support automation through Azure Automation. You can create a runbook to execute the discovery script on a daily schedule.

#### Prerequisites

- Azure Automation Account
- Managed Identity enabled on Automation Account
- Required Graph API permissions assigned to Managed Identity

#### Step 1: Create Automation Account

1. Navigate to **Azure Portal** → **Automation Accounts**
2. Click **+ Create**
3. Configure:
   - **Resource Group:** (select or create new)
   - **Name:** `CopilotMonitoring`
   - **Region:** (your preferred region)
4. Click **Review + Create**

#### Step 2: Enable Managed Identity

1. Open your Automation Account
2. Navigate to **Account Settings** → **Identity**
3. Enable **System assigned** managed identity
4. Click **Save**
5. Note the **Object (principal) ID** for later use

#### Step 3: Assign Graph API Permissions to Managed Identity

```powershell
# Connect to Microsoft Graph as Global Administrator
Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All"

# Get the Managed Identity Service Principal
$automationAccountName = "CopilotMonitoring"
$managedIdentityObjectId = "YOUR-MANAGED-IDENTITY-OBJECT-ID"

# Microsoft Graph Application ID (constant)
$graphAppId = "00000003-0000-0000-c000-000000000000"

# Get Microsoft Graph Service Principal
$graphSP = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'"

# Required permissions
$permissions = @(
    "Application.Read.All",      # Read applications
    "Directory.Read.All"          # Read directory data
)

# Assign permissions
foreach ($permission in $permissions) {
    $appRole = $graphSP.AppRoles | Where-Object {$_.Value -eq $permission}
  
    New-MgServicePrincipalAppRoleAssignment `
        -ServicePrincipalId $managedIdentityObjectId `
        -PrincipalId $managedIdentityObjectId `
        -ResourceId $graphSP.Id `
        -AppRoleId $appRole.Id
}

Write-Host "Permissions assigned successfully" -ForegroundColor Green
```

#### Step 4: Import Required Modules

1. In Automation Account, navigate to **Shared Resources** → **Modules**
2. Click **+ Add a module**
3. Import from **Browse from gallery**
4. Search and import:
   - `Microsoft.Graph.Authentication`
   - `Microsoft.Graph.Applications`
5. Wait for modules to import (Status: Available)

#### Step 5: Create the Runbook

1. Navigate to **Process Automation** → **Runbooks**
2. Click **+ Create a runbook**
3. Configure:
   - **Name:** `Daily-Copilot-Discovery`
   - **Runbook type:** PowerShell
   - **Runtime version:** 7.2
4. Click **Create**

#### Step 6: Add Runbook Code

Paste this code into the runbook editor:

```powershell
# Daily Copilot Discovery Runbook
# Purpose: Automated daily discovery of Copilot components

# Connect using Managed Identity
Connect-MgGraph -Identity -NoWelcome

Write-Output "Connected to Microsoft Graph using Managed Identity"

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
    "0f698dd4-f011-4d23-a33e-b36416dcb1e6",
    "4e291c71-d680-4d0e-9640-0a3358e31177",
    "2e49aa60-1bd3-43b6-8ab6-03ada3d9f08b",
    "bb2a2e3a-c5e7-4f0a-88e0-8e01fd3fc1f4"
)

# Initialize results array
$discoveredApps = @()

# Search by display name
Write-Output "Searching for Copilot components..."

foreach ($keyword in $copilotKeywords) {
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
            DiscoveryDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# Search by known App IDs
foreach ($appId in $knownCopilotAppIds) {
    $sp = Get-MgServicePrincipal -Filter "appId eq '$appId'" -ErrorAction SilentlyContinue
    if ($sp) {
        $exists = $discoveredApps | Where-Object { $_.AppId -eq $sp.AppId }
        if (-not $exists) {
            $discoveredApps += [PSCustomObject]@{
                Type = "ServicePrincipal"
                DisplayName = $sp.DisplayName
                AppId = $sp.AppId
                ObjectId = $sp.Id
                AccountEnabled = $sp.AccountEnabled
                DiscoveryDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }
}

# Remove duplicates
$uniqueApps = $discoveredApps | Sort-Object -Property AppId -Unique

# Generate summary
$enabledApps = ($uniqueApps | Where-Object {$_.AccountEnabled -eq $true}).Count
$totalApps = $uniqueApps.Count

Write-Output "Discovery Complete:"
Write-Output "  Total Copilot components: $totalApps"
Write-Output "  Enabled components: $enabledApps"

# Alert if any enabled apps found
if ($enabledApps -gt 0) {
    Write-Warning "ALERT: $enabledApps enabled Copilot components detected!"
  
    $uniqueApps | Where-Object {$_.AccountEnabled -eq $true} | ForEach-Object {
        Write-Warning "  - $($_.DisplayName) ($($_.AppId))"
    }
  
    # TODO: Send alert email or create incident
    # Example: Send-MailMessage or create ServiceNow ticket
}
else {
    Write-Output "✓ No enabled Copilot components found - Compliant"
}

# Disconnect
Disconnect-MgGraph

Write-Output "Runbook execution completed"
```

#### Step 7: Save and Publish

1. Click **Save**
2. Click **Publish**
3. Confirm publication

#### Step 8: Create Schedule

1. Navigate to **Runbook** → **Schedules**
2. Click **+ Add a schedule**
3. Click **Link a schedule to your runbook**
4. Click **+ Add a schedule**
5. Configure:
   - **Name:** `Daily-Copilot-Check`
   - **Recurrence:** Recurring
   - **Recur every:** 1 Day
   - **Start time:** 6:00 AM (your timezone)
   - **Time zone:** (select your timezone)
6. Click **Create**
7. Click **OK** to link the schedule

#### Step 9: Test the Runbook

1. Navigate to **Runbook** → **Overview**
2. Click **Start**
3. Monitor **Output** tab for results
4. Verify execution completes successfully

### Option 2: Microsoft Defender for Cloud Apps Integration

For organizations using Defender for Cloud Apps, you can create custom policies to monitor Copilot activity:

1. Navigate to **Microsoft Defender Portal** (security.microsoft.com)
2. Go to **Cloud Apps** → **Policies** → **Policy management**
3. Click **Create policy** → **Activity policy**
4. Configure:
   - **Name:** Monitor Copilot Service Principal Changes
   - **Activities matching all:**
     - Activity type: Update application
     - Application: Microsoft Entra ID
   - **Apply to:** All monitored applications
   - **Alerts:** Create alert for each matching event
5. Click **Create**

### Automated Alerting

Configure email alerts for runbook failures or discoveries:

```powershell
# Add to runbook after discovery section

if ($enabledApps -gt 0) {
    # Create alert body
    $alertBody = @"
ALERT: Copilot Components Detected

Enabled Copilot components: $enabledApps
Total Copilot components: $totalApps

Enabled Components:
$($uniqueApps | Where-Object {$_.AccountEnabled -eq $true} | 
    ForEach-Object { "- $($_.DisplayName) ($($_.AppId))" } | Out-String)

Action Required:
1. Review discovered components
2. Run disable scripts if necessary
3. Investigate why components were enabled

Discovery Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    # Send email using Azure Automation Send-MailMessage
    # Or integrate with your alerting system
  
    Write-Output $alertBody
}
```

## Quick Start Guide

### Step 1: Install Prerequisites

```powershell
# Run as Administrator
Install-Module Microsoft.Graph.Authentication -Force
Install-Module Microsoft.Graph.Applications -Force
Install-Module Microsoft.Graph.Identity.SignIns -Force
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force
```

### Step 2: Execute Scripts in Order

```powershell
# Phase 1: Discovery
.\01-Discover-CopilotApps.ps1

# Phase 2: Power Platform (includes manual steps)
.\02-Disable-PowerPlatform-Copilot-Tenant.ps1
.\03-Verify-Environment-Copilot-Settings.ps1

# Phase 3: Entra ID
.\04-Disable-Copilot-ServicePrincipals.ps1
.\05-Create-CA-Policy-BlockCopilot.ps1

# Phase 4: M365 (manual steps)
.\06-Document-M365-Copilot-Settings.ps1

# Verification
.\99-Verify-Copilot-Disabled.ps1
```

### Step 3: Review Results

1. Check all CSV files for completion status
2. Review HTML compliance report
3. Ensure all screenshots captured
4. Store documentation in your compliance repository

## Important URLs

### Direct Configuration Links

| Component                       | URL                                                                                                                |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Power Platform Copilot Settings | https://admin.powerplatform.microsoft.com/copilot/settings                                                         |
| Power Platform Environments     | https://admin.powerplatform.microsoft.com/environments                                                             |
| Entra ID Service Principals     | https://portal.azure.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade/~/AppAppsPreview                  |
| Conditional Access Policies     | https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess/ConditionalAccessBlade/~/Policies                   |
| M365 Copilot Settings           | https://admin.microsoft.com/Adminportal/Home#/Settings/Services                                                    |
| Azure Automation Accounts       | https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Automation%2FautomationAccounts |

## Critical Settings

### Power Platform - ALL Must Be OFF

1. ✅ Copilot (main toggle)
2. ✅ Copilot in Power Apps
3. ✅ Copilot in Power Automate
4. ✅ Copilot in Power Pages
5. ✅ AI data analysis
6. ✅ **Move data across regions** (CRITICAL for data residency)
7. ✅ Bing search
8. ✅ Generative AI features

## Troubleshooting

### "Module not found" Error

```powershell
# Uninstall old version
Uninstall-Module Microsoft.PowerApps.Administration.PowerShell -AllVersions -Force

# Install latest
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
```

### "Insufficient privileges" Error

- Ensure you have the required admin roles
- Run: `Connect-MgGraph -Scopes "Application.ReadWrite.All"`
- Complete admin consent in browser when prompted

### Service Principals Cannot Be Disabled

- This is expected for Microsoft-managed apps
- These will be blocked by Conditional Access policy
- No further action required

### Runbook Execution Fails

- Verify Managed Identity has required Graph permissions
- Check module import status in Automation Account
- Review runbook job output for specific errors
- Ensure modules are compatible with PowerShell 7.2 runtime

## Best Practices

### Data Residency

- Always disable "Move data across regions" setting
- Verify data location settings match your requirements
- Document regional data processing requirements

### Regular Monitoring

- Run discovery script weekly or daily via automation
- Review compliance reports monthly
- Update Conditional Access policies when new Copilot apps appear
- Maintain audit logs of all configuration changes

### Change Management

- Document all changes in your change control system
- Capture before/after screenshots for audit purposes
- Test in non-production environment first
- Create rollback plan before implementation

### Security

- Use Managed Identities for automation (avoid storing credentials)
- Implement least-privilege access for service accounts
- Enable audit logging for all administrative actions
- Review sign-in logs regularly for blocked Copilot access attempts

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Microsoft 365 Tenant                      │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Power Platform                              │    │
│  │  • Copilot Settings (ALL OFF)                       │    │
│  │  • Environment Settings (ALL OFF)                   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Entra ID                                    │    │
│  │  • Service Principals (Disabled)                    │    │
│  │  • Conditional Access (Block Policy Active)         │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         M365 Apps                                   │    │
│  │  • Copilot Features (Disabled)                      │    │
│  │  • Licenses (Removed)                               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         │
         │ ✗ BLOCKED
         ▼
    Azure OpenAI Services (External)
```

## Support and Contributions

For issues, questions, or contributions:

- Review existing documentation thoroughly
- Check troubleshooting section
- Verify all prerequisites are met
- Test in non-production environment first

## License

These scripts are provided as-is for organizational use. Modify as needed for your specific requirements.

## Change Log

| Version | Date       | Changes                                                        |
| ------- | ---------- | -------------------------------------------------------------- |
| 1.0     | 2026-02-05 | Initial release                                                |
| 1.1     | 2026-02-09 | Added direct Copilot settings URL, Purview/Defender automation |

---

**Version:** 1.1
**Last Updated:** February 9, 2026
