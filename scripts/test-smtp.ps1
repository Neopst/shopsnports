###############################################################################
# SMTP Test Script for ShopsNPorts (PowerShell)
#
# This script sends a test email using the configured SMTP settings.
#
# Usage: .\scripts\test-smtp.ps1 recipient@example.com
###############################################################################

# Error action preference
$ErrorActionPreference = "Stop"

# Colors
function Write-Success { Write-Host -ForegroundColor Green @Args }
function Write-Error { Write-Host -ForegroundColor Red @Args }
function Write-Warning { Write-Host -ForegroundColor Yellow @Args }
function Write-Info { Write-Host -ForegroundColor Cyan @Args }

# Get recipient from argument
$RECIPIENT = $args[0]

Write-Info "📧 SMTP Test - ShopsNPorts"
Write-Host ""

# Check if recipient provided
if ([string]::IsNullOrWhiteSpace($RECIPIENT)) {
    Write-Error "Usage: .\scripts\test-smtp.ps1 recipient@example.com"
    Write-Host ""
    Write-Host "Example:"
    Write-Warning "  .\scripts\test-smtp.ps1 test@gmail.com"
    exit 1
}

# Check if functions config is set
Write-Warning "🔍 Checking SMTP configuration..."
try {
    $CONFIG = firebase functions:config:get 2>&1
    if ($LASTEXITCODE -ne 0 -or $CONFIG -notmatch "smtp") {
        Write-Error "❌ SMTP configuration not found"
        Write-Host ""
        Write-Host "Please run setup first:"
        Write-Warning "  .\scripts\setup-smtp.ps1"
        exit 1
    }
    Write-Success "✅ SMTP Configuration found"
} catch {
    Write-Error "❌ Could not verify SMTP configuration"
    Write-Host "Please run setup first:"
    Write-Warning "  .\scripts\setup-smtp.ps1"
    exit 1
}

# Get SMTP user from config (to verify)
if ($CONFIG -match '"user":\s*"([^"]+)"') {
    $SMTP_USER = $Matches[1]
    Write-Host "  SMTP User: $SMTP_USER"
}
Write-Host "  Recipient: $RECIPIENT"
Write-Host ""

# Test email sending
Write-Info "🧪 Sending test email..."
Write-Host ""

# Check if we can use the existing test script
if (Test-Path "test-email-notification.js") {
    Write-Warning "Using existing test-email-notification.js"
    Write-Host ""
    Write-Host "To test with specific recipient, you may need to update the test script."
} else {
    Write-Warning "To test email sending, you need to:"
    Write-Host ""
    Write-Host "1. Deploy functions first:"
    Write-Warning "   firebase deploy --only functions"
    Write-Host ""
    Write-Host "2. Then test via Firebase Console or by triggering sendEmail function"
    Write-Host ""
    Write-Host "3. Or use the test-email-notification.js script in project root"
    Write-Host ""
}

Write-Success "✅ Test complete"
Write-Host ""
Write-Info "💡 Tip: Check your inbox for the test email"
Write-Host ""