variable "stage" {
  description = "Secret stage/environment (e.g. production, staging)"
  type        = string
  default     = "production"
}

data "aws_secretsmanager_secret" "stripe_key" {
  name = "shopsnports/${var.stage}/stripe/secret_key"
}

data "aws_secretsmanager_secret" "stripe_webhook" {
  name = "shopsnports/${var.stage}/stripe/webhook_secret"
}

data "aws_secretsmanager_secret" "paystack_key" {
  name = "shopsnports/${var.stage}/paystack/secret_key"
}

data "aws_secretsmanager_secret" "flutterwave_key" {
  name = "shopsnports/${var.stage}/flutterwave/secret_key"
}

data "aws_secretsmanager_secret" "db_app_user_password" {
  name = "shopsnports/${var.stage}/db/app_user_password"
}

output "secret_arn_stripe_key" {
  value = data.aws_secretsmanager_secret.stripe_key.arn
}

output "secret_arn_stripe_webhook" {
  value = data.aws_secretsmanager_secret.stripe_webhook.arn
}

output "secret_arn_paystack" {
  value = data.aws_secretsmanager_secret.paystack_key.arn
}

output "secret_arn_flutterwave" {
  value = data.aws_secretsmanager_secret.flutterwave_key.arn
}

output "secret_arn_db_password" {
  value = data.aws_secretsmanager_secret.db_app_user_password.arn
}
