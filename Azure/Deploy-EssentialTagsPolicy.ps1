# ================================================================
# CloudCostChefs Recipe: Essential Tags Policy Deployment
# No enterprise bloat, just results in minutes
# ================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("ManagementGroup", "Subscription")]
    [string]$Scope,
    
    [Parameter(Mandatory = $true)]
    [string]$ScopeId,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Audit", "Deny", "Disabled")]
    [string]$Effect = "Deny",
    
    [Parameter(Mandatory = $false)]
    [string[]]$RequiredTags = @("Environment", "Owner", "CostCenter", "Application"),
    
    [Parameter(Mandatory = $false)]
    [string]$AssignmentName = "essential-tags-policy",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# ================================================================
# CloudCostChefs: Because life's too short for manual clicking
# ================================================================

Write-Host "🍳 CloudCostChefs Essential Tags Policy Deployment" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check if logged into Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        throw "Not logged in"
    }
    Write-Host "✅ Logged in as: $($context.Account.Id)" -ForegroundColor Green
}
catch {
    Write-Error "❌ Not logged into Azure. Run 'Connect-AzAccount' first."
    exit 1
}

# Policy definition JSON
$policyDefinition = @{
    properties = @{
        displayName = "Require Essential Tags on Resource Groups"
        policyType = "Custom"
        mode = "All"
        description = "This policy enforces the existence of four essential tags on resource groups: Environment, Owner, CostCenter, and Application to enable proper governance and cost management."
        metadata = @{
            category = "Governance"
            description = "Resource groups must have Environment, Owner, CostCenter, and Application tags for effective cost allocation and resource management."
            non_compliance_message = "Resource group must have all required tags: Environment, Owner, CostCenter, and Application."
            version = "1.0.0"
            createdBy = "CloudCostChefs"
        }
        version = "1.0.0"
        parameters = @{
            requiredTags = @{
                type = "Array"
                metadata = @{
                    description = "Array of required tag names that must be present on all resource groups"
                    displayName = "Required Tags"
                }
                defaultValue = $RequiredTags
            }
            effect = @{
                type = "String"
                metadata = @{
                    description = "The effect determines what happens when the policy rule is evaluated to match"
                    displayName = "Effect"
                }
                allowedValues = @("Audit", "Deny", "Disabled")
                defaultValue = $Effect
            }
        }
        policyRule = @{
            if = @{
                allOf = @(
                    @{
                        equals = "Microsoft.Resources/subscriptions/resourceGroups"
                        field = "type"
                    },
                    @{
                        anyOf = @(
                            @{
                                exists = "false"
                                field = "tags['Environment']"
                            },
                            @{
                                exists = "false"
                                field = "tags['Owner']"
                            },
                            @{
                                exists = "false"
                                field = "tags['CostCenter']"
                            },
                            @{
                                exists = "false"
                                field = "tags['Application']"
                            }
                        )
                    }
                )
            }
            then = @{
                effect = "[parameters('effect')]"
            }
        }
    }
}

# Determine scope path
$scopePath = switch ($Scope) {
    "ManagementGroup" { "/providers/Microsoft.Management/managementGroups/$ScopeId" }
    "Subscription" { "/subscriptions/$ScopeId" }
}

Write-Host "🎯 Target Scope: $Scope ($ScopeId)" -ForegroundColor Yellow
Write-Host "🏷️  Required Tags: $($RequiredTags -join ', ')" -ForegroundColor Yellow
Write-Host "⚡ Effect: $Effect" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "🔍 WHAT-IF MODE: No changes will be made" -ForegroundColor Magenta
}

try {
    # Step 1: Create or update policy definition
    Write-Host "`n📝 Creating policy definition..." -ForegroundColor Blue
    
    $policyDefName = "require-essential-tags-resource-groups"
    $policyParams = @{
        Name = $policyDefName
        Policy = ($policyDefinition | ConvertTo-Json -Depth 10)
        ManagementGroupName = if ($Scope -eq "ManagementGroup") { $ScopeId } else { $null }
        SubscriptionId = if ($Scope -eq "Subscription") { $ScopeId } else { $null }
    }
    
    if ($WhatIf) {
        Write-Host "   Would create policy: $policyDefName" -ForegroundColor Gray
    } else {
        if ($Scope -eq "ManagementGroup") {
            $policyDef = New-AzPolicyDefinition @policyParams
        } else {
            $policyDef = New-AzPolicyDefinition -Name $policyDefName -Policy ($policyDefinition | ConvertTo-Json -Depth 10) -SubscriptionId $ScopeId
        }
        Write-Host "   ✅ Policy definition created: $($policyDef.Name)" -ForegroundColor Green
    }

    # Step 2: Assign the policy
    Write-Host "`n🎯 Assigning policy..." -ForegroundColor Blue
    
    $assignmentParams = @{
        requiredTags = $RequiredTags
        effect = $Effect
    }
    
    $assignParams = @{
        Name = $AssignmentName
        DisplayName = "Essential Tags Policy - CloudCostChefs"
        Description = "Enforces essential tags on resource groups for cost management and governance"
        PolicyDefinition = if (-not $WhatIf) { $policyDef } else { $null }
        Scope = $scopePath
        PolicyParameterObject = $assignmentParams
    }
    
    if ($WhatIf) {
        Write-Host "   Would assign policy: $AssignmentName to $scopePath" -ForegroundColor Gray
        Write-Host "   Parameters: $($assignmentParams | ConvertTo-Json -Compress)" -ForegroundColor Gray
    } else {
        $assignment = New-AzPolicyAssignment @assignParams
        Write-Host "   ✅ Policy assigned: $($assignment.Name)" -ForegroundColor Green
    }

    # Step 3: Success summary
    Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "Policy: require-essential-tags-resource-groups" -ForegroundColor White
    Write-Host "Assignment: $AssignmentName" -ForegroundColor White
    Write-Host "Scope: $scopePath" -ForegroundColor White
    Write-Host "Effect: $Effect" -ForegroundColor White
    Write-Host "Required Tags: $($RequiredTags -join ', ')" -ForegroundColor White
    
    if (-not $WhatIf) {
        Write-Host "`n⏰ Note: Policy evaluation may take up to 30 minutes to take effect" -ForegroundColor Yellow
        Write-Host "🔍 Check compliance: Azure Portal > Policy > Compliance" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "❌ Deployment failed: $($_.Exception.Message)"
    Write-Host "`n🔧 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   • Verify you have Policy Contributor role at the target scope" -ForegroundColor White
    Write-Host "   • Check if the management group/subscription ID is correct" -ForegroundColor White
    Write-Host "   • Try running with -WhatIf first to validate" -ForegroundColor White
    exit 1
}

# ================================================================
# CloudCostChefs: Your cloud costs, tamed in minutes, not months
# ================================================================
