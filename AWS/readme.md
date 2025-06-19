# 🍳 CloudCostChefs Recipe: AWS Essential Tags Policy

**No enterprise bloat. No complex setup. Just tag enforcement that works.**

This recipe deploys an AWS Tag Policy that enforces 4 essential tags on all AWS resources:
- **Environment** (Production, Development, Test, Staging)
- **Owner** (Team or individual responsible)
- **CostCenter** (For billing allocation)
- **Application** (Workload identification)

## 🚀 Quick Start (PowerShell - Recommended)

### Prerequisites
- AWS CLI installed and configured
- AWS Organizations admin permissions
- PowerShell 5.1 or later

### 1. Download the Script
```powershell
# Download directly from GitHub or save the PowerShell script as Deploy-EssentialTagsPolicy.ps1
```

### 2. Deploy to Organization Root
```powershell
# Replace 'r-xxxxxxxxxx' with your organization root ID
./Deploy-EssentialTagsPolicy.ps1 -TargetType Root -TargetId "r-xxxxxxxxxx"
```

### 3. Deploy to Organizational Unit
```powershell
# Replace 'ou-xxxxxxxxxx' with your OU ID
./Deploy-EssentialTagsPolicy.ps1 -TargetType OrganizationalUnit -TargetId "ou-xxxxxxxxxx"
```

### 4. Deploy to Specific Account
```powershell
# Replace '123456789012' with your account ID
./Deploy-EssentialTagsPolicy.ps1 -TargetType Account -TargetId "123456789012"
```

### 5. Test First (Recommended)
```powershell
# Dry run to see what would happen
./Deploy-EssentialTagsPolicy.ps1 -TargetType Root -TargetId "r-xxxxxxxxxx" -WhatIf
```

### Advanced Options
```powershell
# Custom tags and policy name
./Deploy-EssentialTagsPolicy.ps1 `
  -TargetType OrganizationalUnit `
  -TargetId "ou-xxxxxxxxxx" `
  -RequiredTags @("Environment", "Owner", "CostCenter", "Application") `
  -PolicyName "my-custom-tag-policy" `
  -Region "us-west-2"
```

## 🖱️ Manual Deployment (AWS Console)

If you prefer clicking buttons (we don't judge), here's how:

### Step 1: Enable Tag Policies

1. **Navigate to AWS Organizations**
   - Go to AWS Console → Search "Organizations" → Select "AWS Organizations"

2. **Enable Tag Policies**
   - Click "Policies" → "Tag policies" → "Enable tag policies"
   - If already enabled, you'll see existing policies

### Step 2: Create Tag Policy

1. **Create Policy**
   - Click "Create policy"
   - **Policy name**: `essential-tags-policy`
   - **Description**: `CloudCostChefs Essential Tags Policy - Enforces Environment, Owner, CostCenter, and Application tags`

2. **Add Policy Content**
   - Copy the entire content from `essential-tags-policy.json`
   - Paste into the "Policy content" text box
   - Click "Create policy"

### Step 3: Attach Policy

1. **Select Target**
   - Choose Root, Organizational Unit, or Account
   - Click "Attach" next to your new policy

2. **Confirm Attachment**
   - Review the target scope
   - Click "Attach policy"

## 🎯 What This Does

### ✅ **ALLOWS** (Compliant Resources)
```bash
# EC2 instance with all required tags
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Environment,Value=Production},{Key=Owner,Value=platform-team},{Key=CostCenter,Value=engineering},{Key=Application,Value=web-app}]'
```

### ❌ **BLOCKS** (Non-Compliant Resources)
```bash
# Missing tags - will be denied
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro
# ERROR: Resource does not comply with tag policy
```

## 🔧 Resource Coverage

This policy enforces tags on:
- **EC2**: Instances, Volumes, Security Groups, VPCs, Subnets
- **S3**: Buckets
- **RDS**: Databases, Clusters  
- **Lambda**: Functions
- **ECS**: Services, Clusters
- **EKS**: Clusters
- **Load Balancers**: ALB, NLB, Target Groups

## 📋 Customization

### Change Required Tags
Edit the `RequiredTags` parameter in the script:
```powershell
-RequiredTags @("Environment", "Owner", "CostCenter", "Application")
```

### Add More Resource Types
Edit the `enforced_for` section in the JSON:
```json
"enforced_for": {
  "@@assign": [
    "ec2:instance",
    "s3:bucket",
    "your-service:resource-type"
  ]
}
```

### Modify Environment Values
Edit the Environment tag values:
```json
"Environment": {
  "tag_value": {
    "@@assign": [
      "Production",
      "Development",
      "Test",
      "Staging",
      "QA"
    ]
  }
}
```

## 📊 Monitoring Compliance

### AWS CLI
```bash
# List all tag policies
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# Check policy compliance
aws organizations list-policy-targets-for-policy --policy-id p-xxxxxxxxxx

# Get policy details
aws organizations describe-policy --policy-id p-xxxxxxxxxx
```

### AWS Console
1. Go to **AWS Organizations** → **Policies** → **Tag policies**
2. Select your "essential-tags-policy"
3. View attached targets and compliance status

## 🔍 Troubleshooting

### Common Issues

**"Access Denied"**
- Ensure you have Organizations admin permissions
- Check if you're using the management account

**"Tag policies not supported"**
- Verify you're in a supported region
- Check if Organizations is properly set up

**"Policy not enforcing"**
- Wait up to 15 minutes for propagation
- Test with a simple resource creation

### Quick Fixes
```bash
# Check your AWS identity
aws sts get-caller-identity

# Verify Organizations access
aws organizations describe-organization

# List existing policies
aws organizations list-policies --filter TAG_POLICY

# Check if tag policies are enabled
aws organizations list-roots
```

## 🧪 Testing Your Policy

### Test Script
```bash
#!/bin/bash
# Test tag policy enforcement

echo "Testing compliant resource creation..."
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Environment,Value=Test},{Key=Owner,Value=test-user},{Key=CostCenter,Value=engineering},{Key=Application,Value=test-app}]' \
  --dry-run

echo "Testing non-compliant resource creation..."
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --dry-run
```

## 🎉 Success Metrics

After deployment, you should see:
- ✅ 100% of new resources have required tags
- ✅ Clear cost allocation in AWS Cost Explorer
- ✅ Easy resource identification and ownership
- ✅ Improved compliance posture

## 🛠️ Next Steps

1. **Set up Cost Allocation Tags**: Enable tags in AWS Billing console
2. **Create Cost Reports**: Use tags in AWS Cost Explorer
3. **Automate Tag Application**: Use Infrastructure as Code (Terraform/CloudFormation)
4. **Monitor Compliance**: Set up AWS Config rules for ongoing validation

## 📚 Related AWS Services

- **AWS Config**: Monitor ongoing compliance
- **AWS Cost Explorer**: Analyze costs by tags
- **AWS Resource Groups**: Organize resources by tags
- **AWS Systems Manager**: Bulk tag management

## ⚠️ Important Notes

- Tag policies only work with AWS Organizations
- Policies apply to new resources, not existing ones
- Some AWS services may have delayed tag policy support
- Tag policies are case-sensitive

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
