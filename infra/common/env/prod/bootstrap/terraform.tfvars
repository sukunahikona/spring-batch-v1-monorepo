project           = "spring-batch-v1"
environment       = "prod"
region            = "ap-northeast-1"
state_bucket_name = "spring-batch-v1-terraform-state"

# RDS認証情報（SSM Parameter Storeに保存）
# 初期値はdummy。AWS ConsoleまたはCLIで直接SSMパラメータを更新してください
rds_credentials = {
  username = "dummy"
  password = "dummy"
}
