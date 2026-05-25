param()

# Initialize shippingRequests Firestore Collection
# Simple cross-platform compatible version

Write-Host ""
Write-Host "Initializing shippingRequests Firestore Collection" -ForegroundColor Cyan
Write-Host ""

# Get project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

$nodescript = Join-Path $projectRoot "scripts" "init_shipping_requests_collection.js"
$serviceKey = Join-Path $projectRoot "functions" "serviceAccountKey.json"

# Check if Node script exists
if ((Test-Path $nodescript) -eq $false) {
    Write-Host "ERROR: Script not found at $nodescript" -ForegroundColor Red
    exit 1
}

# Check if service account key exists
if ((Test-Path $serviceKey) -eq $false) {
    Write-Host "ERROR: Service account key not found" -ForegroundColor Red
    Write-Host "Expected: $serviceKey" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To get your service account key:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://console.firebase.google.com" -ForegroundColor White
    Write-Host "2. Select shopsnports project" -ForegroundColor White
    Write-Host "3. Click gear icon > Service Accounts" -ForegroundColor White
    Write-Host "4. Click Generate New Private Key" -ForegroundColor White
    Write-Host "5. Save as serviceAccountKey.json in functions folder" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "SUCCESS: Service account key found" -ForegroundColor Green
Write-Host ""
Write-Host "Running initialization..." -ForegroundColor Cyan
Write-Host "======================================"

# Run Node script
node $nodescript
$exitCode = $LASTEXITCODE

Write-Host "======================================"
Write-Host ""

if ($exitCode -eq 0) {
    Write-Host "SUCCESS: Collection initialized!" -ForegroundColor Green
    Write-Host "Ready for shipping requests" -ForegroundColor Cyan
} else {
    Write-Host "ERROR: Failed with code $exitCode" -ForegroundColor Red
}

Write-Host ""
exit $exitCode
