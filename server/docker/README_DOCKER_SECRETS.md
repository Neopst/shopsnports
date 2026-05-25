Docker secrets: Postgres TLS key/cert and app DB password
===============================================

This folder contains helper files to run Postgres with Docker Secrets (Swarm mode) so TLS private keys and the app DB password are not stored on disk inside the container or repository.

Why
- Docker Secrets keeps secret data out of images and (by default) places them under /run/secrets/<name> inside the container with restricted access.
- This flow avoids keeping `server.key` in PGDATA and prevents accidental check-ins.

What this adds
- `docker-compose.postgres.secrets.yml` — an example Compose stack that declares external secrets and mounts a custom entrypoint for Postgres that copies secrets into place and updates `postgresql.auto.conf`.
- `postgres-entrypoint.sh` — small wrapper that copies secrets from `/run/secrets` to `/run/secrets/postgres`, sets permissions, and ensures Postgres will read `ssl_cert_file`/`ssl_key_file` from that path.
- `create_docker_secrets.ps1` — PowerShell helper to create the Docker secrets from files under `./certs/` and `./secrets/`. It will initialise swarm if necessary (prompting), then create secrets.

Important notes
- Docker secrets works natively with Docker Swarm (recommended). `docker stack deploy` is the easiest way to consume secrets as files in services. Compose v3+ with `secrets` also supports them but in standalone compose the secrets are stored on disk.
- For development (non-swarm) the helper script can optionally write the secret files into `./secrets/` and set strict ACLs so your app can continue to read the DB password file — this is a fallback only.
- After creating secrets, you must stop the running Postgres container and deploy the stack (or recreate the service) so the new entrypoint runs and config is applied.

Quick flow (PowerShell)

1) Create secrets from the files you already have locally (adjust paths if needed):

```powershell
# from project root (c:\projects\shopsnports)
cd .\server
.\docker\create_docker_secrets.ps1
```

The script will look for `./certs/server.key`, `./certs/server.crt`, `./certs/ca.crt` and `./secrets/app_user_password.txt`. It creates secrets named:
- `shopsnports_postgres_server_key`
- `shopsnports_postgres_server_crt`
- `shopsnports_postgres_ca_crt` (optional)
- `shopsnports_app_user_password`

2) Deploy the stack using the compose file included here (this uses swarm mode / stack deployment):

```powershell
docker stack deploy -c .\docker\docker-compose.postgres.secrets.yml shopsnports
```

3) Verify the service is running and that Postgres reports the ssl files:

```powershell
# list services
docker service ls

# check logs
docker service logs shopsnports_db --tail 200

# exec into the running container to check SHOW ssl_cert_file
docker exec -it $(docker ps -q -f name=shopsnports_db) psql -U postgres -d shopsnports -c "SHOW ssl_cert_file; SHOW ssl_key_file; SHOW ssl;"
```

Fallback for non-swarm/dev
- If you cannot use Docker Swarm, the script can optionally place the files under `./secrets/` and set strict ACLs (the application already reads `APP_DB_PASSWORD_FILE=./secrets/app_user_password.txt`). This is less secure than real Docker Secrets but is a practical development fallback.

Rotation notes
- To rotate certs or the DB password: create a new secret (for example `shopsnports_postgres_server_key_v2`), update the stack to reference the new secret, and perform a rolling update. Keep an emergency rollback plan.

Support
- If you want, I can also produce a Kubernetes Secret + Deployment manifest instead, or wire this into your CI/CD pipeline.

Try it (concrete commands)

1) From the project root, create the Docker secrets (this will init swarm if necessary):

```powershell
cd C:\projects\shopsnports\server
.\docker\create_docker_secrets.ps1
```

2) Deploy the stack (uses swarm stack deploy so secrets are available under /run/secrets in services):

```powershell
docker stack deploy -c .\docker\docker-compose.postgres.secrets.yml shopsnports
```

3) If you see permission or entrypoint issues (Windows path mapping won't preserve executable bit), run:

```powershell
# on the host that will run the service (if Linux), ensure the entrypoint is executable
chmod +x server/docker/postgres-entrypoint.sh
```

Notes on executability
- Windows filesystems don't preserve the Unix executable bit. If your swarm manager runs on Windows, you'll likely want to build a tiny image that includes `postgres-entrypoint.sh` with correct permissions and use that image in the compose file instead of a host bind mount. I can provide a Dockerfile for that if you prefer.

