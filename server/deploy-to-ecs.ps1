# ===================================================================
# ShopsNSports Server - ECS Deployment Script
# ===================================================================
# Deploys the Node.js server from c:\projects\shopsnports\server to ECS
# ===================================================================

param(
    [switch]$SkipBuild,
    [switch]$SkipPush
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host "        SHOPSNPORTS SERVER - ECS DEPLOYMENT               " -ForegroundColor Cyan
Write-Host "=============================================================`n" -ForegroundColor Cyan

# Configuration
$AWS_REGION = "us-east-1"
$AWS_ACCOUNT_ID = "119495459751"
$ECR_REPO = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/marketplace-api"
$ECS_CLUSTER = "marketplace-api-cluster"
$ECS_SERVICE = "marketplace-api-task-service-siq7bzxe"
$IMAGE_TAG = "latest"

# Change to server directory
$serverDir = "c:\projects\shopsnports\server"
if (-not (Test-Path $serverDir)) {
    Write-Host "ERROR: Server directory not found: $serverDir" -ForegroundColor Red
    exit 1
}

Write-Host "`nWorking directory: $serverDir" -ForegroundColor Cyan
Set-Location $serverDir

# Verify Dockerfile exists
if (-not (Test-Path ".\Dockerfile")) {
    Write-Host "ERROR: Dockerfile not found in $serverDir" -ForegroundColor Red
    exit 1
}

# ============================================================================
# STEP 1: Build Docker Image
# ============================================================================
if (-not $SkipBuild) {
    Write-Host "`nSTEP 1/4: Building Docker image..." -ForegroundColor Yellow
    Write-Host "   Image: marketplace-api:$IMAGE_TAG" -ForegroundColor White
    
    docker build -t marketplace-api:$IMAGE_TAG .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Docker build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Done: Docker image built successfully" -ForegroundColor Green
} else {
    Write-Host "`nSTEP 1/4: Skipping Docker build" -ForegroundColor Yellow
}

# ============================================================================
# STEP 2: Login to ECR
# ============================================================================
Write-Host "`nSTEP 2/4: Logging into AWS ECR..." -ForegroundColor Yellow

try {
    $ecrPassword = aws ecr get-login-password --region $AWS_REGION
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get ECR password"
    }
    
    $ecrPassword | docker login --username AWS --password-stdin $ECR_REPO 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to login to ECR"
    }
    
    Write-Host "Done: ECR login successful" -ForegroundColor Green
} catch {
    Write-Host "ERROR: ECR login failed: $_" -ForegroundColor Red
    Write-Host "   Make sure AWS CLI is configured with valid credentials" -ForegroundColor Yellow
    exit 1
}

# ============================================================================
# STEP 3: Tag and Push to ECR
# ============================================================================
if (-not $SkipPush) {
    Write-Host "`nSTEP 3/4: Pushing image to ECR..." -ForegroundColor Yellow
    Write-Host "   Repository: $ECR_REPO" -ForegroundColor White
    
    # Tag image
    docker tag marketplace-api:$IMAGE_TAG ${ECR_REPO}:$IMAGE_TAG
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Docker tag failed!" -ForegroundColor Red
        exit 1
    }
    
    # Push image
    Write-Host "   Pushing (this may take 1-3 minutes)..." -ForegroundColor White
    docker push ${ECR_REPO}:$IMAGE_TAG
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Docker push failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Done: Image pushed to ECR successfully" -ForegroundColor Green
} else {
    Write-Host "`nSTEP 3/4: Skipping ECR push" -ForegroundColor Yellow
}

# ============================================================================
# STEP 4: Deploy to ECS
# ============================================================================
Write-Host "`nSTEP 4/4: Deploying to ECS..." -ForegroundColor Yellow
Write-Host "   Cluster: $ECS_CLUSTER" -ForegroundColor White
Write-Host "   Service: $ECS_SERVICE" -ForegroundColor White

try {
    # Force new deployment
    aws ecs update-service `
        --cluster $ECS_CLUSTER `
        --service $ECS_SERVICE `
        --force-new-deployment `
        --region $AWS_REGION `
        --output json | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to update ECS service"
    }
    
    Write-Host "Done: ECS deployment initiated" -ForegroundColor Green
    
    # Wait for deployment to stabilize
    Write-Host "`nWaiting for deployment to stabilize (60 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    
    # Check service status
    Write-Host "`nChecking deployment status..." -ForegroundColor Cyan
    $serviceInfo = aws ecs describe-services `
        --cluster $ECS_CLUSTER `
        --services $ECS_SERVICE `
        --region $AWS_REGION `
        --output json | ConvertFrom-Json
    
    $service = $serviceInfo.services[0]
    $deployment = $service.deployments[0]
    
    Write-Host "`nService Status:" -ForegroundColor Cyan
    Write-Host "   Status: $($service.status)" -ForegroundColor $(if($service.status -eq "ACTIVE"){"Green"}else{"Yellow"})
    Write-Host "   Running Tasks: $($deployment.runningCount)/$($deployment.desiredCount)" -ForegroundColor $(if($deployment.runningCount -eq $deployment.desiredCount){"Green"}else{"Yellow"})
    Write-Host "   Deployment Status: $($deployment.rolloutState)" -ForegroundColor Cyan
    
} catch {
    Write-Host "ERROR: ECS deployment failed: $_" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Test API Endpoint
# ============================================================================
Write-Host "`nTesting API endpoint..." -ForegroundColor Yellow
$apiUrl = "http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com"

try {
    $healthResponse = Invoke-RestMethod -Uri "$apiUrl/health" -Method Get -TimeoutSec 10
    Write-Host "Done: API Health Check: OK" -ForegroundColor Green
    Write-Host "   Environment: $($healthResponse.environment)" -ForegroundColor White
    Write-Host "   Timestamp: $($healthResponse.timestamp)" -ForegroundColor White
} catch {
    Write-Host "Warning: API not responding yet (may take 1-2 minutes)" -ForegroundColor Yellow
    Write-Host "   URL: $apiUrl/health" -ForegroundColor White
}

# ============================================================================
# Summary
# ============================================================================
$elapsed = (Get-Date) - $startTime
Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "               DEPLOYMENT COMPLETE                      " -ForegroundColor Green
Write-Host "=============================================================`n" -ForegroundColor Green

Write-Host "Deployment Summary:" -ForegroundColor Cyan
Write-Host "   Time Elapsed: $([math]::Round($elapsed.TotalMinutes, 1)) minutes" -ForegroundColor White
Write-Host "   API Endpoint: $apiUrl" -ForegroundColor White
Write-Host "   ECS Cluster: $ECS_CLUSTER" -ForegroundColor White
Write-Host "   ECS Service: $ECS_SERVICE" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "   1. Test API: $apiUrl/health" -ForegroundColor White
Write-Host "   2. Check products: $apiUrl/api/v1/products" -ForegroundColor White
Write-Host "   3. Update mobile app API endpoint if needed" -ForegroundColor White
Write-Host "   4. Build APK: .\build-apk.ps1 (if you have this script)" -ForegroundColor White

Write-Host ""
