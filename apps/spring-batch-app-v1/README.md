# Batch Application

Spring Bootベースのバッチアプリケーションです。複数のバッチジョブを実行でき、Dockerコンテナとして動作します。

## 概要

このアプリケーションは以下のバッチジョブを提供します：

- **sampleJob**: シンプルなサンプルジョブ
- **sampleContinuingJob**: 複数ステップを順次実行するジョブ
- **parallelJob**: 複数ステップを並列実行するジョブ
- **productFetchJob**: 製品データを取得するジョブ
- **userFetchJob**: ユーザーデータを取得するジョブ

## 技術スタック

- Java 21
- Spring Boot 4.0.1
- Spring Batch
- MyBatis
- PostgreSQL 16
- Gradle 9.2.1
- Docker / Docker Compose

## 前提条件

- Docker
- Docker Compose

## セットアップ

### 1. PostgreSQLの起動

```bash
docker compose up -d postgres
```

データベースが起動し、以下の設定で利用可能になります：
- データベース名: `batchdb`
- ユーザー名: `batchuser`
- パスワード: `batchpass`
- ポート: `5432`

### 2. バッチアプリケーションのイメージをビルド

```bash
docker compose build batch-app
```

マルチステージビルドにより、以下の構成でイメージが作成されます：
- ビルド環境: AWS ECR Public - Gradle (with JDK 21)
- 実行環境: AWS ECR Public - Amazon Corretto 21

## 実行方法

### デフォルトジョブの実行

環境変数を指定しない場合、`sampleJob`が実行されます。

```bash
docker compose run --rm batch-app
```

### 特定のジョブを実行

環境変数`JOB_NAME`でジョブを指定できます。

#### productFetchJobの実行

```bash
docker compose run --rm -e JOB_NAME=productFetchJob batch-app
```

#### userFetchJobの実行

```bash
docker compose run --rm -e JOB_NAME=userFetchJob batch-app
```

#### sampleContinuingJobの実行

```bash
docker compose run --rm -e JOB_NAME=sampleContinuingJob batch-app
```

#### parallelJobの実行

```bash
docker compose run --rm -e JOB_NAME=parallelJob batch-app
```

### 環境変数での実行（別の方法）

```bash
JOB_NAME=productFetchJob docker compose run --rm batch-app
```

## ローカル開発

### ローカル環境での実行

PostgreSQLが起動している状態で、以下のコマンドでバッチを実行できます。

```bash
# デフォルトジョブ
./gradlew bootRun

# 特定のジョブを指定
./gradlew bootRun --args='--JOB_NAME=productFetchJob'
```

### ビルド

```bash
./gradlew build
```

### テスト

```bash
./gradlew test
```

## プロジェクト構成

```
batch-app/
├── batch/
│   └── Dockerfile              # バッチアプリケーション用Dockerfile
├── src/
│   └── main/
│       ├── java/
│       │   └── org/sukunahikona/batch_app/
│       │       ├── config/
│       │       │   ├── BatchJobConfiguration.java       # サンプルジョブの設定
│       │       │   └── BatchRdsJobConfiguration.java    # RDS関連ジョブの設定
│       │       ├── tasklet/
│       │       ├── service/
│       │       ├── mapper/
│       │       └── entity/
│       └── resources/
│           ├── application.properties
│           └── mapper/
├── docker-compose.yml
├── build.gradle
└── README.md
```

## バッチジョブ設定の分割について

バッチジョブの設定は複数のConfigurationファイルに分割できます。`@Configuration`アノテーションを付けたクラスを作成することで、Spring Containerが自動的に検出します。

現在は以下のように分割されています：
- `BatchJobConfiguration.java`: サンプルジョブ、並列実行ジョブ
- `BatchRdsJobConfiguration.java`: RDS操作ジョブ

## トラブルシューティング

### PostgreSQLに接続できない

PostgreSQLコンテナが起動しているか確認してください。

```bash
docker compose ps
```

### ジョブが実行されない

環境変数`JOB_NAME`が正しく指定されているか確認してください。存在しないジョブ名を指定するとエラーになります。

### ビルドに失敗する

Docker Composeを使用してビルドする場合、インターネット接続が必要です。プロキシ環境下では適切な設定が必要な場合があります。

## CI/CD

このプロジェクトはDockerを使用したCI/CDパイプラインに対応しています。`batch/Dockerfile`を使用してコンテナイメージをビルドし、各環境にデプロイできます。

```bash
# イメージのビルド
docker compose build batch-app

# イメージのタグ付け
docker tag batch-app-batch-app:latest your-registry/batch-app:v1.0.0

# レジストリへのプッシュ
docker push your-registry/batch-app:v1.0.0
```

## ライセンス

このプロジェクトはデモ用のサンプルアプリケーションです。