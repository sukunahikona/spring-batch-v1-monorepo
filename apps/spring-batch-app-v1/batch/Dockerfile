# マルチステージビルド - Stage 1: ビルド環境
FROM public.ecr.aws/docker/library/gradle:jdk21 AS builder

WORKDIR /app

# Gradleキャッシュの最適化のため、依存関係定義ファイルを先にコピー
COPY build.gradle settings.gradle ./

# 依存関係を先にダウンロード（キャッシュ利用のため）
RUN gradle dependencies --no-daemon || true

# ソースコードをコピー
COPY src ./src

# アプリケーションをビルド（テストはスキップ）
RUN gradle bootJar --no-daemon -x test

# マルチステージビルド - Stage 2: 実行環境
FROM public.ecr.aws/amazoncorretto/amazoncorretto:21

WORKDIR /app

# アプリケーション実行用の非rootユーザーを作成
RUN yum install -y shadow-utils && \
    groupadd -r spring && \
    useradd -r -g spring spring && \
    yum clean all
USER spring:spring

# ビルドステージからJARファイルをコピー
COPY --from=builder /app/build/libs/*.jar app.jar

# アプリケーション起動
ENTRYPOINT ["java"]
CMD ["-jar", "app.jar"]