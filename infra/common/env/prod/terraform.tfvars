project     = "spring-batch-v1"
environment = "prod"
region      = "ap-northeast-1"

# VPCモジュールの設定
vpc = {
  cidr                 = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  availability_zones   = ["ap-northeast-1a", "ap-northeast-1c"]
}

# EC2モジュールの設定
ec2 = {
  public_bastion = {
    instance_type     = "t3.micro"
    ssh_key_name      = "bastion-key"
    allowed_ssh_cidrs = ["0.0.0.0/0"]
  }
}

# RDSモジュールの設定
# username/passwordはSSM Parameter Storeから取得
rds = {
  engine                   = "postgres"
  engine_version           = "16.12"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_type             = "gp3"
  db_name                  = "springbatchdb"
  backup_retention_days    = 7
  multi_az                 = true
  #multi_az                 = false
  skip_final_snapshot      = false
  snapshot_identifier_name = null  # 復元する場合はスナップショット名を指定（例: "spring-batch-v1-prod-rds-final-snapshot-20260211-123456"）
}
