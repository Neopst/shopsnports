#!/usr/bin/env pwsh
# Build script for development
# Usage: .\scripts\build-dev.ps1

Write-Host "🔨 Building for DEVELOPMENT..." -ForegroundColor Cyan

flutter build apk `
  --dart-define=ENVIRONMENT=development `
  --dart-define=API_BASE_URL=http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com `
  --dart-define=ENABLE_ANALYTICS=true `
  --dart-define=ENABLE_CRASHLYTICS=false

Write-Host "✅ Development build complete!" -ForegroundColor Green
Write-Host "📦 APK location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
