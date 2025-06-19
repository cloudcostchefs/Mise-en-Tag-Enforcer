# ================================================================
# CloudCostChefs Recipe: AWS Essential Tags Policy Deployment
# No enterprise bloat, just results in minutes
# ================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Root", "OrganizationalUnit", "Account")]
    [string]$TargetType,
    
    [Parameter(Mandatory = $true)]
    [string]$TargetId,
    
    [Parameter(Mandatory = $false)]
    [string[]]$RequiredTags = @("Environment", "Owner", "CostCenter", "Application"),
    
    [Parameter(Mandatory = $false)]
    [string]$PolicyName = "essential-tags-policy",
    
    [Parameter(Mandatory = $false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# ================================================================
# CloudCostChefs: Because life's too short for manual clicking
# ================================================================

Write-Host "🍳 CloudCostChefs AWS Essential Tags Policy Deployment" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Check if AWS CLI is installed and configured
try {
    $awsIdentity = aws sts get-caller-identity --output json 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI not configured"
    }
    $identity = $awsIdentity | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($identity.Arn)" -ForegroundColor Green
}
catch {
    Write-Error "❌ AWS CLI not configured. Run 'aws configure' first."
    exit 1
}

# Check if Organizations is enabled
try {
    $orgInfo = aws organizations describe-organization --output json 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Organizations not accessible"
    }
    $org = $orgInfo | ConvertFrom-Json
    Write-Host "✅ Organization ID: $($org.Organization.Id)" -ForegroundColor Green
}
catch {
    Write-Error "❌ AWS Organizations not accessible. Ensure you have appropriate permissions."
    exit 1
}

# Generate Tag Policy JSON
$tagPolicy = @{
    tags = @{}
}

# Add each required tag to the policy
foreach ($tag in $RequiredTags) {
    $tagPolicy.tags[$tag] = @{
        tag_key = @{
            '@@assign' = $tag
        }
        enforced_for = @{
            '@@assign' = @(
                'ec2:instance',
                'ec2:volume',
                'ec2:security-group',
                'ec2:vpc',
                'ec2:subnet',
                's3:bucket',
                'rds:db',
                'rds:cluster',
                'lambda:function',
                'ecs:service',
                'ecs:cluster',
                'eks:cluster',
                'elasticloadbalancing:loadbalancer',
                'elasticloadbalancing:targetgroup'
            )
        }
    }
    
    # Add specific validation for Environment tag
    if ($tag -eq "Environment") {
        $tagPolicy.tags[$tag].tag_value = @{
            '@@assign' = @(
                'Production',
                'Development', 
                'Test',
                'Staging'
            )
        }
    } else {
        # For other tags, allow any non-empty value
        $tagPolicy.tags[$tag].tag_value = @{
            '@@assign' = '.*'
        }
    }
}

$policyDocument = $tagPolicy | ConvertTo-Json -Depth 10

Write-Host "🎯 Target: $TargetType ($TargetId)" -ForegroundColor Yellow
Write-Host "🏷️  Required Tags: $($RequiredTags -join ', ')" -ForegroundColor Yellow
Write-Host "📍 Region: $Region" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "🔍 WHAT-IF MODE: No changes will be made" -ForegroundColor Magenta
    Write-Host "`nPolicy Document:" -ForegroundColor Gray
    Write-Host $policyDocument -ForegroundColor Gray
}

try {
    # Step 1: Create the tag policy
    Write-Host "`n📝 Creating tag policy..." -ForegroundColor Blue
    
    if ($WhatIf) {
        Write-Host "   Would create policy: $PolicyName" -ForegroundColor Gray
    } else {
        $createPolicyCmd = "aws organizations create-policy --name `"$PolicyName`" --description `"CloudCostChefs Essential Tags Policy - Enforces Environment, Owner, CostCenter, and Application tags`" --type TAG_POLICY --content '$policyDocument' --region $Region --output json"
        
        $policyResult = Invoke-Expression $createPolicyCmd
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create policy"
        }
        
        $policy = $policyResult | ConvertFrom-Json
        $policyId = $policy.Policy.PolicySummary.Id
        Write-Host "   ✅ Policy created: $policyId" -ForegroundColor Green
    }

    # Step 2: Attach the policy to the target
    Write-Host "`n🎯 Attaching policy to target..." -ForegroundColor Blue
    
    if ($WhatIf) {
        Write-Host "   Would attach policy to: $TargetType $TargetId" -ForegroundColor Gray
    } else {
        $attachPolicyCmd = "aws organizations attach-policy --policy-id $policyId --target-id $TargetId --region $Region"
        
        Invoke-Expression $attachPolicyCmd
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to attach policy"
        }
        Write-Host "   ✅ Policy attached to: $TargetId" -ForegroundColor Green
    }

    # Step 3: Enable tag policies if not already enabled
    Write-Host "`n⚙️  Ensuring tag policies are enabled..." -ForegroundColor Blue
    
    if ($WhatIf) {
        Write-Host "   Would enable tag policies for organization" -ForegroundColor Gray
    } else {
        $enableTagPoliciesCmd = "aws organizations enable-policy-type --root-id $TargetId --policy-type TAG_POLICY --region $Region 2>$null"
        Invoke-Expression $enableTagPoliciesCmd
        # Don't fail if already enabled
        Write-Host "   ✅ Tag policies enabled" -ForegroundColor Green
    }

    # Step 4: Success summary
    Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "Policy Name: $PolicyName" -ForegroundColor White
    if (-not $WhatIf) {
        Write-Host "Policy ID: $policyId" -ForegroundColor White
    }
    Write-Host "Target: $TargetType ($TargetId)" -ForegroundColor White
    Write-Host "Required Tags: $($RequiredTags -join ', ')" -ForegroundColor White
    Write-Host "Region: $Region" -ForegroundColor White
    
    if (-not $WhatIf) {
        Write-Host "`n⏰ Note: Policy enforcement may take up to 15 minutes to take effect" -ForegroundColor Yellow
        Write-Host "🔍 Check compliance: AWS Console > Organizations > Policies > Tag policies" -ForegroundColor Yellow
        Write-Host "🧪 Test with: aws ec2 run-instances (without required tags - should fail)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "❌ Deployment failed: $($_.Exception.Message)"
    Write-Host "`n🔧 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   • Verify you have Organizations admin permissions" -ForegroundColor White
    Write-Host "   • Check if the target ID (root/OU/account) is correct" -ForegroundColor White
    Write-Host "   • Ensure tag policies are supported in your region" -ForegroundColor White
    Write-Host "   • Try running with -WhatIf first to validate" -ForegroundColor White
    Write-Host "   • Verify AWS CLI is configured with appropriate credentials" -ForegroundColor White
    exit 1
}

# ================================================================
# CloudCostChefs: Your cloud costs, tamed in minutes, not months
# ================================================================
