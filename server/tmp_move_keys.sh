#!/usr/bin/env bash
set -e
mkdir -p /run/secrets/postgres
cp /var/lib/postgresql/server.crt /run/secrets/postgres/server.crt
cp /var/lib/postgresql/server.key /run/secrets/postgres/server.key
chown -R postgres:postgres /run/secrets/postgres
chmod 600 /run/secrets/postgres/server.key
ls -l /run/secrets/postgres
psql -U postgres -c "ALTER SYSTEM SET ssl_cert_file = '/run/secrets/postgres/server.crt';"
psql -U postgres -c "ALTER SYSTEM SET ssl_key_file = '/run/secrets/postgres/server.key';"
psql -U postgres -c "SELECT pg_reload_conf();"
psql -U postgres -c "SHOW ssl_cert_file;"
psql -U postgres -c "SHOW ssl_key_file;"
