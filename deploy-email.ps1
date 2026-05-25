# Simple interactive deployment script
Write-Host "ShopSnPorts Welcome Email Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Ask for password
$password = Read-Host "Enter SMTP password for noreply@shopsnports.com" -AsSecureString
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password))

# Verify we're in the right directory
if (-not (Test-Path "functions/package.json")) {
    Write-Host "ERROR: Not in project root!" -ForegroundColor Red
    Write-Host "Please run from: c:\projects\shopsnports" -ForegroundColor Red
    exit 1
}

# Step 1: Install dependencies
Write-Host "`nStep 1: Installing dependencies..." -ForegroundColor Yellow
Set-Location functions
npm install
Set-Location ..

# Step 2: Deploy function
Write-Host "`nStep 2: Deploying function..." -ForegroundColor Yellow
firebase deploy --only functions:onCustomerCreated --set-env SMTP_HOST=smtp.shopsnports.com,SMTP_PORT=587,SMTP_USER=noreply@shopsnports.com,SMTP_PASS=$plainPassword,SMTP_SECURE=false

# Step 3: Verify
Write-Host "`nStep 3: Verifying deployment..." -ForegroundColor Yellow
firebase functions:list

Write-Host "`nDone! Watch for welcome emails on new customer registration." -ForegroundColor Green
Write-Host "Check logs: firebase functions:log" -ForegroundColor Green
