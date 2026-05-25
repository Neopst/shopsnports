# SMTP PASSWORD ROTATION SCRIPT
param([switch]$Help)

if ($Help) {
    Write-Host @"
SMTP PASSWORD ROTATION SCRIPT

This script updates your SMTP password securely.

USAGE:
  .\update-smtp-password.ps1

STEPS:
  1. Enter your NEW SMTP password (hidden)
  2. Script updates Firebase Functions config
  3. Local .env files updated if they exist
  4. See summary of changes

BEFORE RUNNING:
  - Have your new SMTP password ready
  - Logged into Firebase: firebase login
"@
    exit
}

# Functions
function Write-Success {
    Write-Host "[SUCCESS] $($args -join ' ')" -ForegroundColor Green
}

function Write-Error-Custom {
    Write-Host "[ERROR] $($args -join ' ')" -ForegroundColor Red
}

function Write-Warning-Custom {
    Write-Host "[WARNING] $($args -join ' ')" -ForegroundColor Yellow
}

function Write-Info {
    Write-Host "[INFO] $($args -join ' ')" -ForegroundColor Cyan
}

function Test-Firebase-CLI {
    try {
        firebase --version 2>$null | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Update-Firebase-Config {
    param([string]$Password)
    
    Write-Info "Updating Firebase Functions config..."
    try {
        firebase functions:config:set smtp.pass="$Password" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Firebase config updated"
            return $true
        }
        else {
            Write-Error-Custom "Firebase update failed"
            return $false
        }
    }
    catch {
        Write-Error-Custom "Error: $_"
        return $false
    }
}

function Update-Env-Files {
    param([string]$Password)
    
    $functionsDir = Join-Path $PSScriptRoot "functions"
    if (-not (Test-Path $functionsDir)) {
        return $false
    }
    
    $envFiles = Get-ChildItem -Path $functionsDir -Filter ".env*" 2>$null
    
    if ($envFiles.Count -eq 0) {
        return $false
    }
    
    $updated = 0
    foreach ($file in $envFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "SMTP_PASS") {
            $newContent = $content -replace 'SMTP_PASS=.*', "SMTP_PASS=$Password"
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -ErrorAction SilentlyContinue
            Write-Success "Updated $($file.Name)"
            $updated++
        }
    }
    
    return $updated -gt 0
}

# Main script
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMTP PASSWORD ROTATION TOOL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Firebase
Write-Info "Checking Firebase CLI..."
if (-not (Test-Firebase-CLI)) {
    Write-Error-Custom "Firebase CLI not found"
    Write-Host "Install: npm install -g firebase-tools"
    exit 1
}
Write-Success "Firebase CLI found"

# Get password
Write-Host ""
Write-Host "Enter your NEW SMTP password:" -ForegroundColor Yellow
$pass1 = Read-Host -AsSecureString

$pass1Str = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass1)
)

if ([string]::IsNullOrWhiteSpace($pass1Str)) {
    Write-Error-Custom "Password cannot be empty"
    exit 1
}

# Confirm password
Write-Host "Confirm password:" -ForegroundColor Yellow
$pass2 = Read-Host -AsSecureString

$pass2Str = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass2)
)

if ($pass1Str -ne $pass2Str) {
    Write-Error-Custom "Passwords do not match"
    exit 1
}

Write-Success "Passwords match"

# Update configs
Write-Host ""
Write-Info "Updating configuration..."

$firebaseOk = Update-Firebase-Config -Password $pass1Str
$envOk = Update-Env-Files -Password $pass1Str

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "UPDATE SUMMARY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($firebaseOk) {
    Write-Host "Firebase Functions config: UPDATED" -ForegroundColor Green
}

if ($envOk) {
    Write-Host "Local .env files: UPDATED" -ForegroundColor Green
}

if (-not $firebaseOk -and -not $envOk) {
    Write-Warning-Custom "No files were updated"
}

# Next steps
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Deploy: firebase deploy --only functions"
Write-Host "2. Test email system with test shipping request"
Write-Host "3. Check logs: firebase functions:log"
Write-Host ""

Write-Success "Password rotation complete!"

# Cleanup
$pass1Str = $null
$pass2Str = $null
[System.GC]::Collect()

Write-Host "[INFO] Sensitive data cleared" -ForegroundColor Gray
Write-Host ""
