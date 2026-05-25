# Terraform snippet to create an OIDC-assumable role for GitHub Actions
# Fill in variables or replace placeholders before applying.

variable "aws_account_id" {}
variable "region" {
  default = "us-east-1"
}

variable "github_org" {}

variable "github_repo" {}

variable "ecs_cluster_arn" {
  description = "(optional) ARN of the ECS cluster the workflow will update. If empty, wildcards are used."
  default     = ""
}

variable "ecs_service_arn" {
  description = "(optional) ARN of the ECS service to update. If empty, wildcards are used."
  default     = ""
}

variable "task_role_arn" {
  description = "(optional) Task role ARN that may be passed via iam:PassRole."
  default     = ""
}

variable "execution_role_arn" {
  description = "(optional) Execution role ARN that may be passed via iam:PassRole."
  default     = ""
}

// Explicit provider block: use the profile and region variables so the AWS provider uses the named profile
provider "aws" {
  region  = var.region
  # Use the named profile configured locally (shopsnports-deployer)
  profile = "shopsnports-deployer"
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "shopsnports-github-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

# Attach inline policy - you may choose to use aws_iam_policy + aws_iam_role_policy_attachment instead
resource "aws_iam_role_policy" "deploy_policy" {
  name = "shopsnports-deploy-policy"
  role = aws_iam_role.github_actions_deploy.id
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":[
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource":["arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:shopsnports/production/*"]
    },
    {
      "Effect":"Allow",
      "Action":[
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
        "iam:PassRole"
      ],
      "Resource":[
        ${var.ecs_cluster_arn != "" ? "\"${var.ecs_cluster_arn}\"" : "\"*\""},
        ${var.ecs_service_arn != "" ? "\"${var.ecs_service_arn}\"" : "\"*\""}
      ]
    },
    {
      "Effect":"Allow",
      "Action":[
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource":"*"
    }
  ]
}
POLICY
}

output "deploy_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}
