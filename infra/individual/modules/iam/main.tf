###############################################################################
# GitHub Actions OIDC Provider
###############################################################################
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

###############################################################################
# IAM Role - GitHub Actions から Spring Batch のデプロイ用
###############################################################################
resource "aws_iam_role" "github_actions_spring_batch" {
  name = "${var.project}-${var.environment}-github-actions-spring-batch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.environment}-github-actions-spring-batch"
  }
}

###############################################################################
# IAM Policy - ECR プッシュ権限
###############################################################################
resource "aws_iam_policy" "ecr_push" {
  name        = "${var.project}-${var.environment}-ecr-push-policy"
  description = "GitHub Actions から ECR へのイメージプッシュに必要な権限"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 認証トークン取得（アカウントレベル）
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        # イメージのプッシュ（リポジトリレベル）
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.github_actions_spring_batch.name
  policy_arn = aws_iam_policy.ecr_push.arn
}
