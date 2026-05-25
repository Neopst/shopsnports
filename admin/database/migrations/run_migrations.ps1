# Database Migration Runner (PowerShell)
# Run all migration scripts in order against PostgreSQL RDS

# Database credentials
$DB_HOST = "marketplace-db.ceno66e8mz81.us-east-1.rds.amazonaws.com"
$DB_USER = "admin0"
$DB_PASSWORD = "ShopsNSports2024!"
$DB_NAME = "marketplace"
$DB_PORT = "5432"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Database Migration Runner" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# Set environment variable for password
$env:PGPASSWORD = $DB_PASSWORD

# Test database connection
Write-Host "Testing database connection..." -ForegroundColor Yellow
$testResult = psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "SELECT 1;" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to connect to database" -ForegroundColor Red
    Write-Host "Host: $DB_HOST"
    Write-Host "User: $DB_USER"
    Write-Host "Database: $DB_NAME"
    exit 1
}

Write-Host "✓ Database connection successful" -ForegroundColor Green
Write-Host ""

# Get list of migration files
$MIGRATIONS_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$MIGRATION_FILES = Get-ChildItem -Path $MIGRATIONS_DIR -Filter "*.sql" | Sort-Object Name

if ($MIGRATION_FILES.Count -eq 0) {
    Write-Host "No migration files found in $MIGRATIONS_DIR" -ForegroundColor Red
    exit 1
}

# Run each migration
Write-Host "Running migrations..." -ForegroundColor Yellow
Write-Host ""

foreach ($migration_file in $MIGRATION_FILES) {
    $filename = $migration_file.Name
    Write-Host "Running: $filename" -ForegroundColor Yellow
    
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -f $migration_file.FullName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $filename completed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ $filename failed" -ForegroundColor Red
        Write-Host "Migration stopped at $filename" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "  All migrations completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Show table count
Write-Host ""
Write-Host "Database summary:" -ForegroundColor Yellow
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "\dt"

# Unset password
Remove-Item Env:\PGPASSWORD
