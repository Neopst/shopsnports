Production checklist for ShopsNports server

Required environment variables (examples):

- DATABASE_URL: postgres://user:password@host:5432/shopsnports
- NODE_ENV=production
- SESSION_SECRET: a long random secret for session signing
- ADMIN_API_KEY: key required to serve the static admin UI
- DB_SSL=true (optional) to enable TLS to Postgres
- DB_SSL_REJECT_UNAUTHORIZED=false (optional) for self-signed certs (not recommended for production)

Recommended steps before go-live

1. Use a dedicated DB user (not 'postgres') with least privileges. Create user and grant necessary privileges.
2. Apply schema migrations using a versioned migration tool (node-pg-migrate, Flyway, etc.) instead of relying on on-start CREATE TABLEs.
3. Rotate credentials and store them in a secrets manager. Do not commit secrets to source control.
4. Enable TLS for app and DB connections. Serve admin UI over HTTPS only.
5. Configure nightly backups. Example included: `scripts/backup-db.ps1`.
6. Configure monitoring and alerting (health checks, log shipping, uptime monitors).
7. Harden sessions and cookies: set `SESSION_SECRET` and ensure `cookie.secure` is true behind HTTPS.
8. Disable dev fallbacks: `ADMIN_USER`/`ADMIN_PASS` are allowed only in non-production.

Backup usage

From project root:

powershell
Set-Location -Path 'server'
.\scripts\backup-db.ps1 -OutDir .\backups -DbName shopsnports -User postgres

This script performs a pg_dump inside the container and copies the SQL dump to the host backups directory.

Restoration example

Use `psql` to restore a dump to a database. Be careful: this will overwrite data.

psql -U postgres -d shopsnports -f path/to/dump.sql

Further reading
- Postgres backups: https://www.postgresql.org/docs/current/backup.html
- Migrations: https://github.com/salsita/node-pg-migrate
