# Terraform snippet to create ECS Task Role, Policy and a Task Definition that injects Secrets Manager secrets
# Fill variables or replace placeholders before applying.

variable "aws_account_id" {
  description = "(optional) AWS account id - if empty we will use the current caller identity"
  type        = string
  default     = ""
}

// region variable is declared in provider.tf
variable "cluster" { default = "shopsnports-cluster" }
variable "image" {
  description = "Container image to run (e.g. <account>.dkr.ecr.<region>.amazonaws.com/shopsnports:latest)"
  type        = string
  default     = ""
}
variable "container_name" { default = "shopsnports-api" }

variable "secret_arn_stripe_key" {
  description = "ARN for stripe secret_key (optional - falls back to data lookup)"
  type        = string
  default     = ""
}
variable "secret_arn_stripe_webhook" {
  description = "ARN for stripe webhook_secret (optional - falls back to data lookup)"
  type        = string
  default     = ""
}
variable "secret_arn_paystack" {
  description = "ARN for paystack secret_key (optional - falls back to data lookup)"
  type        = string
  default     = ""
}
variable "secret_arn_flutterwave" {
  description = "ARN for flutterwave secret_key (optional - falls back to data lookup)"
  type        = string
  default     = ""
}
variable "secret_arn_db_password" {
  description = "ARN for db password secret (optional - falls back to data lookup)"
  type        = string
  default     = ""
}
variable "execution_role_arn" {
  description = "(optional) existing execution role ARN to use for pulling images/logging"
  default     = ""
}

variable "task_role_arn" {
  description = "(optional) existing task role ARN to use for app permissions"
  default     = ""
}

# Task Role for the application (grants access to Secrets Manager for specific secrets)
resource "aws_iam_role" "task_role" {
  count = var.task_role_arn == "" ? 1 : 0
  name = "shopsnports-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Use secret ARNs from variables if supplied, otherwise use data lookups (outputs provided by secrets_lookup.tf)
locals {
  stripe_key_arn       = var.secret_arn_stripe_key != "" ? var.secret_arn_stripe_key : (try(data.aws_secretsmanager_secret.stripe_key.arn, ""))
  stripe_webhook_arn   = var.secret_arn_stripe_webhook != "" ? var.secret_arn_stripe_webhook : (try(data.aws_secretsmanager_secret.stripe_webhook.arn, ""))
  paystack_arn         = var.secret_arn_paystack != "" ? var.secret_arn_paystack : (try(data.aws_secretsmanager_secret.paystack_key.arn, ""))
  flutterwave_arn      = var.secret_arn_flutterwave != "" ? var.secret_arn_flutterwave : (try(data.aws_secretsmanager_secret.flutterwave_key.arn, ""))
  db_password_arn      = var.secret_arn_db_password != "" ? var.secret_arn_db_password : (try(data.aws_secretsmanager_secret.db_app_user_password.arn, ""))
}

# Attach an inline policy scoped to the specific secrets
resource "aws_iam_role_policy" "task_secrets_policy" {
  name = "shopsnports-task-secrets-policy"
  role = var.task_role_arn == "" ? aws_iam_role.task_role[0].id : var.task_role_arn
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "${local.stripe_key_arn}",
        "${local.stripe_webhook_arn}",
        "${local.paystack_arn}",
        "${local.flutterwave_arn}",
        "${local.db_password_arn}"
      ]
    }
  ]
}
POLICY
}

# Task definition with secrets injected from Secrets Manager
resource "aws_ecs_task_definition" "api" {
  family                   = "shopsnports-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn != "" ? var.execution_role_arn : (length(aws_iam_role.task_role) > 0 ? aws_iam_role.task_role[0].arn : var.execution_role_arn)
  task_role_arn            = var.task_role_arn != "" ? var.task_role_arn : (length(aws_iam_role.task_role) > 0 ? aws_iam_role.task_role[0].arn : var.task_role_arn)

  container_definitions = jsonencode([
    {
      name = var.container_name,
      image = var.image,
      essential = true,
      portMappings = [
        { containerPort = 3000, hostPort = 3000, protocol = "tcp" }
      ],
      secrets = [
        { name = "STRIPE_SECRET_KEY", valueFrom = local.stripe_key_arn },
        { name = "STRIPE_WEBHOOK_SECRET", valueFrom = local.stripe_webhook_arn },
        { name = "PAYSTACK_SECRET_KEY", valueFrom = local.paystack_arn },
        { name = "FLUTTERWAVE_SECRET_KEY", valueFrom = local.flutterwave_arn },
        { name = "DB_PASSWORD", valueFrom = local.db_password_arn }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/shopsnports",
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.api.arn
}

# Notes:
# - Consider creating a separate execution role (ecsTaskExecutionRole) for pulling images and writing logs. Here we used the same role for brevity.
# - Adjust CPU/memory, container ports, and image as needed.
# - Before applying, ensure ECS cluster exists, or add an aws_ecs_cluster resource.
# - After registering the task definition, update the ECS service to use the new task definition (aws ecs update-service).
