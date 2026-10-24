# ローカル実行用の Makefile（docker compose のラッパー）
#
# 実行するジョブは、up / batch の後ろの第一引数で指定する（既定: sampleJob）
#   例: make batch userFetchJob
# JOB=userFetchJob の形でも指定できる

JOB ?= sampleJob

# up / batch の後ろの引数をジョブ名として扱う。
# 引数は make にとってはターゲット名なので、何もしないターゲットとして定義して「見つからない」エラーを防ぐ
ifneq ($(filter $(firstword $(MAKECMDGOALS)),up batch),)
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifneq ($(ARGS),)
    JOB := $(firstword $(ARGS))
    $(eval $(ARGS):;@:)
  endif
endif

.DEFAULT_GOAL := help
.PHONY: help up infra dev-infra batch clean

help: ## コマンド一覧を表示する
	@echo "使い方: make <コマンド> [ジョブ名]"
	@echo ""
	@awk -F':.*## ' '/^[a-z-]+:.*## /{printf "  make %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "実行するバッチは、up / batch の後ろにジョブ名を付けて指定する（省略すると sampleJob）"
	@echo "  make batch userFetchJob   userFetchJob だけを実行する"
	@echo "  make up productFetchJob   インフラを起動して productFetchJob を実行する"
	@echo ""
	@echo "指定できるジョブ名: sampleJob / sampleContinuingJob / parallelJob / productFetchJob / userFetchJob"

up: infra batch ## インフラ（PostgreSQL）を起動し、続けてバッチを実行する

infra: ## インフラ（PostgreSQL）だけを起動する
	docker compose up -d postgres
	@echo "PostgreSQL の起動を待っています..."
	@# 初回の初期化中の一時サーバーは TCP を待ち受けないため、-h 127.0.0.1 で本起動を待つ
	@until docker compose exec -T postgres pg_isready -h 127.0.0.1 -U batchuser -d batchdb >/dev/null 2>&1; do sleep 1; done
	@echo "PostgreSQL が起動しました"

dev-infra: ## インフラ（PostgreSQL）をログ表示つきで起動する（Ctrl+C で停止）
	docker compose up postgres

batch: ## バッチだけを実行する（インフラは起動済みの前提）
	docker compose build batch-app
	docker compose run --rm -e JOB_NAME=$(JOB) batch-app

clean: ## インフラとバッチの資材（コンテナ・DBデータ・イメージ・ビルド成果物）を削除する
	docker compose down -v --rmi local --remove-orphans
	rm -rf build .gradle
