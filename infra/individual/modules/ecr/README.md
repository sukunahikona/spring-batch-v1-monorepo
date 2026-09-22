# ECR モジュール

## 概要

このモジュールは、Spring Batch アプリケーション用の Amazon ECR (Elastic Container Registry) リポジトリを管理します。

## 前提条件

アプリケーションのソースは、同一リポジトリの `apps/spring-batch-app-v1` にあります（別途 clone は不要です）。

## 使用方法

イメージのビルドと ECR へのプッシュは、次のいずれかで行います。

### 1. スクリプトで手動プッシュ

```bash
# monorepoルートから実行（AWS認証済みであること）
./infra/individual/modules/ecr/push-to-ecr.sh [イメージタグ]
```

### 2. GitHub Actions でプッシュ

`.github/workflows/deploy.yml` を、Actions タブの **Run workflow** でブランチを選んで手動実行します（`push_image` を ON。テスト → ビルド → ECR プッシュ）。
AWS への認証は GitHub Environments（`prod`）と OIDC で行います。ロールの ARN はワークフロー内の `AWS_ROLE_ARN` に記載しています（individual スタックの出力 `github_actions_role_arn` と同じ値）。

### 3. コマンドで手動プッシュ

```bash
# ECR にログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com

# イメージをビルド・タグ付け
docker build -f apps/spring-batch-app-v1/batch/Dockerfile -t spring-batch-app-v1:latest apps/spring-batch-app-v1
docker tag spring-batch-app-v1:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/spring-batch-v1-prod-spring-batch-app-v1:latest

# イメージをプッシュ
docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/spring-batch-v1-prod-spring-batch-app-v1:latest
```
