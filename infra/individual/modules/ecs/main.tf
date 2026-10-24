###############################################################################
# CloudWatch Log Group
###############################################################################
resource "aws_cloudwatch_log_group" "spring_batch" {
  name              = "/ecs/${var.project}-${var.environment}-spring-batch"
  retention_in_days = 30

  tags = {
    Name = "/ecs/${var.project}-${var.environment}-spring-batch"
  }
}

###############################################################################
# ECS クラスタ
###############################################################################
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project}-${var.environment}-cluster"
  }
}

###############################################################################
# ECS タスク用セキュリティグループ
###############################################################################
resource "aws_security_group" "ecs_task" {
  name        = "${var.project}-${var.environment}-ecs-task-sg"
  description = "Security group for ECS Spring Batch tasks"
  vpc_id      = var.vpc_id

  # アウトバウンド（ECR pull・RDS接続・SSM・CloudWatch Logs）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecs-task-sg"
  }
}

###############################################################################
# ECS タスク定義（Spring Batch）
###############################################################################
resource "aws_ecs_task_definition" "spring_batch" {
  family                   = "${var.project}-${var.environment}-spring-batch"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.batch_cluster.task_cpu
  memory                   = var.batch_cluster.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = templatefile("${path.module}/tasks/spring-batch.json.tpl", {
    ecr_repository_url = var.ecr_repository_url
    rds_endpoint       = var.rds_endpoint
    db_name            = var.db_name
    project            = var.project
    environment        = var.environment
    region             = var.region
    log_group_name     = aws_cloudwatch_log_group.spring_batch.name

    # Fluent Bit サイドカー（init イメージが S3 の追加設定を取得する）
    log_router_image         = var.log_router_image
    fluent_bit_config_s3_arn = "${aws_s3_bucket.batch_logs.arn}/${aws_s3_object.fluent_bit_s3_output.key}"
  })

  tags = {
    Name = "${var.project}-${var.environment}-spring-batch"
  }
}
