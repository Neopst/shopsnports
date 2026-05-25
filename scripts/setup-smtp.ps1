###############################################################################
# SMTP Configuration Setup Script for ShopsNPorts (PowerShell)
#
# This script securely configures SMTP credentials for Firebase Cloud Functions
# by storing them in Firebase Functions config (encrypted, not in git).
#
# Usage: .\scripts\setup-smtp.ps1
###############################################################################

# Error action preference
$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green @Args }
function Write-Error { Write-ColorOutput Red @Args }
function Write-Warning { Write-ColorOutput Yellow @Args }
function Write-Info { Write-ColorOutput Cyan @Args }

# Print header
Write-Host ""
Write-Info "═══════════════════════════════════════════════════════════════"
Write-Info "        📧 SMTP Configuration Setup - ShopsNPorts"
Write-Info "═══════════════════════════════════════════════════════════════"
Write-Host ""
Write-Host "This will configure SMTP credentials for email sending."
Write-Host "Credentials will be stored securely in Firebase Functions config."
Write-Host ""

# Check if firebase CLI is installed
Write-Warning "🔍 Checking Firebase CLI installation..."
try {
    $firebaseVersion = firebase --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Firebase CLI not found"
    }
    Write-Success "✅ Firebase CLI found: $firebaseVersion"
} catch {
    Write-Error "❌ Error: Firebase CLI not found"
    Write-Host "Please install it first: npm install -g firebase-tools"
    exit 1
}

# Check if logged in to Firebase
Write-Warning "🔍 Checking Firebase login status..."
try {
    $loginStatus = firebase login:list 2>&1
    if ($loginStatus -match "No active" -or $loginStatus -match "not logged in") {
        Write-Warning "⚠️  Not logged in to Firebase"
        Write-Host "Please run: firebase login"
        Write-Host ""
        Read-Host "Press Enter to continue after logging in, or Ctrl+C to cancel"
        firebase login
    }
    Write-Success "✅ Firebase CLI ready"
} catch {
    Write-Warning "⚠️  Could not verify login status, continuing..."
}

Write-Host ""

# Prompt for SMTP configuration
Write-Info "📝 SMTP Configuration (ShopsNPorts):"
Write-Host ""
Write-Host "Using ShopsNPorts SMTP settings:"
Write-Host "  SMTP Host:     mail.shopsnports.com"
Write-Host "  SMTP Port:     465"
Write-Host "  SMTP User:     noreply@shopsnports.com"
Write-Host "  SSL/TLS:       Enabled"
Write-Host ""

# Set ShopsNPorts SMTP defaults
$SMTP_HOST = "mail.shopsnports.com"
$SMTP_PORT = "465"
$SMTP_USER = "noreply@shopsnports.com"
$SMTP_SECURE = "true"

# SMTP Password (hidden input) - ONLY prompt for password
Write-Host ""
$SMTP_PASS = Read-Host -AsSecureString "Enter the email account's password"
$SMTP_PASS_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SMTP_PASS))
if ([string]::IsNullOrWhiteSpace($SMTP_PASS_PLAIN)) {
    Write-Error "❌ Error: SMTP Password is required"
    exit 1
}

# Display confirmation
Write-Host ""
Write-Info "───────────────────────────────────────────────────────────────"
Write-Info "📋 Configuration Summary:"
Write-Info "───────────────────────────────────────────────────────────────"
Write-Host "  SMTP Host:     $SMTP_HOST"
Write-Host "  SMTP Port:     $SMTP_PORT"
Write-Host "  SMTP User:     $SMTP_USER"
Write-Host "  SMTP Password: ********"  # Hidden
Write-Host "  Secure SSL:    $SMTP_SECURE"
Write-Host ""

# Confirm before proceeding
$CONFIRM = Read-Host "Proceed with this configuration? (yes/no)"
if ($CONFIRM -notmatch "^(y|yes)$") {
    Write-Warning "⚠️  Setup cancelled"
    exit 0
}

Write-Host ""
Write-Info "🔧 Configuring Firebase Functions..."
Write-Host ""

# Build the firebase command
$firebaseCmd = "firebase functions:config:set smtp.host=`"$SMTP_HOST`" smtp.port=`"$SMTP_PORT`" smtp.user=`"$SMTP_USER`" smtp.pass=`"$SMTP_PASS_PLAIN`" smtp.secure=`"$SMTP_SECURE`""

# Apply configuration
try {
    Invoke-Expression $firebaseCmd
    if ($LASTEXITCODE -ne 0) {
        throw "Firebase command failed"
    }
    Write-Host ""
    Write-Success "✅ SMTP configuration saved successfully!"
} catch {
    Write-Host ""
    Write-Error "❌ Failed to configure Firebase Functions"
    Write-Host "Error: $_"
    exit 1
}

Write-Host ""
Write-Info "───────────────────────────────────────────────────────────────"
Write-Info "📌 Next Steps:"
Write-Info "───────────────────────────────────────────────────────────────"
Write-Host ""
Write-Host "1. Deploy functions to apply changes:"
Write-Warning "   firebase deploy --only functions"
Write-Host ""
Write-Host "2. Test email sending with:"
Write-Warning "   node test-email-notification.js"
Write-Host ""
Write-Host "3. To view current configuration:"
Write-Warning "   firebase functions:config:get"
Write-Host ""
Write-Host "4. To update configuration later, run this script again:"
Write-Warning "   .\scripts\setup-smtp.ps1"
Write-Host ""
Write-Success "🎉 Setup complete!"
Write-Host ""


