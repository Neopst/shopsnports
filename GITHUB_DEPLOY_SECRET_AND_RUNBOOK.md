Add `DEPLOY_ROLE_ARN` secret and run OIDC smoke-test

This file contains copy-paste steps for adding the `DEPLOY_ROLE_ARN` repository secret and running the manual OIDC assume-role smoke-test workflow that we added at `.github/workflows/oidc-assume-role-smoke.yml`.

1) Add the secret via the GitHub UI (simplest)
- Go to your repository on github.com (e.g. https://github.com/<owner>/<repo>)
- Settings → Secrets and variables → Actions → New repository secret
  - Name: DEPLOY_ROLE_ARN
  - Value: arn:aws:iam::119495459751:role/shopsnports-github-deploy-role
  - Click Add secret

2) Add the secret via GitHub CLI (`gh`) — Windows copy/paste
# Install `gh` (Windows using winget)
```powershell
winget install --id GitHub.cli -e --source winget
```
# Authenticate `gh` (follow prompts)
```powershell
gh auth login
```
# From the repo root, set the secret
```powershell
gh secret set DEPLOY_ROLE_ARN --body "arn:aws:iam::119495459751:role/shopsnports-github-deploy-role"
```

3) Run the OIDC smoke-test workflow (manual)
- In GitHub: Actions → OIDC assume-role smoke test → Run workflow → Branch: main (or default) → Run workflow
- The workflow uses `id-token: write` permission and will attempt to assume the role then run `aws sts get-caller-identity`.

4) What to look for in the Action logs
- Open the job, expand the "Show caller identity" step output.
- Success: you should see JSON similar to:
```
{
  "UserId": "AROA...:session-name",
  "Account": "119495459751",
  "Arn": "arn:aws:sts::119495459751:assumed-role/shopsnports-github-deploy-role/session-name"
}
```
- Failure reasons and quick checks:
  - 400/403: secret not present or empty; verify `DEPLOY_ROLE_ARN` exists.
  - "AccessDenied" or trust error: verify the role trust policy includes the correct `sub`/`aud` for your repo/org and `sts:AssumeRoleWithWebIdentity` is allowed.
  - "id-token: write" missing: ensure the workflow permissions include `id-token: write` (the provided workflow already does).

5) Remove the temporary inline policy (admin)
- Console (recommended):
  - Sign in as an admin.
  - IAM → Users → shopsnports-deployer → Permissions → Inline policies → Delete `shopsnportspermissioninlinepolicy`.
  - Verify under Permissions that the inline policy no longer appears.

- CLI (admin): copy/paste
```powershell
# with an admin profile configured
aws iam delete-user-policy --user-name shopsnports-deployer --policy-name shopsnportspermissioninlinepolicy --profile admin-profile
aws iam list-user-policies --user-name shopsnports-deployer --profile admin-profile
# expected: empty or at least no 'shopsnportspermissioninlinepolicy'
```

6) Optional: confirm CI can assume the role locally (debug)
- If you have AWS CLI and a token from OIDC set up, you can use `aws sts assume-role-with-web-identity` locally for troubleshooting, but typically the Action logs provide the best signal.

7) Quick rollback plan
- If any step breaks deploy, reattach the temporary inline policy for a short admin window (via Console) while you investigate, then remove when fixed.

If you'd like, I can also:
- Create a small PR that wires `DEPLOY_ROLE_ARN` into the real deploy workflow (`.github/workflows/deploy-oidc.yml`) ready to use (requires a secret to be present), or
- Add more debugging steps for trust-policy adjustments (e.g. exact `sub` claim values to accept repo or org-wide tokens).