[
  {
    "name": "spring-batch-app",
    "image": "${ecr_repository_url}:latest",
    "essential": true,
    "environment": [
      {
        "name": "JOB_NAME",
        "value": "sampleJob"
      },
      {
        "name": "SPRING_DATASOURCE_URL",
        "value": "jdbc:postgresql://${rds_endpoint}/${db_name}"
      },
      {
        "name": "TZ",
        "value": "Asia/Tokyo"
      }
    ],
    "secrets": [
      {
        "name": "SPRING_DATASOURCE_USERNAME",
        "valueFrom": "/${project}/${environment}/rds/username"
      },
      {
        "name": "SPRING_DATASOURCE_PASSWORD",
        "valueFrom": "/${project}/${environment}/rds/password"
      },
      {
        "name": "SLACK_WEBHOOK_URL",
        "valueFrom": "/${project}/${environment}/slack/webhook_url"
      }
    ],
    "logConfiguration": {
      "logDriver": "awsfirelens",
      "options": {
        "Name": "cloudwatch_logs",
        "region": "${region}",
        "log_group_name": "${log_group_name}",
        "log_stream_prefix": "ecs/",
        "auto_create_group": "false"
      }
    }
  },
  {
    "name": "log_router",
    "image": "${log_router_image}",
    "essential": true,
    "memoryReservation": 64,
    "stopTimeout": 60,
    "environment": [
      {
        "name": "aws_fluent_bit_init_s3_1",
        "value": "${fluent_bit_config_s3_arn}"
      }
    ],
    "firelensConfiguration": {
      "type": "fluentbit",
      "options": {
        "enable-ecs-log-metadata": "true"
      }
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${fluent_bit_log_group_name}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
