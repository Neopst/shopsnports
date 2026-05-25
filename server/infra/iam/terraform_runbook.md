Terraform runbook — safe plan/apply for OIDC role + publish deploy role ARN to GitHub

This runbook is Windows/PowerShell friendly and focused on creating the OIDC deploy role and publishing the `deploy_role_arn` into a GitHub repository secret called `DEPLOY_ROLE_ARN`.

Preconditions
- You have AWS credentials configured for an account with permission to create IAM roles and policies.
- You have `terraform` installed and on PATH.
- You have `gh` (GitHub CLI) installed and authenticated (for publishing the secret) or you can add the secret via GitHub UI.
- Edit `terraform.tfvars` or copy from `terraform.tfvars.example` and fill with your real values.

Secure checklist (manual review required)
1. Review `terraform_oidc_role.tf` and `shopsnports_deploy_policy.json` to ensure ARNs and permissions match your security posture.
2. Fill `terraform.tfvars` with your `aws_account_id`, `github_org`, `github_repo`, and optional ARNs.
3. Ensure you understand the iam:PassRole resource scope; set `task_role_arn` and `execution_role_arn` if you want to restrict it.

PowerShell commands (copy/paste-safe)

# From project root
cd server/infra/iam

# Initialize and validate
terraform init
terraform validate

# Plan (use -out to capture plan file)
terraform plan -var-file=terraform.tfvars -out=plan.out

# Inspect human-readable plan
terraform show -no-color plan.out | Out-File -Encoding utf8 plan.txt
notepad plan.txt  # review plan carefully

# Apply only when you're ready
terraform apply "plan.out"

# Capture the role ARN
$roleArn = terraform output -raw deploy_role_arn
Write-Host "Deploy role ARN: $roleArn"

# Optionally store into GitHub Actions secret (gh CLI)
# Ensure gh is authenticated and you have repo admin rights
gh secret set DEPLOY_ROLE_ARN --body $roleArn --repo "<GITHUB_ORG>/<GITHUB_REPO>"

# Or print instructions to store via GitHub UI
Write-Host "If you don't use gh, open: https://github.com/<GITHUB_ORG>/<GITHUB_REPO>/settings/secrets/actions and create DEPLOY_ROLE_ARN with the value above."

Post-apply checks
- Trigger `workflow_dispatch` on `.github/workflows/deploy-oidc.yml` and confirm `Show caller identity` prints the assumed role's ARN.
- Ensure CloudTrail logs show `AssumeRoleWithWebIdentity` events from `token.actions.githubusercontent.com`.

Rollback (if needed)
- If you want to remove the role, run `terraform destroy -var-file=terraform.tfvars`. Review dependencies — ensure no active workflows rely on that role.

Notes
- This runbook intentionally requires manual review of the plan before apply.
- If you plan to automate terraform in CI, store state in a remote backend (S3 + DynamoDB lock) and protect your secrets.
