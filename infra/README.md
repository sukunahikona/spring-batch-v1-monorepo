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
| ECS タスク定義 | `spring-batch-v1-prod-spring-batch`（CPU: 512、Memory: 1024）。バッチ（`spring-batch-app`）と Fluent Bit のサイドカー（`log_router`）の2コンテナ構成 |
| ログ | バッチのログは FireLens（Fluent Bit サイドカー）経由で、CloudWatch Logs（直近30日）と S3 `spring-batch-v1-prod-batch-logs-<アカウントID>`（保持期間は無期限）の両方に出力（後述） |
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

## ログの出力（Fluent Bit サイドカー）

バッチのコンテナ（`spring-batch-app`）の標準出力は、同じタスク内の Fluent Bit（`log_router`、FireLens）が受け取り、2か所に出力します。

| 出力先 | 保持期間 | 場所 |
|---|---|---|
| CloudWatch Logs | 30日 | `/ecs/spring-batch-v1-prod-spring-batch`（ストリーム: `ecs/spring-batch-app-firelens-<タスクID>`） |
| S3 | 無期限（ライフサイクルルールなし） | `s3://spring-batch-v1-prod-batch-logs-<アカウントID>/spring-batch/<年>/<月>/<日>/...log.gz` |

- `log_router` 自身のログは、同じロググループの `firelens/` ストリームに出力します。
- Fargate では S3 上の設定ファイルを直接指定できないため、Fluent Bit の `init` イメージが、起動時に S3（`fluent-bit/s3-output.conf`）から追加設定（S3への出力）を取得します。CloudWatch Logs への出力は、タスク定義の `logConfiguration` から FireLens が生成します。
- ログの出力に使う権限は、タスクロールに付けています（`ecs_task_logs` ポリシー）。

### 異常検知との関係
異常検知（上記）は、タスク内のいずれかのコンテナの `exitCode` が 0 以外のときに通知します。EventBridge は配列内の特定のコンテナだけを条件にできないため、`log_router` は正常停止時に `exitCode` 0 で終了する前提です。通知文の `exitCode` は、先頭のコンテナ（`spring-batch-app`）から取り出しています。

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
