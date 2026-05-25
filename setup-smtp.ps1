# Interactive SMTP Configuration Script
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "ShopSnPorts SMTP Configuration" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Ask for password
$password = Read-Host "Enter SMTP password for noreply@shopsnports.com"

if ([string]::IsNullOrWhiteSpace($password)) {
    Write-Host "Error: Password cannot be empty!" -ForegroundColor Red
    exit 1
}

# Path to env file
$envFilePath = "functions\.env.onCustomerCreated"

# Check if file exists
if (-not (Test-Path $envFilePath)) {
    Write-Host "Error: File not found: $envFilePath" -ForegroundColor Red
    Write-Host "Make sure you're in: c:\projects\shopsnports" -ForegroundColor Yellow
    exit 1
}

# Read file
$envContent = @"
SMTP_HOST=smtp.shopsnports.com
SMTP_PORT=587
SMTP_USER=noreply@shopsnports.com
SMTP_PASS=$password
SMTP_SECURE=false
"@

# Write to file
Set-Content -Path $envFilePath -Value $envContent -Force

Write-Host ""
Write-Host "✅ SMTP configuration saved!" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Deploy the function" -ForegroundColor Yellow
Write-Host "Run: firebase deploy --only functions:onCustomerCreated" -ForegroundColor Cyan
Write-Host ""
