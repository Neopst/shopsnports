This folder contains Terraform snippets and policies to create an IAM role that GitHub Actions can assume via OIDC.

Purpose
- Create a minimal IAM role that allows GH Actions to read specific Secrets Manager secrets and perform ECS deploy steps.

Important variables
- `aws_account_id` (required)
- `github_org` (required)
- `github_repo` (required)
- `region` (defaults to us-east-1)
- `ecs_cluster_arn` (optional) - restrict ECS Update permissions to a cluster
- `ecs_service_arn` (optional) - restrict ECS Update permissions to a specific service
- `task_role_arn` (optional) - restrict iam:PassRole to specific task role
- `execution_role_arn` (optional) - restrict iam:PassRole to specific execution role

Usage (safe)
1. Review the policy in `terraform_oidc_role.tf` and replace variables via a `terraform.tfvars` file or `-var` flags.
2. Run `terraform init` and `terraform plan` locally. Inspect the plan carefully.
3. Apply in a controlled environment (staging) first: `terraform apply`.
4. After role creation, copy the `deploy_role_arn` output into `.github/workflows/deploy-oidc.yml` as the `role-to-assume`.

Notes
- The policy intentionally prefers explicit ARNs when provided; leave them blank to use wildcards (not recommended for production).
- The role trust policy constrains tokens to the `repo:ORG/REPO:ref:refs/heads/*` subject; consider tightening to a fixed branch like `refs/heads/main` for production.
- Limit `secretsmanager` resources to the `shopsnports/production/*` prefix; if you store secrets elsewhere, update the ARN accordingly.

Security checklist
- Use GitHub branch protection and manual approvals for main branch deploys.
- Rotate any long-lived credentials used for bootstrap; prefer OIDC.
- Audit role usage via CloudTrail.
