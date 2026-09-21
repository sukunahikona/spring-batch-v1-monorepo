project     = "spring-batch-v1"
environment = "prod"
region      = "ap-northeast-1"
github_org  = "sukunahikona"
github_repo = "spring-batch-v1-monorepo"

# ECS Spring Batch クラスタ設定
batch_cluster = {
  task_cpu    = 512
  task_memory = 1024
}

# EventBridge Scheduler による定期実行（ENABLED: 実行する / DISABLED: 停止する）
batch_schedule_state = "DISABLED"
