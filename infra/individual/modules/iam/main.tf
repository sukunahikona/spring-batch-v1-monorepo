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
            # subには不変IDが含まれる形式（repo:owner@ID/repo@ID:environment:名前）で発行される。
            # 指定したEnvironmentを使うジョブだけがロールを引き受けられる（ブランチはEnvironment側の設定で制御する）
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}@${var.github_org_id}/${var.github_repo}@${var.github_repo_id}:environment:${var.github_environment}"
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

###############################################################################
# IAM Policy - ECS 単発タスクの実行権限（DBスキーマ投入などをCIから実行するため）
###############################################################################
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ecs_run_task" {
  name        = "${var.project}-${var.environment}-ecs-run-task-policy"
  description = "GitHub Actions から ECS の単発タスクを起動・確認するために必要な権限"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 指定クラスタ上で、指定タスク定義(family)のタスクだけ起動できる
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.ecs_task_definition_family}:*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.ecs_cluster_arn
          }
        }
      },
      {
        # 起動したタスクの状態確認・停止（指定クラスタのタスクに限定）
        Effect   = "Allow"
        Action   = ["ecs:DescribeTasks", "ecs:StopTask"]
        Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task/${var.ecs_cluster_name}/*"
      },
      {
        # タスクに渡すロールは、実行ロールとタスクロールのみ（ECSタスク用途に限定）
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = var.ecs_pass_role_arns
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        # 起動先のサブネット・セキュリティグループの参照（読み取りのみ。リソース指定不可）
        Effect   = "Allow"
        Action   = ["ec2:DescribeSubnets", "ec2:DescribeSecurityGroups"]
        Resource = "*"
      },
      {
        # タスクのログ参照（バッチタスクのロググループに限定）
        Effect   = "Allow"
        Action   = "logs:GetLogEvents"
        Resource = "${var.ecs_log_group_arn}:log-stream:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_run_task" {
  role       = aws_iam_role.github_actions_spring_batch.name
  policy_arn = aws_iam_policy.ecs_run_task.arn
}
