variable "project_name" {
  type = string
  default = "shopsnports"
}

variable "environment" {
  type = string
  default = "staging"
}

variable "ecs_cluster_name" {
  type = string
  default = "shopsnports-cluster"
}

variable "ecs_service_name" {
  type = string
  default = "shopsnports-service"
}

variable "desired_count" {
  type = number
  default = 1
}

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 14
  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}

# Alarm: High CPU utilization across ECS services (average CPU > 80% for 5 minutes)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
  alarm_description = "Alarm when ECS service CPU utilization is > 80%"
  alarm_actions = var.alarm_email == "" ? [] : [aws_sns_topic.alarms.arn]
}

# Alarm: ECS service running tasks below desired count
resource "aws_cloudwatch_metric_alarm" "task_count_low" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-task-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Minimum"
  threshold           = var.desired_count
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
  alarm_description = "Alarm when ECS running task count falls below desired"
  alarm_actions = var.alarm_email == "" ? [] : [aws_sns_topic.alarms.arn]
}

# Alarm: Target Group unhealthy hosts (requires target group ARN input if you want per-TG alarm)
variable "tg_arn" {
  type = string
  default = ""
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.tg_arn == "" ? 0 : 1
  alarm_name          = "${var.project_name}-${var.environment}-tg-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  dimensions = {
    TargetGroup = var.tg_arn
  }
  alarm_description = "Alarm when ALB target group reports unhealthy hosts"
  alarm_actions = var.alarm_email == "" ? [] : [aws_sns_topic.alarms.arn]
}

# SNS topic for alarm notifications
variable "alarm_email" {
  description = "Optional email to subscribe to alarm notifications (leave empty to skip)"
  type        = string
  default     = ""
}

resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.environment}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Attach SNS alarm actions
resource "aws_cloudwatch_metric_alarm" "high_cpu_with_action" {
  count = 0
  # This resource is a placeholder to document how to attach actions; we attach actions directly below by referencing aws_sns_topic.alarms.arn in existing alarms via alarm_actions attribute if desired.
}

locals {
  alarm_actions = length(aws_sns_topic.alarms.*.arn) > 0 ? [aws_sns_topic.alarms.arn] : []
}

/**
 * Attach actions to the existing alarms using separate resources is a verbose pattern in Terraform.
 * For simplicity, the next step is to manually add `alarm_actions = local.alarm_actions` to the alarm definitions above
 * if you want them wired automatically. I've left `locals.alarm_actions` available for you to incorporate.
 */
