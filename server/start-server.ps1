# ShopsNSports API Server Startup Script
# This script starts the backend server with proper environment configuration

Write-Host "================================" -ForegroundColor Cyan
Write-Host "ShopsNSports API Server Startup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location $PSScriptRoot

# Set Firebase credentials
$env:GOOGLE_APPLICATION_CREDENTIALS = "$PSScriptRoot\shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json"
Write-Host "[CONFIG] Firebase credentials: $env:GOOGLE_APPLICATION_CREDENTIALS" -ForegroundColor Green

# Check if Firebase credentials file exists
if (-not (Test-Path $env:GOOGLE_APPLICATION_CREDENTIALS)) {
    Write-Host "[ERROR] Firebase credentials file not found!" -ForegroundColor Red
    Write-Host "        Looking for: $env:GOOGLE_APPLICATION_CREDENTIALS" -ForegroundColor Yellow
    exit 1
}

# Load .env file if it exists
if (Test-Path "$PSScriptRoot\.env") {
    Write-Host "[CONFIG] Loading environment variables from .env" -ForegroundColor Green
} else {
    Write-Host "[WARNING] .env file not found" -ForegroundColor Yellow
}

# Set NODE_ENV if not already set
if (-not $env:NODE_ENV) {
    $env:NODE_ENV = "development"
}
Write-Host "[CONFIG] NODE_ENV: $env:NODE_ENV" -ForegroundColor Green

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Starting API Server on port 3000" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the server
node index.js

# If server exits, show status
Write-Host ""
Write-Host "================================" -ForegroundColor Red
Write-Host "Server stopped" -ForegroundColor Red
Write-Host "================================" -ForegroundColor Red
Write-Host ""
Write-Host "To restart, run: .\start-server.ps1" -ForegroundColor Yellow
