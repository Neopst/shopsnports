#!/usr/bin/env pwsh
# Build script for production
# Usage: .\scripts\build-prod.ps1
# Requires environment variables or .env file with production keys

Write-Host "🚀 Building for PRODUCTION..." -ForegroundColor Cyan

# Check if required keys are set
if (-not $env:STRIPE_KEY) {
    Write-Host "❌ ERROR: STRIPE_KEY environment variable not set!" -ForegroundColor Red
    Write-Host "Set it with: `$env:STRIPE_KEY='pk_live_...'" -ForegroundColor Yellow
    exit 1
}

flutter build apk `
  --dart-define=ENVIRONMENT=production `
  --dart-define=API_BASE_URL=http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com `
  --dart-define=STRIPE_KEY=$env:STRIPE_KEY `
  --dart-define=PAYSTACK_KEY=$env:PAYSTACK_KEY `
  --dart-define=FLUTTERWAVE_KEY=$env:FLUTTERWAVE_KEY `
  --dart-define=ENABLE_ANALYTICS=true `
  --dart-define=ENABLE_CRASHLYTICS=true `
  --release

Write-Host "✅ Production build complete!" -ForegroundColor Green
Write-Host "📦 APK location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
Write-Host "⚠️  Remember to test before deploying!" -ForegroundColor Yellow
