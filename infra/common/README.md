# common - Terraform Infrastructure

## ディレクトリ構成

```
common/
├── bootstrap/              # 初回セットアップ用（ローカルステート）
│   ├── main.tf             # S3ステートバケット作成
│   ├── variables.tf
│   └── terraform.tfvars
├── env/
│   └── prod/               # 本番環境（S3バックエンド）
│       ├── backend.tf      # S3リモートステート設定
│       ├── main.tf         # モジュール呼び出し
│       ├── provider.tf     # AWS/TLS/Localプロバイダー設定
│       ├── variables.tf    # 変数宣言
│       └── terraform.tfvars # 変数値
└── modules/
    ├── s3/                 # S3バケットモジュール
    │   ├── main.tf         # バケット + バージョニング + 暗号化 + パブリックアクセスブロック
    │   ├── variables.tf
    │   └── outputs.tf
    └── vpc/                # VPCモジュール
        ├── main.tf         # VPC, サブネット, IGW, NAT, ルートテーブル, 踏み台EC2
        ├── variables.tf
        └── outputs.tf
```

## ネットワーク構成

- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24 (ap-northeast-1a), 10.0.2.0/24 (ap-northeast-1c)
- **Private Subnets**: 10.0.11.0/24 (ap-northeast-1a), 10.0.12.0/24 (ap-northeast-1c)
- **Internet Gateway**: パブリックサブネットからインターネットへのルーティング
- **NAT Gateway**: プライベートサブネットからインターネットへのアウトバウンド通信

## 踏み台サーバー (Bastion)

- **OS**: Ubuntu 24.04 LTS
- **配置**: Public Subnet (10.0.1.0/24, ap-northeast-1a)
- **インスタンスタイプ**: t3.micro
- **SSHキー**: `bastion-key.pem`（リポジトリルートに生成）

### 接続方法

```bash
ssh -i bastion-key.pem ubuntu@<BASTION_PUBLIC_IP>
```

## セットアップ手順

### 1. 初回セットアップ（S3ステートバケット作成）

```bash
cd common/bootstrap
terraform init
terraform apply
```

### 2. インフラ構築

```bash
cd common/env/prod
terraform init
terraform apply
```

## Terraform バージョン

- Terraform: >= 1.14.0
- AWS Provider: ~> 5.0
- TLS Provider: ~> 4.0
- Local Provider: ~> 2.0
