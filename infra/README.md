# インフラ構成（Terraform）

Spring Batch アプリケーション（`apps/spring-batch-app-v1`）を AWS 上で定期実行するためのインフラを Terraform で管理します。
リポジトリ全体の構成は [ルートREADME](../README.md) を参照してください。

---

## ディレクトリ構成

```
infra/
├── common/                          # 共有インフラ（VPC・RDS・IAMなど）
│   ├── env/prod/                    # prod環境エントリーポイント
│   │   └── bootstrap/               # Terraformバックエンド（S3）初期構築用
│   └── modules/
│       ├── iam/                     # OIDC Provider（GitHub Actions用）
│       ├── rds/                     # RDS PostgreSQL（Multi-AZ）
│       ├── s3/                      # S3バケット
│       ├── ssm_parameter/           # SSM Parameter Store（RDS認証情報・Slack Webhook URL）
│       └── vpc/                     # VPC・サブネット・NAT・Bastion
│
└── individual/                      # アプリ個別インフラ（ECR・ECS・EventBridgeなど）
    ├── env/prod/                    # prod環境エントリーポイント
    └── modules/
        ├── ecr/                     # ECRリポジトリ（spring-batch-app-v1）
        ├── ecs/                     # ECSクラスタ・タスク定義・IAMロール・SG
        ├── ecs_alert/               # ECSタスク異常の検知（EventBridge + API destination → Slack）
        ├── eventbridge/             # EventBridge Schedulerによる定期実行
        └── iam/                     # GitHub Actions用IAMロール（ECRプッシュ・ECS単発タスク実行権限）
```

---

## アーキテクチャ概要

```mermaid
graph TB
    subgraph GitHub
        GHA[GitHub Actions]
    end

    subgraph AWS
        ECR[ECR\nspring-batch-app-v1]
        EBS[EventBridge Scheduler\nsampleJob / userFetchJob\n1時間に1回実行]
        SSM[SSM Parameter Store\nDB認証情報 / Slack Webhook URL]
        CWL[CloudWatch Logs]

        subgraph VPC / プライベートサブネット ap-northeast-1a / 1c
            ECS[ECS Fargate\nspring-batch-v1-prod-cluster]
            RDS[(RDS PostgreSQL\nMulti-AZ\nspringbatchdb)]
        end
    end

    GHA -->|docker push| ECR
    GHA -->|RunTask（DB初期化）| ECS
    EBS -->|RunTask| ECS
    ECS -->|イメージ取得| ECR
    ECS -->|認証情報取得| SSM
    ECS -->|DB接続| RDS
    ECS -->|ログ出力| CWL
    ECS -->|開始・終了通知| SLACK[Slack\nIncoming Webhook]
    ECS -.->|Task State Change| EVR[EventBridge Rule\n異常終了のみ]
    EVR -->|API destination| SLACK
```

GitHub Actions は、GitHub Environments（`prod`）を使った OIDC 認証で IAM ロールを引き受けます。
詳細は [ルートREADME](../README.md) の「CI/CD」を参照してください。

### ネットワーク構成図（Terraform の定義に基づく）

```mermaid
flowchart TB
    subgraph EXT["外部"]
        DEV["運用者<br/>(SSH)"]
        GHA["GitHub Actions<br/>(Environment: prod)"]
        SLACK["Slack<br/>Incoming Webhook"]
    end

    subgraph AWS["AWS (ap-northeast-1)"]
        subgraph MGMT["アカウント共通 / サービス"]
            OIDC["IAM OIDC Provider<br/>+ GitHub Actions用ロール"]
            ECR["ECR<br/>spring-batch-app-v1"]
            SSM["SSM Parameter Store<br/>RDS認証情報 / Slack Webhook URL"]
            CWL["CloudWatch Logs<br/>/ecs/...-spring-batch"]
            S3["S3<br/>Terraform state"]
        end

        subgraph EVENTS["EventBridge"]
            SCH["Scheduler x2<br/>sampleJob / userFetchJob<br/>rate(1 hour) Asia/Tokyo"]
            RULE["Rule<br/>ECS Task State Change<br/>起動失敗 / exitCode≠0"]
            APID["API destination<br/>+ Connection"]
        end

        subgraph VPC["VPC 10.0.0.0/16"]
            IGW["Internet Gateway"]

            subgraph PUB["パブリックサブネット 10.0.1.0/24 (1a) / 10.0.2.0/24 (1c)"]
                NAT["NAT Gateway"]
                BASTION["Bastion EC2<br/>t3.micro (SSH:22)"]
            end

            subgraph PRI["プライベートサブネット 10.0.11.0/24 (1a) / 10.0.12.0/24 (1c)"]
                ECS["ECS Fargate タスク<br/>cluster: ...-prod-cluster<br/>CPU 512 / Mem 1024"]
                RDS[("RDS PostgreSQL 16<br/>db.t3.micro / Multi-AZ<br/>springbatchdb :5432")]
            end
        end
    end

    %% 定期実行
    SCH -->|RunTask| ECS

    %% アプリの通信
    ECS -->|"5432"| RDS
    ECS -->|"認証情報 (secrets)"| SSM
    ECS -->|ログ| CWL
    ECS -->|"イメージ取得 (NAT経由)"| NAT
    NAT --> IGW
    IGW -.-> ECR
    ECS -->|"開始・終了通知 (NAT経由)"| NAT
    IGW -.-> SLACK

    %% 異常検知
    ECS -.->|Task State Change| RULE
    RULE --> APID
    APID -->|HTTPS POST| SLACK
    SSM -.->|"Terraform が Webhook URL を読み取り設定"| APID

    %% 運用・CI/CD
    DEV -->|SSH| BASTION
    BASTION -->|"DB接続"| RDS
    GHA -->|OIDC| OIDC
    GHA -->|docker push| ECR
    GHA -->|"RunTask (DB初期化)"| ECS
```

- ECS タスクと RDS はプライベートサブネットに置き、パブリック IP は付けません（`assign_public_ip = false`）。外部への通信（ECR・Slack など）は NAT Gateway を経由します。
- RDS のセキュリティグループは、プライベートサブネットの CIDR と Bastion からの 5432 を許可します。
- 異常検知（EventBridge ルール → API destination → Slack）は、`JOB_NAME` を指定して起動したタスクだけが対象です。
- Terraform の state は S3 に保存します（`bootstrap` で作成）。図が煩雑になるため、state に接続する線は省略しています。

---

## Terraformスタック構成

本リポジトリは **2つの独立したTerraformスタック**で管理されています。

| スタック | ディレクトリ | 用途 |
|---|---|---|
| common | `common/env/prod/` | VPC・RDS・S3など共有インフラ |
| individual | `individual/env/prod/` | ECR・ECS・EventBridgeなどアプリ個別インフラ |

`individual` スタックは `common` スタックのリソースを AWS データソースで参照します。

---

## 主要リソース

### common スタック

| リソース | 内容 |
|---|---|
| VPC | `10.0.0.0/16`、パブリック×2 / プライベート×2（ap-northeast-1a, 1c） |
| NAT Gateway | パブリックサブネットに配置 |
| Bastion | パブリックサブネットに配置（SSH踏み台） |
| RDS PostgreSQL | `db.t3.micro`、Multi-AZ、暗号化有効、`springbatchdb` |
| SSM Parameter Store | RDS認証情報（`/spring-batch-v1/prod/rds/username`, `password`）とSlack Webhook URL（`/spring-batch-v1/prod/slack/webhook_url`）。`bootstrap` で作成し、値は初回作成後にConsoleやCLIで更新する |

### individual スタック

| リソース | 内容 |
|---|---|
| ECR | `spring-batch-v1-prod-spring-batch-app-v1`（最新30イメージ保持） |
| ECS クラスタ | `spring-batch-v1-prod-cluster`（Fargate、Container Insights有効） |
| ECS タスク定義 | `spring-batch-v1-prod-spring-batch`（CPU: 512、Memory: 1024） |
| EventBridge Scheduler | `sampleJob`・`userFetchJob` を1時間に1回実行（`batch_schedule_state` で停止可能） |
| ECSタスク異常検知 | EventBridge ルール（ECS Task State Change）と API destination。起動失敗・異常終了したタスクを Slack へ通知（後述） |
| IAM（GitHub Actions） | OIDC経由（Environment `prod` のジョブのみ許可）で、ECRプッシュ権限と、ECS単発タスクの起動・確認権限（DB初期化用）を付与 |

---

## ECSタスクの異常検知（Slack通知）

対象クラスタ（`spring-batch-v1-prod-cluster`）で、定期実行のタスクが**起動に失敗した**、または**起動直後に異常終了した**ときに、Slack へ通知します。
ジョブの起動後の例外は、アプリ内の通知（`SlackJobExecutionListener`）が担当します。ここでは、アプリが通知できない場合（イメージの取得失敗、シークレットの取得失敗、起動直後のクラッシュなど）を拾います。

| 検知する条件 | 例 |
|---|---|
| 起動失敗（`stopCode = TaskFailedToStart`） | イメージの取得失敗、シークレットの取得失敗 |
| コンテナの `exitCode` が 0 以外で `STOPPED` | DB 接続失敗による起動時クラッシュ、OOM（137） |

対象は、環境変数 `JOB_NAME` を指定して起動したタスク（EventBridge Scheduler による定期実行）のみです。CI の DB 初期化タスクは、CI 側で失敗が分かるため対象外です。
正常終了（`exitCode = 0`）や実行中の状態変化は通知しません。

通知内容: バッチ識別子（`JOB_NAME`）、停止コード、`exitCode`、理由（`stoppedReason`）、タスク ARN、時刻、ログの場所

構成は `EventBridge ルール → API destination（Slack Incoming Webhook）` です（Lambda は使いません）。
Webhook URL は、アプリと同じ SSM の `/spring-batch-v1/prod/slack/webhook_url` を Terraform が読み込んで API destination に設定します。

> **注意**
> - Webhook URL は **tfstate に含まれ**、EventBridge のコンソールでも参照できます（state の S3 バケットとコンソールは、閲覧できるユーザーを限定している前提です）。
> - SSM の値を更新したときは、`terraform apply` で反映します（初期値の `dummy` のままだと apply が失敗します）。
> - `JOB_NAME` は、定期実行の上書き設定（`JOB_NAME` のみ）の先頭にある前提で、位置を指定して取り出しています。上書きする環境変数を増やす場合は、`ecs_alert` モジュールの `input_paths` を確認してください。

---

## 定期実行の停止・再開

EventBridge Scheduler の状態は、`infra/individual/env/prod/terraform.tfvars` の `batch_schedule_state` で切り替えます。

| 値 | 動作 |
|---|---|
| `ENABLED` | `sampleJob`・`userFetchJob` を1時間に1回実行する（現在の設定） |
| `DISABLED` | 定期実行を停止する |

```bash
cd infra/individual/env/prod
terraform apply   # tfvars の値を変更してから実行
```

---

## Spring Batch ジョブ一覧

| ジョブ名 | 概要 |
|---|---|
| `sampleJob` | 基本サンプルジョブ |
| `sampleContinuingJob` | 継続処理サンプルジョブ |
| `parallelJob` | 並列処理ジョブ |
| `productFetchJob` | RDSからProduct情報を取得 |
| `userFetchJob` | RDSからUser情報を取得 |

---

## Terraform 操作手順

### 初回セットアップ

```bash
# バックエンド（S3）の初期構築
cd infra/common/env/prod/bootstrap
terraform init && terraform apply

# common スタック
cd infra/common/env/prod
terraform init && terraform apply

# individual スタック
cd infra/individual/env/prod
terraform init && terraform apply
```

### 通常のapply

```bash
cd infra/common/env/prod      # または infra/individual/env/prod
terraform plan
terraform apply
```

---

## ECS タスクの手動実行

```bash
aws ecs run-task \
  --cluster spring-batch-v1-prod-cluster \
  --task-definition spring-batch-v1-prod-spring-batch \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxx,subnet-yyyy],securityGroups=[sg-xxxx],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"spring-batch-app","environment":[{"name":"JOB_NAME","value":"productFetchJob"}]}]}'
```

サブネットID・SGIDは以下で確認できます。

```bash
cd infra/individual/env/prod
terraform output ecs_private_subnet_ids
terraform output ecs_task_security_group_id
```

---

## ローカル開発

```bash
cd apps/spring-batch-app-v1   # monorepoルートから

# PostgreSQL 起動
docker compose up -d postgres

# バッチ実行（ジョブ名を指定）
JOB_NAME=productFetchJob docker compose up batch-app
```

ローカルDB接続情報：

| 項目 | 値 |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `batchdb` |
| Username | `batchuser` |
| Password | `batchpass` |
