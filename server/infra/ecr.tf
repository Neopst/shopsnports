variable "ecr_repository_name" {
  description = "Name for the ECR repository"
  type        = string
  default     = "shopsnports"
}

resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
  tags = {
    Name = var.ecr_repository_name
  }
}

resource "aws_ecr_lifecycle_policy" "retention" {
  repository = aws_ecr_repository.app.name
  policy     = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images and remove untagged older than 14 days"
        selection = {
          tagStatus = "any"
          countType = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
