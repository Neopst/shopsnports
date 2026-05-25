# ShopsNSports API Server Monitor & Auto-Restart Script
# This script continuously monitors and auto-restarts the server if it crashes

param(
    [switch]$AutoRestart = $false
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "ShopsNSports API Server Monitor" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

if ($AutoRestart) {
    Write-Host "[MODE] Auto-restart enabled" -ForegroundColor Green
    Write-Host "       Server will automatically restart if it crashes" -ForegroundColor Green
} else {
    Write-Host "[MODE] Single run (use -AutoRestart for continuous operation)" -ForegroundColor Yellow
}
Write-Host ""

# Set working directory
Set-Location $PSScriptRoot

# Set Firebase credentials
$env:GOOGLE_APPLICATION_CREDENTIALS = "$PSScriptRoot\shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json"

# Check if Firebase credentials file exists
if (-not (Test-Path $env:GOOGLE_APPLICATION_CREDENTIALS)) {
    Write-Host "[ERROR] Firebase credentials file not found!" -ForegroundColor Red
    exit 1
}

# Set NODE_ENV
if (-not $env:NODE_ENV) {
    $env:NODE_ENV = "development"
}

$restartCount = 0

do {
    if ($restartCount -gt 0) {
        Write-Host ""
        Write-Host "================================" -ForegroundColor Yellow
        Write-Host "Server crashed! Restarting..." -ForegroundColor Yellow
        Write-Host "Restart count: $restartCount" -ForegroundColor Yellow
        Write-Host "================================" -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 2
    }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting server..." -ForegroundColor Green
    
    # Start the server and capture exit code
    node index.js
    $exitCode = $LASTEXITCODE
    
    $restartCount++
    
    if ($exitCode -eq 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Server stopped gracefully (exit code 0)" -ForegroundColor Green
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Server exited with code $exitCode" -ForegroundColor Red
    }
    
} while ($AutoRestart)

Write-Host ""
Write-Host "Monitor stopped. Total restarts: $restartCount" -ForegroundColor Cyan
