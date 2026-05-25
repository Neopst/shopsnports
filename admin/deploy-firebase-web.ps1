# Flutter Admin Dashboard - Firebase Web Deployment Script
# This script builds the Flutter web app and deploys to Firebase Hosting

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Admin - Firebase Web Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean previous builds
Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Clean completed" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pub get failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies resolved" -ForegroundColor Green
Write-Host ""

# Step 3: Build for web (production)
Write-Host "Step 3: Building Flutter web app (release mode)..." -ForegroundColor Yellow
flutter build web --release --web-renderer html
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build completed - output in build/web" -ForegroundColor Green
Write-Host ""

# Step 4: Deploy to Firebase Hosting
Write-Host "Step 4: Deploying to Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Cyan
Write-Host "Your admin dashboard is now live on Firebase Hosting" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
