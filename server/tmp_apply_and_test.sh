#!/bin/bash
set -euo pipefail

# Run migration SQL (assumes migration_core.sql is present at /tmp/migration_core.sql)
psql -U postgres -d shopsnports -v ON_ERROR_STOP=1 -f /tmp/migration_core.sql

# Smoke test as app_user using in-container secret
if [ ! -f /run/secrets/shopsnports_app_user_password ]; then
  echo "ERROR: secret shopsnports_app_user_password not found" >&2
  exit 1
fi
PW=$(cat /run/secrets/shopsnports_app_user_password)
export PGPASSWORD="$PW"
psql -U app_user -d shopsnports -c "INSERT INTO users (username, password_hash, role) VALUES ('smoke_test_post_migrate', 'x', 'user') ON CONFLICT DO NOTHING;"
psql -U app_user -d shopsnports -c "SELECT username FROM users WHERE username='smoke_test_post_migrate' LIMIT 1;"

echo "SCRIPT_DONE"
