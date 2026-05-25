# ===================================================================
# AWS ECS Force Deployment Script - FIXED VERSION
# ===================================================================
# This script forces ECS to redeploy with the latest task definition
# Uses correct cluster and service names
# ===================================================================

param(
    [string]$Region = "us-east-1",
    [string]$ClusterName = "marketplace-api-cluster",
    [string]$ServiceName = "marketplace-api-task-service-siq7bzxe",
    [string]$TaskFamily = "marketplace-api-task"
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  ECS Force Deployment - ShopsNSports" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cluster: $ClusterName" -ForegroundColor Gray
Write-Host "Service: $ServiceName" -ForegroundColor Gray
Write-Host "Region: $Region" -ForegroundColor Gray
Write-Host ""

# Step 1: Get current service info
Write-Host "[1/4] Checking current service status..." -ForegroundColor Yellow
try {
    $serviceInfo = aws ecs describe-services `
        --cluster $ClusterName `
        --services $ServiceName `
        --region $Region `
        --query 'services[0]' `
        --output json | ConvertFrom-Json
    
    Write-Host "  Status: $($serviceInfo.status)" -ForegroundColor Green
    Write-Host "  Running: $($serviceInfo.runningCount)/$($serviceInfo.desiredCount)" -ForegroundColor Green
    Write-Host "  Current Task Def: $($serviceInfo.taskDefinition.Split('/')[-1])" -ForegroundColor Gray
} catch {
    Write-Host "  ERROR: Failed to describe service" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Get latest task definition
Write-Host "[2/4] Getting latest task definition..." -ForegroundColor Yellow
try {
    $latestTaskDef = aws ecs list-task-definitions `
        --family-prefix $TaskFamily `
        --region $Region `
        --sort DESC `
        --max-items 1 `
        --query 'taskDefinitionArns[0]' `
        --output text
    
    $taskDefVersion = $latestTaskDef.Split('/')[-1]
    Write-Host "  Latest: $taskDefVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to get task definition" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Force update service
Write-Host "[3/4] Forcing new deployment..." -ForegroundColor Yellow
Write-Host "  This will pull the latest Docker image and restart tasks" -ForegroundColor Gray
try {
    aws ecs update-service `
        --cluster $ClusterName `
        --service $ServiceName `
        --task-definition $TaskFamily `
        --force-new-deployment `
        --region $Region | Out-Null
    
    Write-Host "  Deployment initiated successfully!" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to update service" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Wait for deployment
Write-Host "[4/4] Waiting for deployment to stabilize..." -ForegroundColor Yellow
Write-Host "  This may take 2-5 minutes..." -ForegroundColor Gray
Write-Host "  Press Ctrl+C to exit (deployment will continue in background)" -ForegroundColor Gray
Write-Host ""

$maxWaitMinutes = 10
$waitSeconds = 0
$maxWaitSeconds = $maxWaitMinutes * 60

while ($waitSeconds -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 15
    $waitSeconds += 15
    
    try {
        $serviceStatus = aws ecs describe-services `
            --cluster $ClusterName `
            --services $ServiceName `
            --region $Region `
            --query 'services[0]' `
            --output json | ConvertFrom-Json
        
        $deployments = $serviceStatus.deployments
        $runningCount = $serviceStatus.runningCount
        $desiredCount = $serviceStatus.desiredCount
        
        if ($deployments.Count -eq 1 -and $runningCount -eq $desiredCount) {
            Write-Host ""
            Write-Host "  ✅ Deployment COMPLETE!" -ForegroundColor Green
            Write-Host "  Running: $runningCount/$desiredCount tasks" -ForegroundColor Green
            Write-Host "  Task Definition: $($deployments[0].taskDefinition.Split('/')[-1])" -ForegroundColor Gray
            break
        } else {
            $primaryDeployment = $deployments | Where-Object { $_.status -eq "PRIMARY" } | Select-Object -First 1
            $rolloutState = $primaryDeployment.rolloutState
            Write-Host "  ⏳ Status: $rolloutState | Running: $runningCount/$desiredCount | Elapsed: $($waitSeconds)s" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ⚠️  Error checking status (will retry): $_" -ForegroundColor Yellow
    }
}

if ($waitSeconds -ge $maxWaitSeconds) {
    Write-Host ""
    Write-Host "  ⏱️  Timeout after $maxWaitMinutes minutes" -ForegroundColor Yellow
    Write-Host "  Deployment is still in progress. Check AWS Console for status." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Get ALB endpoint
$loadBalancer = aws ecs describe-services `
    --cluster $ClusterName `
    --services $ServiceName `
    --region $Region `
    --query 'services[0].loadBalancers[0].targetGroupArn' `
    --output text 2>$null

if ($loadBalancer) {
    # Get ALB from target group
    $albArn = aws elbv2 describe-target-groups `
        --target-group-arns $loadBalancer `
        --region $Region `
        --query 'TargetGroups[0].LoadBalancerArns[0]' `
        --output text 2>$null
    
    if ($albArn) {
        $albDns = aws elbv2 describe-load-balancers `
            --load-balancer-arns $albArn `
            --region $Region `
            --query 'LoadBalancers[0].DNSName' `
            --output text 2>$null
        
        if ($albDns) {
            Write-Host ""
            Write-Host "API Endpoint: http://$albDns" -ForegroundColor Green
            Write-Host ""
            Write-Host "Test with:" -ForegroundColor Gray
            Write-Host "  curl http://$albDns/health" -ForegroundColor Cyan
        }
    }
}

Write-Host ""
Write-Host "Deployment script completed!" -ForegroundColor Green
Write-Host ""
