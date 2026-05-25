This folder contains Terraform snippets to wire AWS Secrets Manager secrets into ECS task definitions.

Files:
- terraform_task_with_secrets.tf  - Task role, inline policy, and task definition with Secrets Manager secrets injected as container environment variables.

Usage:
1) Replace variable placeholders or define them in a `.tfvars` file:
   - aws_account_id = "123456789012"
   - region = "us-east-1"
   - image = "<your-ecr-or-docker-image>"
   - container_name = "shopsnports-api"

2) Initialize and plan in this directory (or include in your root Terraform module):
   terraform init
   terraform plan -var-file=path/to/vars.tfvars

3) Apply in a staging account first. Ensure you have a remote backend configured for state locking.

4) After task definition is registered, update your ECS service to use the new task definition ARN:
   aws ecs update-service --cluster <cluster> --service <service> --task-definition <task-def-arn>

Notes:
- This snippet uses a single role for the task; consider using a separate execution role with `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, etc., for image pulls.
- Keep the task role policy minimally scoped to exact secret ARNs when possible.
