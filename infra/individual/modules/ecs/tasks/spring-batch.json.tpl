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
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
