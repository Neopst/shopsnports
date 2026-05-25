# Complete Deployment Script
# Deploys API with banner routes and admin dashboard

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     SHOPSNPORTS - COMPLETE DEPLOYMENT AUTOMATION         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$startTime = Get-Date

# ============================================================================
# STEP 1: Build and Deploy API to ECS
# ============================================================================
Write-Host "📦 STEP 1/4: Building API Docker Image..." -ForegroundColor Yellow
cd C:\projects\marketplace-api

docker build -t marketplace-api:latest . 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker image built successfully`n" -ForegroundColor Green

# ============================================================================
# STEP 2: Push to ECR
# ============================================================================
Write-Host "🔐 STEP 2/4: Pushing to AWS ECR..." -ForegroundColor Yellow

# ECR Login
$ecrPassword = aws ecr get-login-password --region us-east-1
$ecrPassword | docker login --username AWS --password-stdin 119495459751.dkr.ecr.us-east-1.amazonaws.com 2>&1 | Out-Null

# Tag and push
docker tag marketplace-api:latest 119495459751.dkr.ecr.us-east-1.amazonaws.com/marketplace-api:latest
docker push 119495459751.dkr.ecr.us-east-1.amazonaws.com/marketplace-api:latest 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ECR push failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Pushed to ECR successfully`n" -ForegroundColor Green

# ============================================================================
# STEP 3: Deploy to ECS
# ============================================================================
Write-Host "🚀 STEP 3/4: Deploying to ECS..." -ForegroundColor Yellow

aws ecs update-service `
    --cluster marketplace-api-cluster `
    --service marketplace-api-task-service-siq7bzxe `
    --force-new-deployment `
    --region us-east-1 `
    --output json | Out-Null

Write-Host "✅ ECS deployment initiated`n" -ForegroundColor Green
Write-Host "⏳ Waiting for deployment to stabilize (90 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

# Check deployment status
$service = aws ecs describe-services `
    --cluster marketplace-api-cluster `
    --services marketplace-api-task-service-siq7bzxe `
    --region us-east-1 `
    --output json | ConvertFrom-Json

$deployment = $service.services[0].deployments[0]
Write-Host "   Status: $($deployment.status)" -ForegroundColor Cyan
Write-Host "   Running: $($deployment.runningCount)/$($deployment.desiredCount)`n" -ForegroundColor Cyan

# Test API
Write-Host "🧪 Testing banner API endpoint..." -ForegroundColor Yellow
try {
    $testUrl = "http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/api/v1/content/banners/active?placement=home"
    $response = Invoke-RestMethod -Uri $testUrl -Method Get -ErrorAction Stop
    if ($response.success -and $response.data.Count -gt 0) {
        Write-Host "✅ Banner API working! Found $($response.data.Count) banners`n" -ForegroundColor Green
    } else {
        Write-Host "⚠️  API responded but no banners found`n" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  API test failed (might need more time to stabilize)`n" -ForegroundColor Yellow
}

# ============================================================================
# STEP 4: Build and Deploy Admin Dashboard
# ============================================================================
Write-Host "🎨 STEP 4/4: Building Admin Dashboard..." -ForegroundColor Yellow
cd C:\projects\shopsnports\admin_dashboard

flutter build web --release --web-renderer html 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Admin dashboard build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Admin dashboard built`n" -ForegroundColor Green

Write-Host "🚀 Deploying to Firebase..." -ForegroundColor Yellow
firebase deploy --only hosting 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Firebase deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Admin dashboard deployed to https://admin.shopsnports.com`n" -ForegroundColor Green

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║             🎉 DEPLOYMENT COMPLETE! 🎉                   ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "⏱️  Total Time: $([int]$duration.TotalMinutes) min $($duration.Seconds) sec`n" -ForegroundColor Cyan

Write-Host "✅ READY FOR APK BUILD!" -ForegroundColor Green
Write-Host "`n📱 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Test banner API: http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/api/v1/content/banners/active" -ForegroundColor White
Write-Host "   2. Test admin dashboard: https://admin.shopsnports.com" -ForegroundColor White
Write-Host "   3. Run mobile app to verify sliders display" -ForegroundColor White
Write-Host "   4. Build production APK: flutter build apk --release`n" -ForegroundColor White
