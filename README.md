# Microsoft Copilot Disable Scripts

**Version:** 1.2  
**Last Updated:** February 13, 2026

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

## Implementation Steps

### Step 1: Power Platform & Copilot Studio Configuration (MANUAL)

**Purpose:** Disable ALL AI and Copilot features across Power Platform products to prevent app registrations and external AI service connections.

**Configuration URL:** https://admin.powerplatform.microsoft.com/copilot/settings

---

#### Section A: Power Platform Settings

Navigate to: https://admin.powerplatform.microsoft.com/copilot/settings

##### A.1: Copilot Feedback (TENANT-LEVEL)
- ☐ **Copilot feedback** → OFF
- Description: Controls whether users can submit feedback about Copilot to Microsoft

##### A.2: Generative AI Settings
- ☐ **Generative AI Settings** → Click to open → Disable ALL options
- Description: Controls usage of AI in Power Platform products

##### A.3: Preview and Experimental AI Models
- ☐ **Preview and experimental AI models** → OFF
- Description: Prevents use of experimental/preview AI models in Copilot Studio, Power Apps, and Power Automate

##### A.4: AI Prompts
- ☐ **AI prompts** → OFF
- Description: Controls whether users see prebuilt and custom prompts when using generative AI

##### A.5: External Models
Click to expand the "External models" subsection:
- ☐ **Anthropic** (PREVIEW) → OFF
  - Note: May show "Enabled in Microsoft 365 admin center" - verify disabled in M365 admin center as well
  - Description: Prevents use of Anthropic AI models in Copilot Studio

---

#### Section B: Copilot Studio Settings

All settings below are found under the **Copilot Studio** section:

##### B.1: Computer Use
- ☐ **Computer Use** → OFF
- **CRITICAL**: AI automates interactions but may cause unintended actions compromising device, data, or account security

##### B.2: Entra Agent Identity (PREVIEW)
- ☐ **Entra Agent Identity for Copilot Studio** → OFF
- Description: Prevents new Copilot Studio custom agents from using Entra Agent Identity

##### B.3: Code Generation and Execution
- ☐ **Code generation and execution in Copilot Studio** → OFF
- Description: Disables code generation and execution capabilities

##### B.4: Connected Agents (PREVIEW)
- ☐ **Connected Agents Copilot Studio** → OFF
- Description: Prevents Copilot Studio agents from invoking other agents

##### B.5: Hosted Browser (PREVIEW, TENANT-LEVEL)
- ☐ **Hosted Browser in Copilot Studio** → OFF
- **CRITICAL**: Data flows to Windows 365 outside Azure compliance boundary

##### B.6: Knowledge Sources
- ☐ **Knowledge sources for agents** → Click to open → Disable ALL knowledge source types

##### B.7: Agent Access Channels
- ☐ **Agent access channels** → Click to open → Disable ALL channels

##### B.8: Skills in Agents
- ☐ **Skills in agents** → OFF
- Description: Prevents agents from using other agents to navigate topics

##### B.9: Client Application Access Control
- ☐ **Client application access control** → Click to open → Configure to prevent data exfiltration

##### B.10: Authentication for Agents
- ☐ **Authentication for agents** → Click to open → Review and restrict access settings

##### B.11: Sharing
- ☐ **Sharing** → Click to open → Set to most restrictive settings

---

#### Section C: Power Apps Settings

All settings below are found under the **Power Apps** section:

##### C.1: AI-Generated App Descriptions (PREVIEW)
- ☐ **AI-generated app descriptions** → OFF
- Description: Prevents AI from automatically generating app descriptions

##### C.2: Copilot in Power Apps (PREVIEW, TENANT-LEVEL)
- ☐ **Copilot in Power Apps** → OFF
- Description: Disables new Copilot preview features in Power Apps

##### C.3: Maker Copilot (PREVIEW)
- ☐ **Maker Copilot** → OFF
- Description: Prevents use of Copilot to help make apps

##### C.4: AI Features Control (PREVIEW)
- ☐ **Control who can use AI features in model-driven apps** → Click to open → Restrict to NO users/groups

##### C.5: Chat Agent - M365 Copilot Chat
Expand the "Chat Agent" subsection:
- ☐ **M365 Copilot Chat** → OFF
- Description: AI chat powered by Microsoft 365 Copilot within Power Apps

##### C.6: Chat Agent in Model-Driven Apps (PREVIEW)
- ☐ **Chat agent in Model-Driven Apps** → OFF
- Description: Next-generation AI assistant for model-driven apps

---

#### Section D: Power Automate Settings

All settings below are found under the **Power Automate** section:

##### D.1: Copilot Help via Bing (PREVIEW, TENANT-LEVEL)
- ☐ **Copilot help assistance in Power Automate via Bing** → OFF
- Description: Disables Copilot assistance using Bing search

##### D.2: Copilot in Power Automate (PREVIEW, TENANT-LEVEL)
- ☐ **Copilot in Power Automate** → OFF
- Description: Disables Copilot in desktop flows for workflow automation

---

#### Section E: Power Pages Settings

All settings below are found under the **Power Pages** section:

##### E.1: Copilot in Power Pages Studio
- ☐ **Copilot in Power Pages Studio** → OFF
- Description: Prevents use of Copilot to help make sites

##### E.2: Web Agent
- ☐ **Web agent** → OFF (should already show "Turned off for all environments")
- Description: Prevents adding agents to websites

##### E.3: AI Search Summary
- ☐ **AI search summary in Power Pages** → OFF
- Description: Disables Copilot from summarizing searches

##### E.4: Summarization API
- ☐ **Summarization API in Power Pages** → OFF
- Description: Disables summarization APIs

##### E.5: AI Form Fill Assistance
- ☐ **AI form fill assistance in Power Pages** → OFF
- Description: Prevents AI from helping fill out forms

##### E.6: AI Summary List
- ☐ **AI summary list in Power Pages** → OFF
- Description: Disables Copilot from summarizing lists

---

#### Section F: Dynamics 365 Customer Service Settings

All settings below are found under the **Dynamics 365 Customer Service** section:

##### F.1: Agents (PREVIEW)
- ☐ **Agents** → OFF
- Description: Disables AI agents

##### F.2: Copilot (PREVIEW)
- ☐ **Copilot** → OFF
- Description: Disables AI-powered Copilot features

---

#### Section G: Dynamics 365 Sales Settings

All settings below are found under the **Dynamics 365 Sales** section:

##### G.1: AI Agents (PREVIEW)
- ☐ **AI Agents** → OFF
- Description: Disables AI agents (does not activate agents automatically)

##### G.2: Copilot (PREVIEW)
- ☐ **Copilot** → OFF
- Description: Disables Copilot-powered features in Dynamics 365 Sales

---

### Step 1 Completion Checklist

After disabling all settings above:

1. **Capture Screenshots:**
   - ☐ Before configuration (all sections visible)
   - ☐ After configuration for each section (all settings OFF)
   - ☐ Save confirmation messages

2. **Verify ALL Sections:**
   - ☐ Section A: Power Platform (5 settings)
   - ☐ Section B: Copilot Studio (11 settings)
   - ☐ Section C: Power Apps (6 settings)
   - ☐ Section D: Power Automate (2 settings)
   - ☐ Section E: Power Pages (6 settings)
   - ☐ Section F: Dynamics 365 Customer Service (2 settings)
   - ☐ Section G: Dynamics 365 Sales (2 settings)
   - ☐ **Total: 34 settings disabled**

3. **Save Configuration:**
   - ☐ Click Save after each section
   - ☐ Confirm all changes applied
   - ☐ Wait 24-48 hours for full propagation

4. **Store Documentation:**
   - ☐ Save all screenshots to documentation repository
   - ☐ Document change control ticket number
   - ☐ Record approver name and date

**⏱️ Propagation Time:**
- Most environments: 1-4 hours
- All environments: 24-48 hours
- Verify in Step 3 after propagation period

**Documentation Script (Optional):**
After completing the manual steps above, you can run this script to document the configuration:

```powershell
.\02-Disable-PowerPlatform-Copilot-Tenant.ps1
```

**Outputs:** `TenantCopilotConfig_[timestamp].csv`

---

### Step 2: Discovery

**Script:** `01-Discover-CopilotApps.ps1`  
**Purpose:** Identify all Copilot components in your tenant  
**Runtime:** 2-5 minutes  
**Outputs:** 
- `CopilotDiscovery_[timestamp].csv`
- `CopilotDiscoverySummary_[timestamp].json`

```powershell
.\01-Discover-CopilotApps.ps1
```

---

### Step 3: Power Platform Environment Verification

**Script:** `03-Verify-Environment-Copilot-Settings.ps1`  
**Purpose:** Generate environment verification checklist  
**Runtime:** 5-10 minutes  
**Outputs:**
- `EnvironmentCopilotVerification_[timestamp].csv`
- `EnvironmentVerificationGuide_[timestamp].txt`

```powershell
.\03-Verify-Environment-Copilot-Settings.ps1
```

**Note:** This script generates URLs for manual verification of each environment. Follow the generated guide to verify Copilot is disabled in each Power Platform environment.

---

### Step 4: Entra ID - Disable Service Principals

**Script:** `04-Disable-Copilot-ServicePrincipals.ps1`  
**Purpose:** Disable Copilot service principals  
**Runtime:** 2-5 minutes  
**Outputs:** `ServicePrincipalDisable_[timestamp].csv`

```powershell
.\04-Disable-Copilot-ServicePrincipals.ps1
```

**Note:** Some Microsoft-managed service principals cannot be directly disabled. These will be blocked by the Conditional Access policy in the next step.

---

### Step 5: Entra ID - Create Conditional Access Policy

**Script:** `05-Create-CA-Policy-BlockCopilot.ps1`  
**Purpose:** Create Conditional Access policy to block Copilot  
**Runtime:** 1-2 minutes  
**Outputs:** `CA_Policy_Copilot_[timestamp].csv`

```powershell
.\05-Create-CA-Policy-BlockCopilot.ps1
```

**What this does:**
- Creates a Conditional Access policy named "BLOCK - Microsoft Copilot Services"
- Blocks ALL Copilot applications (including Microsoft-managed apps)
- Applies to all users (except optional break-glass accounts)
- Takes effect immediately

---

### Step 6: M365 Copilot Configuration (MANUAL)

**Purpose:** Disable M365 Copilot features and remove licenses

**Configuration URL:** https://admin.microsoft.com/Adminportal/Home#/Settings/Services

#### Manual Procedure:

1. **Navigate to M365 Admin Center:** https://admin.microsoft.com

2. **Go to Settings → Org settings → Services**

3. **Select "Microsoft 365 Copilot"** (if present)

4. **Disable ALL settings:**
   - ☐ Allow users to access Microsoft Copilot
   - ☐ Allow Copilot to access web content
   - ☐ Allow Copilot in Microsoft 365 apps

5. **Click Save**

6. **License Management:**
   - Navigate to **Billing → Licenses**
   - Search for "Copilot" licenses
   - Remove ALL user assignments (target: 0 assigned)
   - Document license counts

7. **Capture Screenshots:**
   - Before configuration
   - After configuration (all settings OFF)
   - License status (0 assignments)

**Documentation Script (Optional):**
After completing the manual steps, run:

```powershell
.\06-Document-M365-Copilot-Settings.ps1
```

**Outputs:** `M365_Copilot_Config_[timestamp].csv`

---

### Step 7: Verification

**Script:** `99-Verify-Copilot-Disabled.ps1`  
**Purpose:** Comprehensive compliance verification  
**Runtime:** 10-15 minutes  
**Outputs:**
- `CopilotComplianceReport_[timestamp].csv`

```powershell
.\99-Verify-Copilot-Disabled.ps1
```

**Verification Checklist:**
- ✅ Power Platform tenant settings (34 settings - manual verification)
- ✅ No active Copilot service principals
- ✅ Conditional Access policy enabled
- ✅ M365 Copilot disabled
- ✅ All documentation generated

---

### Step 8: Scheduled Monitoring (Optional)

**Script:** `Create-ScheduledCopilotCheck.ps1`  
**Purpose:** Create monthly automated compliance check  
**Runtime:** 1 minute

```powershell
.\Create-ScheduledCopilotCheck.ps1
```

Creates a Windows scheduled task that runs the verification script monthly.

---

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

---

## Quick Start Guide

### Complete Implementation (All Steps)

```powershell
# Step 1: MANUAL - Power Platform & Copilot Studio Settings
# Navigate to: https://admin.powerplatform.microsoft.com/copilot/settings
# Disable ALL 34 settings across all sections (see Step 1 above)
# Then document:
.\02-Disable-PowerPlatform-Copilot-Tenant.ps1

# Step 2: Discovery
.\01-Discover-CopilotApps.ps1

# Step 3: Environment Verification (generates manual checklist)
.\03-Verify-Environment-Copilot-Settings.ps1

# Step 4: Disable Service Principals
.\04-Disable-Copilot-ServicePrincipals.ps1

# Step 5: Create Conditional Access Policy
.\05-Create-CA-Policy-BlockCopilot.ps1

# Step 6: MANUAL - M365 Copilot Settings
# Navigate to: https://admin.microsoft.com
# Disable M365 Copilot, remove licenses (see Step 6 above)
# Then document:
.\06-Document-M365-Copilot-Settings.ps1

# Step 7: Verification
.\99-Verify-Copilot-Disabled.ps1
```

### Review Results

1. Check all CSV files for completion status
2. Review compliance report
3. Ensure all screenshots captured
4. Store documentation in your compliance repository

---

## Important URLs

### Direct Configuration Links

| Component | URL |
|-----------|-----|
| **Power Platform Copilot Settings** | https://admin.powerplatform.microsoft.com/copilot/settings |
| Power Platform Environments | https://admin.powerplatform.microsoft.com/environments |
| Entra ID Service Principals | https://portal.azure.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade/~/AppAppsPreview |
| Conditional Access Policies | https://portal.azure.com/#view/Microsoft_AAD_ConditionalAccess/ConditionalAccessBlade/~/Policies |
| **M365 Copilot Settings** | https://admin.microsoft.com/Adminportal/Home#/Settings/Services |
| Azure Automation Accounts | https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Automation%2FautomationAccounts |

---

## Critical Settings Summary

### Total Settings to Disable: 34+

| Product Area | Settings Count | Level |
|--------------|----------------|-------|
| Power Platform | 5 | Tenant |
| Copilot Studio | 11 | Tenant/Environment |
| Power Apps | 6 | Tenant/Environment |
| Power Automate | 2 | Tenant |
| Power Pages | 6 | Environment |
| Dynamics 365 Customer Service | 2 | Environment |
| Dynamics 365 Sales | 2 | Environment |

### Most Critical Settings (Data Residency/Security)

| Setting | Location | Priority | Reason |
|---------|----------|----------|--------|
| Hosted Browser in Copilot Studio | Copilot Studio | **CRITICAL** | Data flows to Windows 365 outside compliance boundary |
| Computer Use | Copilot Studio | **CRITICAL** | May compromise device, data, or account security |
| Copilot in Power Apps | Power Apps | High | Tenant-level AI enablement |
| Copilot in Power Automate | Power Automate | High | Tenant-level automation AI |
| External Models (Anthropic) | Power Platform | High | Third-party AI model access |

---

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

### Power Platform Settings Not Saving
- Ensure you have Power Platform Administrator role
- Try different browser (Edge or Chrome recommended)
- Clear browser cache and retry
- Verify no conflicting group policies
- Some settings may require environment-level configuration

### Settings Re-Enable After Updates
- Microsoft may enable new AI features during product updates
- Run discovery script weekly/monthly to detect changes
- Update Conditional Access policy with new App IDs discovered
- Maintain change control documentation

---

## Best Practices

### Data Residency
- Always disable "Hosted Browser" and "Computer Use" settings
- Review data flow warnings on each setting
- Document regional data processing requirements
- Verify compliance boundary configurations

### Regular Monitoring
- Run discovery script weekly or daily via automation
- Review compliance reports monthly
- Update Conditional Access policies when new Copilot apps appear
- Maintain audit logs of all configuration changes
- Subscribe to Microsoft 365 Message Center for AI feature announcements

### Change Management
- Document all changes in your change control system
- Capture before/after screenshots for audit purposes
- Test in non-production environment first
- Create rollback plan before implementation
- Review settings after each major Microsoft product update

### Security
- Use Managed Identities for automation (avoid storing credentials)
- Implement least-privilege access for service accounts
- Enable audit logging for all administrative actions
- Review sign-in logs regularly for blocked Copilot access attempts
- Monitor for new Entra ID app registrations

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Microsoft 365 Tenant                      │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Power Platform (34 Settings)                │    │
│  │  • Copilot Settings (ALL OFF)                       │    │
│  │  • Copilot Studio (ALL OFF)                         │    │
│  │  • Power Apps (ALL OFF)                             │    │
│  │  • Power Automate (ALL OFF)                         │    │
│  │  • Power Pages (ALL OFF)                            │    │
│  │  • Dynamics 365 (ALL OFF)                           │    │
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
    External AI Services (Azure OpenAI, Anthropic, etc.)
```

---

## Support and Contributions

For issues, questions, or contributions:
- Review existing documentation thoroughly
- Check troubleshooting section
- Verify all prerequisites are met
- Test in non-production environment first

---

## License

These scripts are provided as-is for organizational use. Modify as needed for your specific requirements.

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
| 1.1 | 2026-02-09 | Added direct Copilot settings URL, Purview/Defender automation, detailed manual steps |
| 1.2 | 2026-02-13 | Expanded to cover ALL 34 Power Platform/Copilot Studio settings across all product areas |

---

**Version:** 1.2  
**Last Updated:** February 13, 2026