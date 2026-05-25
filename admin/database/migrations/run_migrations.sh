#!/bin/bash
# Database Migration Runner
# Run all migration scripts in order against PostgreSQL RDS

# Database credentials
DB_HOST="marketplace-db.ceno66e8mz81.us-east-1.rds.amazonaws.com"
DB_USER="admin0"
DB_PASSWORD="ShopsNSports2024!"
DB_NAME="marketplace"
DB_PORT="5432"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Database Migration Runner${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: psql is not installed${NC}"
    echo "Please install PostgreSQL client tools"
    exit 1
fi

# Set PGPASSWORD environment variable
export PGPASSWORD="$DB_PASSWORD"

# Test database connection
echo -e "${YELLOW}Testing database connection...${NC}"
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -c "SELECT 1;" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to connect to database${NC}"
    echo "Host: $DB_HOST"
    echo "User: $DB_USER"
    echo "Database: $DB_NAME"
    exit 1
fi

echo -e "${GREEN}✓ Database connection successful${NC}"
echo ""

# Get list of migration files
MIGRATIONS_DIR="$(dirname "$0")"
MIGRATION_FILES=$(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort)

if [ -z "$MIGRATION_FILES" ]; then
    echo -e "${RED}No migration files found in $MIGRATIONS_DIR${NC}"
    exit 1
fi

# Run each migration
echo -e "${YELLOW}Running migrations...${NC}"
echo ""

for migration_file in $MIGRATION_FILES; do
    filename=$(basename "$migration_file")
    echo -e "${YELLOW}Running: $filename${NC}"
    
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -f "$migration_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $filename completed successfully${NC}"
    else
        echo -e "${RED}✗ $filename failed${NC}"
        echo -e "${RED}Migration stopped at $filename${NC}"
        exit 1
    fi
    echo ""
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All migrations completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

# Show table count
echo ""
echo -e "${YELLOW}Database summary:${NC}"
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -c "\dt"

# Unset password
unset PGPASSWORD
