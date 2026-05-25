Backups & Secrets (operational runbook)

This document describes the steps to implement backups & restore testing (item 5) and secrets rotation/management (item 6).

Goals
- Ensure data is regularly backed up (RPO), encrypted at rest, and can be restored (RTO) with verification.
- Ensure secrets (DB passwords, TLS keys, Firebase JSON) are stored securely and can be rotated without downtime.

Item 5: Backups & restore testing - sequence of steps
1) Decide backup cadence & retention
   - Example: daily full backups + hourly incremental (if needed). For now we implement daily full backups.

2) Prepare backup target
   - S3 bucket or MinIO. Create bucket and credentials with limited privileges (PutObject, ListBucket).

3) Implement backup script
   - Use `server/scripts/backup_pg.ps1` (PowerShell) which:
     - Runs `pg_dump` (customizable to use app_user or postgres user depending on access needs)
     - Compresses and encrypts the dump (OpenSSL AES-256-CBC)
     - Uploads to S3 using AWS CLI

4) Schedule backups
   - Use a scheduled task (Windows) or cron job (Linux) or a containerized scheduled job (Kubernetes CronJob / Docker scheduled job) to invoke the backup script.

5) Implement restore verification
   - Use `server/scripts/restore_pg.ps1` to download a backup, decrypt, decompress and restore into a temporary Postgres container, then run a set of smoke queries.

6) Automate and alert
   - Add monitoring for the backup job (success/failure) and configure alerts (PagerDuty/Email/Slack).

Acceptance criteria for backups
- Daily backup exists in S3 and is encrypted.
- Restore script can restore a backup to a fresh Postgres container and smoke tests pass.
- Alerts are configured for failed backups.

Item 6: Secrets management & rotation - sequence of steps
1) Inventory secrets
   - List all secrets (DB passwords, TLS key, TLS cert, Firebase JSON, 3rd party API keys).

2) Decide secrets backend
   - Options: Docker secrets (current), HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager.
   - Recommendation: If you have cloud provider lock-in, use the cloud's Secret Manager. For multi-cloud/self-hosting, use Vault.

3) Migration plan
   - For Vault: create a Vault path `secret/shopsnports/` and write secrets.
   - Scripts to fetch secrets at deploy-time and create Docker secrets or mount as files for your containers.

4) Rotation automation
   - Use `server/scripts/rotate_secret.ps1` to create a new docker secret and add it to the service. Automate tests to verify the new secret works (smoke tests), then safely remove the old secret.

5) Audit & access control
   - Ensure access to the secrets backend is limited and logged (Vault policies / IAM roles).

Acceptance criteria for secrets
- No sensitive secrets in repository or in PGDATA.
- Rotation procedure exists and is tested for app_user password.
- At least one secrets backend is selected and integrated (Vault or cloud) and automation is in place.

Start now
- I created `server/scripts/backup_pg.ps1`, `server/scripts/restore_pg.ps1`, and `server/scripts/rotate_secret.ps1`.
- To continue I can:
  - Wire a scheduled job to run `backup_pg.ps1` daily and run `restore_pg.ps1` once to verify.
  - Implement a Vault example integration and rotate secrets once with `rotate_secret.ps1`.

If you want me to proceed now, pick:
- "Backups now": I'll run a manual backup, upload to S3/MinIO (you must provide S3 credentials or allow me to use local MinIO), and run a restore verification.
- "Secrets now": I'll scaffold a Vault example and rotate `app_user` secret once, verifying the service remains healthy.
- "Both": I'll do backups first, then secrets rotation.
