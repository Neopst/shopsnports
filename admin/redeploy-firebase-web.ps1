# Flutter Admin Dashboard - Quick Firebase Redeploy
# This script skips clean and just builds + deploys (faster for updates)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Redeploy to Firebase Hosting" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Build for web (production)
Write-Host "Building Flutter web app (release mode)..." -ForegroundColor Yellow
flutter build web --release --web-renderer html
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build completed" -ForegroundColor Green
Write-Host ""

# Deploy to Firebase Hosting
Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Deployed successfully!" -ForegroundColor Green
