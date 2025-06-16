# 🍳 CloudCostChefs Recipe: Essential Tags Policy

**No enterprise bloat. No complex setup. Just tag enforcement that works.**

This recipe deploys an Azure Policy that enforces 4 essential tags on all resource groups:
- **Environment** (Production, Development, Test, Staging)
- **Owner** (Team or individual responsible)
- **CostCenter** (For billing allocation)
- **Application** (Workload identification)

## 🚀 Quick Start (PowerShell - Recommended)

### Prerequisites
- Azure PowerShell module installed
- Logged into Azure (`Connect-AzAccount`)
- Policy Contributor role at target scope

### 1. Download the Script
```powershell
# Download directly from GitHub or save the PowerShell script as Deploy-EssentialTagsPolicy.ps1
```

### 2. Deploy to Management Group
```powershell
# Replace 'your-mg-id' with your management group ID
./Deploy-EssentialTagsPolicy.ps1 -Scope ManagementGroup -ScopeId "your-mg-id"
```

### 3. Deploy to Subscription
```powershell
# Replace 'your-subscription-id' with your subscription ID
./Deploy-EssentialTagsPolicy.ps1 -Scope Subscription -ScopeId "your-subscription-id"
```

### 4. Test First (Recommended)
```powershell
# Dry run to see what would happen
./Deploy-EssentialTagsPolicy.ps1 -Scope Subscription -ScopeId "your-subscription-id" -WhatIf
```

### Advanced Options
```powershell
# Custom tags and audit mode
./Deploy-EssentialTagsPolicy.ps1 `
  -Scope Subscription `
  -ScopeId "your-subscription-id" `
  -Effect "Audit" `
  -RequiredTags @("Environment", "Owner", "CostCenter", "Application") `
  -AssignmentName "my-custom-policy"
```

## 🖱️ Manual Deployment (Azure Portal)

If you prefer clicking buttons (we don't judge), here's how:

### Step 1: Create Policy Definition

1. **Navigate to Azure Policy**
   - Go to Azure Portal → Search "Policy" → Select "Policy"

2. **Create Definition**
   - Click "Definitions" → "Policy definition" → "+ Policy definition"
   
3. **Fill in Details**
   - **Definition location**: Select your Management Group or Subscription
   - **Name**: `require-essential-tags-resource-groups`
   - **Display name**: `Require Essential Tags on Resource Groups`
   - **Category**: Create new → `Governance`

4. **Copy Policy Rule**
   - Copy the entire content from `essential-tags-policy.json`
   - Paste into the "Policy rule" text box
   - Click "Save"

### Step 2: Assign the Policy

1. **Create Assignment**
   - Go to "Assignments" → "+ Assign policy"

2. **Assignment Details**
   - **Scope**: Select your Management Group or Subscription
   - **Policy definition**: Search for "Require Essential Tags on Resource Groups"
   - **Assignment name**: `essential-tags-policy`

3. **Configure Parameters**
   - **Effect**: Choose "Deny" (or "Audit" for testing)
   - **Required Tags**: Leave default or customize

4. **Review and Create**
   - Click "Review + create" → "Create"

## 🎯 What This Does

### ✅ **ALLOWS** (Compliant Resource Groups)
```bash
# Resource group with all required tags
az group create \
  --name "myapp-prod-rg" \
  --location "eastus" \
  --tags Environment=Production Owner=platform-team CostCenter=engineering Application=web-app
```

### ❌ **BLOCKS** (Non-Compliant Resource Groups)
```bash
# Missing tags - will be denied
az group create \
  --name "random-rg" \
  --location "eastus"
  # ERROR: Resource group must have all required tags
```

## 🔧 Customization

### Change Required Tags
Edit the `requiredTags` parameter in the script:
```powershell
-RequiredTags @("Environment", "Owner", "CostCenter", "Application")
```

### Audit Mode (Non-Blocking)
Start with audit mode to see compliance without blocking:
```powershell
-Effect "Audit"
```

### Different Enforcement Levels
- **Deny**: Block non-compliant resources (recommended)
- **Audit**: Report violations but allow creation
- **Disabled**: Turn off the policy

## 📊 Monitoring Compliance

### PowerShell
```powershell
# Check policy compliance
Get-AzPolicyState | Where-Object {$_.PolicyDefinitionName -eq "require-essential-tags-resource-groups"}
```

### Azure Portal
1. Go to **Azure Policy** → **Compliance**
2. Find your "Essential Tags Policy" assignment
3. View compliant vs non-compliant resources

## 🔍 Troubleshooting

### Common Issues

**"Access Denied"**
- Ensure you have Policy Contributor role
- Check if targeting the right Management Group/Subscription

**"Policy not taking effect"**
- Wait up to 30 minutes for evaluation cycle
- Try creating a test resource group

**"Tags not being enforced on resources"**
- This policy only enforces tags on Resource Groups
- Resources inherit tags from Resource Groups (enable tag inheritance)

### Quick Fixes
```powershell
# Check your permissions
Get-AzRoleAssignment | Where-Object {$_.SignInName -eq (Get-AzContext).Account.Id}

# Validate policy assignment
Get-AzPolicyAssignment -Name "essential-tags-policy"

# Force policy evaluation (if needed)
Start-AzPolicyComplianceScan
```

## 🎉 Success Metrics

After deployment, you should see:
- ✅ 100% of new resource groups have required tags
- ✅ Clear cost allocation in Azure Cost Management
- ✅ Easy resource identification and ownership
- ✅ Improved governance and compliance scores

## 🛠️ Next Steps

1. **Enable Tag Inheritance**: Apply resource group tags to child resources
2. **Set up Cost Allocation**: Use tags in Azure Cost Management
3. **Automate Tag Application**: Use Infrastructure as Code (Terraform/ARM)
4. **Create Tag Policies for Resources**: Extend beyond resource groups

---

## 🍳 CloudCostChefs Philosophy

**We believe cloud cost optimization should be:**
- ⚡ **Fast**: Deploy in minutes, not months
- 🎯 **Practical**: Real solutions for real problems
- 🔧 **Engineer-friendly**: Code over clicks
- 💰 **Immediately valuable**: See results on day one

---

**Questions? Issues?** 
Open an issue or contribute at [CloudCostChefs GitHub](https://github.com/cloudcostchefs)

*Happy tagging! 🏷️*
