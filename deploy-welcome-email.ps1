#!/usr/bin/env pwsh
<#
.SYNOPSIS
Deploy ShopSnPorts Welcome Email Function with SMTP Configuration

.DESCRIPTION
This script automates the deployment of the onCustomerCreated Cloud Function
with all required SMTP parameters for Windows PowerShell.

.PARAMETER SmtpPassword
The SMTP password for noreply@shopsnports.com (required for function to work)

.EXAMPLE
.\deploy-welcome-email.ps1 -SmtpPassword "your_actual_password"
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="SMTP password for noreply@shopsnports.com")]
    [string]$SmtpPassword
)

$ErrorActionPreference = "Stop"

# Simple output functions
function ShowSuccess {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function ShowError {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function ShowWarning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function ShowInfo {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

# Verify we're in the correct directory
if (-not (Test-Path "functions/package.json")) {
    ShowError "Not in project root! Please run from c:\projects\shopsnports"
    exit 1
}

ShowInfo "🚀 ShopSnPorts Welcome Email Deployment Script"
ShowInfo "============================================="

# Step 1: Check Firebase CLI
ShowInfo "Step 1: Checking Firebase CLI..."
try {
    $firebaseVersion = firebase --version 2>&1 | Select-String "firebase-tools"
    ShowSuccess "Firebase CLI found: $firebaseVersion"
} catch {
    ShowError "Firebase CLI not found! Install with: npm install -g firebase-tools"
    exit 1
}

# Step 2: Install dependencies
ShowInfo "Step 2: Installing dependencies..."
try {
    Set-Location functions
    ShowInfo "Running: npm install"
    npm install 2>&1 | Select-String -Pattern "added|up to date"
    ShowSuccess "Dependencies installed"
    Set-Location ..
} catch {
    ShowError "Failed to install dependencies: $_"
    exit 1
}

# Step 3: Deploy with environment variables
ShowInfo "Step 3: Deploying with SMTP configuration..."
try {
    $params = @(
        "SMTP_HOST=smtp.shopsnports.com",
        "SMTP_PORT=587",
        "SMTP_USER=noreply@shopsnports.com",
        "SMTP_PASS=$SmtpPassword",
        "SMTP_SECURE=false"
    )
    
    $setEnvArgs = $params -join " "
    ShowInfo "Setting environment variables..."
    
    # Firebase deploy with environment variables
    firebase deploy --only functions:onCustomerCreated `
        --set-env "$setEnvArgs" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        ShowSuccess "Function deployed successfully!"
    } else {
        ShowWarning "Deployment completed with warnings. Check output above."
    }
} catch {
    ShowError "Deployment failed: $_"
    exit 1
}

# Step 4: Verify deployment
ShowInfo "Step 4: Verifying deployment..."
try {
    firebase functions:list 2>&1 | Select-String "onCustomerCreated" | ForEach-Object {
        ShowSuccess "Found: $_"
    }
} catch {
    ShowWarning "Could not verify deployment"
}

# Step 5: Show next steps
ShowInfo "====================================="
ShowSuccess "Deployment Complete!"
ShowInfo ""
ShowInfo "Next Steps:"
ShowInfo "1. Register a new account on the mobile app"
ShowInfo "2. Use an email you can access (Gmail recommended)"
ShowInfo "3. Check inbox for welcome email"
ShowInfo ""
ShowInfo "Monitoring:"
ShowInfo "   View logs: firebase functions:log"
ShowInfo "   Check Firestore activity_log collection for details"
ShowInfo ""
ShowInfo "Firebase Console: https://console.firebase.google.com/project/shopsnports"
ShowInfo ""
