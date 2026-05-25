# Production APK Build Script
# Builds release APK for ShopsNSports mobile app

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          📱 SHOPSNPORTS - APK BUILD SCRIPT 📱            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$startTime = Get-Date

cd C:\projects\shopsnports

# ============================================================================
# PRE-BUILD CHECKS
# ============================================================================
Write-Host "🔍 Pre-build checks..." -ForegroundColor Yellow

# Check API connectivity
Write-Host "   Testing API connection..." -ForegroundColor Cyan
try {
    $apiTest = Invoke-RestMethod -Uri "http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/api/v1/products" -Method Get -TimeoutSec 5
    if ($apiTest.success) {
        Write-Host "   ✅ API is online ($($apiTest.data.Count) products)" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️  API connection warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Check banner endpoint
Write-Host "   Testing banner endpoint..." -ForegroundColor Cyan
try {
    $bannerTest = Invoke-RestMethod -Uri "http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/api/v1/content/banners/active" -Method Get -TimeoutSec 5
    if ($bannerTest.success) {
        Write-Host "   ✅ Banners available ($($bannerTest.data.Count) sliders)" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️  Banner endpoint not ready yet" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# CLEAN BUILD
# ============================================================================
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "✅ Clean complete`n" -ForegroundColor Green

# ============================================================================
# GET DEPENDENCIES
# ============================================================================
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get | Out-Null
Write-Host "✅ Dependencies updated`n" -ForegroundColor Green

# ============================================================================
# BUILD APK
# ============================================================================
Write-Host "🔨 Building production APK..." -ForegroundColor Yellow
Write-Host "   This may take 3-5 minutes...`n" -ForegroundColor Cyan

flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ APK build failed!" -ForegroundColor Red
    exit 1
}

# ============================================================================
# BUILD COMPLETE
# ============================================================================
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              🎉 APK BUILD COMPLETE! 🎉                   ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "⏱️  Build Time: $([int]$duration.TotalMinutes) min $($duration.Seconds) sec`n" -ForegroundColor Cyan

# Get APK info
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
    Write-Host "📦 APK Details:" -ForegroundColor Yellow
    Write-Host "   Location: $apkPath" -ForegroundColor White
    Write-Host "   Size: $apkSize MB" -ForegroundColor White
    Write-Host "   Full Path: $(Resolve-Path $apkPath)`n" -ForegroundColor White
    
    # Copy to easy access location
    $outputDir = "C:\projects\shopsnports\releases"
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $releaseApk = "$outputDir\ShopsNSports-v1.0-$timestamp.apk"
    Copy-Item $apkPath $releaseApk
    
    Write-Host "✅ APK copied to: $releaseApk`n" -ForegroundColor Green
    
    Write-Host "📱 Ready for Testing/Distribution!" -ForegroundColor Green
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "   1. Test APK on Android device/emulator" -ForegroundColor White
    Write-Host "   2. Verify all features: products, sliders, payments, etc." -ForegroundColor White
    Write-Host "   3. Share with team for testing" -ForegroundColor White
    Write-Host "   4. Upload to Google Play Console (when ready)`n" -ForegroundColor White
} else {
    Write-Host "⚠️  APK file not found at expected location" -ForegroundColor Yellow
}
