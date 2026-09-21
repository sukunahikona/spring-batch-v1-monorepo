#!/bin/bash

###############################################################################
# ECRへのDockerイメージのビルド＆プッシュスクリプト
###############################################################################

set -e

# アプリのソース位置（monorepoルートの apps/spring-batch-app-v1）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/../../../../apps/spring-batch-app-v1"

# 設定
AWS_REGION="ap-northeast-1"
PROJECT="spring-batch-v1"
# 環境指定
ENVIRONMENT="prod"
ECR_REPOSITORY_NAME="${PROJECT}-${ENVIRONMENT}-spring-batch-app-v1"
IMAGE_TAG="${1:-latest}"

echo "================================================================"
echo "Spring Batch App - ECR Push Script"
echo "================================================================"
echo "Repository: ${ECR_REPOSITORY_NAME}"
echo "Image Tag:  ${IMAGE_TAG}"
echo "AWS Region: ${AWS_REGION}"
echo ""

# AWSアカウントIDを取得
echo "[Step 1] AWSアカウント情報を取得"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URL}/${ECR_REPOSITORY_NAME}:${IMAGE_TAG}"
echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
echo ""

###############################################################################
# ビルドステップ
###############################################################################
echo "================================================================"
echo "ビルドステップ"
echo "================================================================"

echo "[Step 2] Dockerイメージをビルド"
(cd "${APP_DIR}" && docker build -f batch/Dockerfile -t ${ECR_REPOSITORY_NAME}:${IMAGE_TAG} .)
echo ""

echo "[Step 3] ECR用のタグを付与"
docker tag ${ECR_REPOSITORY_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}
echo "Tagged: ${FULL_IMAGE_NAME}"
echo ""

###############################################################################
# プッシュステップ
###############################################################################
echo "================================================================"
echo "プッシュステップ"
echo "================================================================"

echo "[Step 4] ECRにログイン"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}
echo ""

echo "[Step 5] ECRにプッシュ"
docker push ${FULL_IMAGE_NAME}
echo ""

echo "================================================================"
echo "完了"
echo "================================================================"
echo "Image: ${FULL_IMAGE_NAME}"
echo ""
