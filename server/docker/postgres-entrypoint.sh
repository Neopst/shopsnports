#!/bin/sh
set -euo pipefail

# Copy secrets from /run/secrets (Swarm) into a predictable folder and set perms
TARGET_DIR="/run/secrets/postgres"
mkdir -p "$TARGET_DIR"

copy_secret_if_exists() {
  name="$1"
  dest="$2"
  if [ -f "/run/secrets/$name" ]; then
    cp "/run/secrets/$name" "$dest"
    chown postgres:postgres "$dest"
    chmod 600 "$dest"
    echo "Copied secret $name -> $dest"
  fi
}

# expected secret names
copy_secret_if_exists "shopsnports_postgres_server_key" "$TARGET_DIR/server.key"
copy_secret_if_exists "shopsnports_postgres_server_crt" "$TARGET_DIR/server.crt"
copy_secret_if_exists "shopsnports_postgres_ca_crt" "$TARGET_DIR/ca.crt"

# If ssl files exist, ensure Postgres will read them from the secret path.
# IMPORTANT: do not create files in $PGDATA before initdb runs. initdb requires an empty directory.
# Only write postgresql.auto.conf if the cluster is already initialized (PG_VERSION exists).
if [ -f "$TARGET_DIR/server.key" ] && [ -f "$TARGET_DIR/server.crt" ]; then
  if [ -f "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "ssl = on" >> /var/lib/postgresql/data/postgresql.auto.conf || true
    echo "ssl_cert_file = '$TARGET_DIR/server.crt'" >> /var/lib/postgresql/data/postgresql.auto.conf || true
    echo "ssl_key_file = '$TARGET_DIR/server.key'" >> /var/lib/postgresql/data/postgresql.auto.conf || true
    chown postgres:postgres /var/lib/postgresql/data/postgresql.auto.conf || true
    echo "Wrote Postgres ssl config to postgresql.auto.conf (existing cluster)"
  else
    echo "Postgres cluster not initialized yet; skipping write to postgresql.auto.conf to avoid initdb errors."
    echo "After first start you can run: docker exec -it <cid> psql -U postgres -c \"ALTER SYSTEM SET ssl = 'on'; ALTER SYSTEM SET ssl_cert_file = '$TARGET_DIR/server.crt'; ALTER SYSTEM SET ssl_key_file = '$TARGET_DIR/server.key'; SELECT pg_reload_conf();\""
  fi
fi

# If DB password secret exists, copy it to /run/secrets so the app can also access it via /run/secrets
if [ -f "/run/secrets/shopsnports_app_user_password" ]; then
  cp /run/secrets/shopsnports_app_user_password /run/secrets/app_user_password.txt
  chown postgres:postgres /run/secrets/app_user_password.txt || true
  chmod 600 /run/secrets/app_user_password.txt || true
fi

# If a Postgres superuser password secret exists, load it into POSTGRES_PASSWORD so the official
# entrypoint will initialize the DB securely.
SUPER_SECRET_PATHS="/run/secrets/shopsnports_postgres_superuser_password /run/secrets/postgres_super_pw /run/secrets/postgres_superuser_password /run/secrets/postgres_superuser_pass"
found=""
for p in $SUPER_SECRET_PATHS; do
  if [ -f "$p" ]; then
    found="$p"
    break
  fi
done
# fallback: look for any secret filename mentioning both 'super' and 'pass'
if [ -z "$found" ]; then
  for f in /run/secrets/*; do
    if [ -f "$f" ]; then
      name=$(basename "$f" | tr '[:upper:]' '[:lower:]')
      if echo "$name" | grep -q "super" && echo "$name" | grep -q "pass"; then
        found="$f"
        break
      fi
    fi
  done
fi

if [ -n "$found" ]; then
  export POSTGRES_PASSWORD="$(cat "$found" | tr -d '\r')"
  echo "Loaded POSTGRES_PASSWORD from secret file: $found"
fi

# exec the original entrypoint with the same args
exec docker-entrypoint.sh postgres
