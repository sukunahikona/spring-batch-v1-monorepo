project            = "spring-batch-v1"
environment        = "prod"
region             = "ap-northeast-1"
github_org         = "sukunahikona"
github_org_id      = "127575809" # OIDCトークンのsubに含まれるオーナーID
github_repo        = "spring-batch-v1-monorepo"
github_repo_id     = "1380617590" # OIDCトークンのsubに含まれるリポジトリID
github_environment = "prod"       # GitHub Environments の名前

# ECS Spring Batch クラスタ設定
batch_cluster = {
  task_cpu    = 512
  task_memory = 1024
}

# EventBridge Scheduler による定期実行（ENABLED: 実行する / DISABLED: 停止する）
batch_schedule_state = "DISABLED"
