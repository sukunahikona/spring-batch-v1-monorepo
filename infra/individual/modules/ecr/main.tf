###############################################################################
# ECR Repository for Spring Batch App
###############################################################################
resource "aws_ecr_repository" "spring_batch_app" {
  name                 = "${var.project}-${var.environment}-spring-batch-app-v1"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project}-${var.environment}-spring-batch-app-v1"
    Application = "spring-batch-app-v1"
  }
}

###############################################################################
# ECR Lifecycle Policy - 古いイメージの自動削除
###############################################################################
resource "aws_ecr_lifecycle_policy" "spring_batch_app" {
  repository = aws_ecr_repository.spring_batch_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "最新の30イメージのみ保持"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
