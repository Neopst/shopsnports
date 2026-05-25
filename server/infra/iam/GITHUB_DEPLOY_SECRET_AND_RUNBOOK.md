Runbook: export deploy_role_arn and add to GitHub Secrets (DEPLOY_ROLE_ARN)

Purpose
- After creating the OIDC role via Terraform, store the role ARN in the repository secret `DEPLOY_ROLE_ARN` so GitHub Actions can assume it.

Steps (from your workstation)
1. From the `server/infra/iam` directory, run terraform to create the role:

```bash
terraform init
terraform plan -var-file=terraform.tfvars # inspect the changes
terraform apply -var-file=terraform.tfvars
```

2. After apply, capture the role ARN:

```bash
terraform output -raw deploy_role_arn
# e.g. arn:aws:iam::123456789012:role/shopsnports-github-deploy-role
```

3. Add the ARN to your GitHub repository secrets (recommended: repository-level secret)

- In GitHub UI: Settings → Secrets and variables → Actions → New repository secret
  - Name: DEPLOY_ROLE_ARN
  - Value: <paste role ARN from terraform output>

- Or via gh CLI (if authenticated):

```bash
gh secret set DEPLOY_ROLE_ARN --body "$(terraform output -raw deploy_role_arn)" --repo your-org/shopsnports
```

4. Verify in a dry-run workflow
- Trigger the `.github/workflows/deploy-oidc.yml` via `workflow_dispatch` and inspect the `Show caller identity` step. It should show the assumed role's ARN.

Security notes
- Use branch protection and require manual approval for main deploys.
- Prefer repository-level secret over organization-level if you want tighter control.
- Rotate long-lived credentials and avoid embedding ARNs in code — use `terraform.tfvars` or CI secret injection.

Troubleshooting
- If `terraform output` is empty, check the apply logs and ensure the role resource was created.
- If the workflow fails to assume the role, verify the trust policy's `token.actions.githubusercontent.com:sub` matches your repo and branch (consider limiting to `refs/heads/main`).
