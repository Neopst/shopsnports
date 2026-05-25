# Initialize shippingRequests Firestore Collection
# Cross-platform PowerShell compatible script
# Usage: pwsh .\scripts\init_shipping_collection.ps1  (or .\scripts\init_shipping_collection.ps1 on Windows)

Write-Host "Initializing shippingRequests Firestore Collection" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$scriptPath = Join-Path $projectRoot "scripts" "init_shipping_requests_collection.js"

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Script not found: $scriptPath" -ForegroundColor Red
    Write-Host "Please ensure init_shipping_requests_collection.js exists in the scripts folder" -ForegroundColor Yellow
    exit 1
}

# Check if serviceAccountKey.json exists
$serviceAccountKey = Join-Path $projectRoot "functions" "serviceAccountKey.json"
if (-not (Test-Path $serviceAccountKey)) {
    Write-Host "ERROR: Firebase service account key not found" -ForegroundColor Red
    Write-Host "Expected at: $serviceAccountKey" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To get your service account key:" -ForegroundColor Cyan
    Write-Host "1. Go to Firebase Console: https://console.firebase.google.com" -ForegroundColor White
    Write-Host "2. Select shopsnports project" -ForegroundColor White
    Write-Host "3. Click Project Settings icon (gear)" -ForegroundColor White
    Write-Host "4. Go to Service Accounts tab" -ForegroundColor White
    Write-Host "5. Click Generate New Private Key" -ForegroundColor White
    Write-Host "6. Save JSON file as serviceAccountKey.json in the functions folder" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "SUCCESS: Service account key found" -ForegroundColor Green
Write-Host ""
Write-Host "Running initialization..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Gray
Write-Host ""

# Run the initialization script
node $scriptPath

$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "======================================" -ForegroundColor Gray

if ($exitCode -eq 0) {
    Write-Host "SUCCESS: Collection initialized successfully!" -ForegroundColor Green
    Write-Host "Ready to receive shipping requests" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "ERROR: Initialization failed (Exit code: $exitCode)" -ForegroundColor Red

exit $exitCode
