# spring-batch-v1-monorepo

Spring Batch アプリケーションと、それを AWS（ECS Fargate + EventBridge Scheduler + RDS）で動かすための Terraform インフラを一つにまとめたモノレポです。

## ディレクトリ構成

```
.
├── apps/
│   └── spring-batch-app-v1/   # Spring Boot / Spring Batch アプリ（Java 21, Gradle）
├── infra/
│   ├── common/                # 共有インフラ（VPC・RDS・S3・OIDC Provider）
│   └── individual/            # アプリ個別インフラ（ECR・ECS・EventBridge・GitHub Actions用IAM）
└── .github/workflows/         # CI/CD（テスト → イメージビルド → ECRプッシュ）
```

| 対象 | 詳細ドキュメント |
|---|---|
| アプリ | [apps/spring-batch-app-v1/README.md](apps/spring-batch-app-v1/README.md) |
| インフラ | [infra/README.md](infra/README.md) |

## CI/CD

GitHub Actions のワークフローはリポジトリルートの `.github/workflows/` に置いています。

| ワークフロー | 役割 |
|---|---|
| `prod-deployment.yml` | エントリーポイント。PR（`apps/spring-batch-app-v1/**` または `.github/workflows/**` の変更時）と手動実行で起動 |
| `unit-test.yml` | ユニットテスト（再利用ワークフロー） |
| `build.yml` | Docker イメージのビルド（再利用ワークフロー） |
| `push.yml` | OIDC 認証で ECR へプッシュ（再利用ワークフロー） |

### 初期設定

1. `infra/common/env/prod/bootstrap` → `infra/common/env/prod` → `infra/individual/env/prod` の順に `terraform apply`
2. individual スタックの出力 `github_actions_role_arn` を、このリポジトリのシークレット `AWS_DEPLOY_ROLE_ARN` に登録

IAM ロールの信頼ポリシーは `infra/individual/env/prod/terraform.tfvars` の `github_org` / `github_repo`（= 本リポジトリ）に紐づきます。

## 命名規則

Terraform の `project`（`spring-batch-v1`）と `environment`（`prod`）から、AWS リソース名が `spring-batch-v1-prod-*` の形で決まります。
プロジェクト名を変える場合は、次の箇所を揃えて変更してください（S3 バケット名はグローバルで一意）。

- `infra/common/env/prod/terraform.tfvars` / `infra/individual/env/prod/terraform.tfvars` / `infra/common/env/prod/bootstrap/terraform.tfvars` の `project`
- `infra/common/env/prod/bootstrap/terraform.tfvars` の `state_bucket_name`
- 両スタックの `backend.tf` の `bucket`（Terraform の制約で変数化できない）
- `infra/individual/modules/ecr/push-to-ecr.sh` の `PROJECT`
- `.github/workflows/prod-deployment.yml` の `ecr_repository`
