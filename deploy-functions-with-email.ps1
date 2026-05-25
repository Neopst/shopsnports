# Deploy Cloud Functions with SMTP Environment Variables
# This deploys the email functions with the configured SMTP credentials

Write-Host "🚀 Deploying Firebase Cloud Functions with SMTP Configuration..." -ForegroundColor Green
Write-Host ""

# Navigate to functions directory
$functionsPath = "C:\projects\shopsnports\functions"
if (!(Test-Path $functionsPath)) {
    Write-Host "❌ Functions directory not found at $functionsPath" -ForegroundColor Red
    exit 1
}

cd $functionsPath

# Read SMTP credentials from .env.onCustomerCreated
Write-Host "📖 Reading SMTP credentials from .env.onCustomerCreated..." -ForegroundColor Cyan

if (!(Test-Path ".env.onCustomerCreated")) {
    Write-Host "❌ .env.onCustomerCreated file not found!" -ForegroundColor Red
    exit 1
}

# Parse .env file
$envContent = Get-Content ".env.onCustomerCreated"
$smtpHost = ($envContent | Select-String 'SMTP_HOST=').ToString().Split('=')[1]
$smtpPort = ($envContent | Select-String 'SMTP_PORT=').ToString().Split('=')[1]
$smtpUser = ($envContent | Select-String 'SMTP_USER=').ToString().Split('=')[1]
$smtpPass = ($envContent | Select-String 'SMTP_PASS=').ToString().Split('=')[1]
$smtpSecure = ($envContent | Select-String 'SMTP_SECURE=').ToString().Split('=')[1]

Write-Host "✅ Extracted SMTP Configuration:" -ForegroundColor Green
Write-Host "   - Host: $smtpHost"
Write-Host "   - Port: $smtpPort"
Write-Host "   - User: $smtpUser"
Write-Host "   - Secure: $smtpSecure"
Write-Host ""

# Build TypeScript to JavaScript
Write-Host "📦 Building TypeScript functions..." -ForegroundColor Cyan
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build successful" -ForegroundColor Green
Write-Host ""

# Deploy functions with environment variables
Write-Host "📤 Deploying functions to Firebase with SMTP environment variables..." -ForegroundColor Cyan
Write-Host ""

firebase deploy --only functions `
  --set-env SMTP_HOST=$smtpHost `
  --set-env SMTP_PORT=$smtpPort `
  --set-env SMTP_USER=$smtpUser `
  --set-env SMTP_PASS="$smtpPass" `
  --set-env SMTP_SECURE=$smtpSecure

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Deployment successful!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Deployed Functions:" -ForegroundColor Cyan
firebase functions:list
Write-Host ""
Write-Host "🧪 Testing email functionality:" -ForegroundColor Yellow
Write-Host "   1. Create a new account in the mobile app"
Write-Host "   2. Check email for welcome message from noreply@shopsnports.com"
Write-Host "   3. Check Firebase Console > Functions > Logs for execution details"
