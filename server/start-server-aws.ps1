# ===================================================================
# ShopsNSports Server Startup Script - AWS RDS Production Mode
# ===================================================================
# This script starts the Node.js server with AWS RDS PostgreSQL
# ===================================================================

param(
    [switch]$AutoRestart,
    [switch]$RunMigrations
)

$ErrorActionPreference = "Stop"

# Get script directory and change to it
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  ShopsNSports Server - AWS RDS Mode" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the server directory
if (-not (Test-Path ".\index.js")) {
    Write-Host "[ERROR] index.js not found!" -ForegroundColor Red
    Write-Host "   Please run this script from the server directory" -ForegroundColor Yellow
    Write-Host "   Example: cd c:\projects\shopsnports\server" -ForegroundColor Yellow
    exit 1
}

# Check for Firebase credentials
$firebaseKeyPath = ".\shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json"
if (-not (Test-Path $firebaseKeyPath)) {
    Write-Host "[ERROR] Firebase credentials not found!" -ForegroundColor Red
    Write-Host "   Expected: $firebaseKeyPath" -ForegroundColor Yellow
    exit 1
}

# Set Firebase credentials environment variable
$env:GOOGLE_APPLICATION_CREDENTIALS = $firebaseKeyPath
Write-Host "[OK] Firebase credentials: $firebaseKeyPath" -ForegroundColor Green

# Load .env file
if (Test-Path ".\.env") {
    Write-Host "[OK] Loading environment variables from .env" -ForegroundColor Green
    Get-Content .\.env | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ($key -and -not $key.StartsWith('#')) {
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
    }
} else {
    Write-Host "[WARNING] .env file not found" -ForegroundColor Yellow
}

# Display database connection info
Write-Host ""
Write-Host "Database Configuration:" -ForegroundColor Cyan
$dbUrl = $env:DATABASE_URL
if ($dbUrl -match 'postgres://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)') {
    $dbUser = $matches[1]
    $dbHost = $matches[3]
    $dbPort = $matches[4]
    $dbName = $matches[5]
    
    Write-Host "   Host: $dbHost" -ForegroundColor Gray
    Write-Host "   Port: $dbPort" -ForegroundColor Gray
    Write-Host "   Database: $dbName" -ForegroundColor Gray
    Write-Host "   User: $dbUser" -ForegroundColor Gray
    
    if ($dbHost -like "*amazonaws.com") {
        Write-Host "   Type: AWS RDS (Production)" -ForegroundColor Green
    } elseif ($dbHost -eq "localhost") {
        Write-Host "   Type: Local PostgreSQL" -ForegroundColor Yellow
    } else {
        Write-Host "   Type: Remote PostgreSQL" -ForegroundColor Cyan
    }
} else {
    Write-Host "   [WARNING] DATABASE_URL not configured" -ForegroundColor Yellow
}

# Run migrations if requested
if ($RunMigrations) {
    Write-Host ""
    Write-Host "Running database migrations..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        npm run migrate
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[OK] Migrations completed successfully!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[WARNING] Migrations completed with warnings (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host ""
        Write-Host "[ERROR] Migration failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Continue starting server anyway? (Y/N)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -ne 'Y' -and $response -ne 'y') {
            exit 1
        }
    }
}

Write-Host ""
Write-Host "Starting server..." -ForegroundColor Cyan
Write-Host ""

$restartCount = 0

do {
    if ($restartCount -gt 0) {
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Yellow
        Write-Host "  Auto-restart #$restartCount at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
        Write-Host "=========================================" -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 2
    }
    
    # Start the server
    node index.js
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "[OK] Server stopped gracefully (exit code: 0)" -ForegroundColor Green
        break
    } else {
        Write-Host ""
        Write-Host "[WARNING] Server exited with code: $exitCode" -ForegroundColor Yellow
        
        if (-not $AutoRestart) {
            Write-Host ""
            Write-Host "Server stopped. Use -AutoRestart to automatically restart on crashes." -ForegroundColor Gray
            break
        }
        
        $restartCount++
        
        if ($restartCount -ge 10) {
            Write-Host ""
            Write-Host "[ERROR] Too many restarts ($restartCount). Stopping auto-restart." -ForegroundColor Red
            break
        }
    }
    
} while ($AutoRestart)

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Server Stopped" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($restartCount -gt 0) {
    Write-Host "Total restarts: $restartCount" -ForegroundColor Gray
}

Write-Host ""
