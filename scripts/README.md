# ShopsNPorts Setup Scripts

This folder contains scripts for deploying Firestore rules, indexes, and configuring email notifications.

## Email Notification Setup

### setup-smtp.sh (Linux/Mac) or setup-smtp.ps1 (Windows)
Configure SMTP credentials for Firebase Cloud Functions.

**Usage (Linux/Mac):**
```bash
bash scripts/setup-smtp.sh
```

**Usage (Windows PowerShell):**
```powershell
.\scripts\setup-smtp.ps1
```

**What it does:**
- Prompts you for SMTP host, port, user, password
- Stores credentials securely in Firebase Functions config (encrypted)
- Credentials are never committed to git

**Required information:**
- SMTP Host (e.g., `smtp.gmail.com`)
- SMTP Port (e.g., `587`)
- SMTP User/Email (e.g., `noreply@shopsnports.com`)
- SMTP Password (your email password or app-specific password)
- SSL/TLS setting (yes/no)

**After running:**
1. Deploy functions to apply changes:
   ```bash
   firebase deploy --only functions
   ```

2. Test email sending:
   ```bash
   bash scripts/test-smtp.sh your-email@example.com
   ```

### test-smtp.sh (Linux/Mac) or test-smtp.ps1 (Windows)
Test email sending with configured SMTP settings.

**Usage (Linux/Mac):**
```bash
bash scripts/test-smtp.sh recipient@example.com
```

**Usage (Windows PowerShell):**
```powershell
.\scripts\test-smtp.ps1 recipient@example.com
```

### Common SMTP Settings

| Provider | Host | Port | SSL/TLS |
|----------|------|------|---------|
| Gmail | smtp.gmail.com | 587 | false |
| Outlook | smtp-mail.outlook.com | 587 | false |
| Yahoo | smtp.mail.yahoo.com | 587 | false |
| SendGrid | smtp.sendgrid.net | 587 | false |
| AWS SES | email-smtp.us-east-1.amazonaws.com | 587 | false |

### Gmail Setup (Recommended)

1. Enable 2-Factor Authentication on your Google account
2. Go to Google Account Security → App Passwords
3. Create a new app password with name "ShopsNPorts"
4. Use that app password in the setup script

### Troubleshooting

**View current configuration:**
```bash
firebase functions:config:get
```

**Clear configuration (if needed):**
```bash
firebase functions:config:unset smtp
```

---

## Firebase Firestore Deploy Scripts

This folder also contains simple PowerShell scripts to deploy Firestore rules and indexes.

Prerequisites
- Firebase CLI installed and authenticated (firebase login)
- You have the correct project IDs for staging and production
- Update `firestore.rules` in the repo root before deploying (start from `firestore.rules.example`)

Usage

Deploy rules to staging:

```
./deploy_firestore_rules.ps1 -ProjectId "my-staging-project-id"
```

Deploy indexes:

```
./deploy_firestore_indexes.ps1 -ProjectId "my-staging-project-id"
```

Repeat for production. These scripts are intentionally minimal — you can integrate them into CI/CD with secure secrets for project IDs or use a single service account with the Firebase CLI in your pipeline.

Entry points
-----------
We added two entrypoints to help build/testing different environments:

- `lib/main_staging.dart` - initializes Firebase with `lib/firebase_options_staging.dart` and overrides `firestoreProvider`.
- `lib/main_production.dart` - initializes Firebase with `lib/firebase_options_production.dart` and overrides `firestoreProvider`.

Generate firebase options
-------------------------
Use the `flutterfire configure` command to generate the environment option files and place them under `lib/` as `firebase_options_staging.dart` and `firebase_options_production.dart`.

Smoke tests
-----------
We added a tiny `scripts/smoke_test.dart` file as a placeholder for smoke tests. It is intentionally minimal — use a real Admin SDK script or a proper test harness for production verification.

CI secrets
----------
Add these to GitHub secrets to enable automated deploys using the provided workflow:
- `FIREBASE_TOKEN`
- `PROJECT_ID_STAGING`
- `PROJECT_ID_PRODUCTION`

Admin helper
------------
We added `scripts/set_admin_claims.js` which you can run locally to set the `admin` custom claim for a user. Example:

```powershell
node .\set_admin_claims.js --key C:\path\to\sa.json --uid <USER_UID> --project shopsnports-7c967
```


