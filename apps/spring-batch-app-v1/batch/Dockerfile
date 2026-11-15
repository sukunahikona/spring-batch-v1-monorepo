# 追加のCA証明書（任意）
#   社内プロキシや SSL スキャン（セキュリティソフト）が HTTPS を中継する環境では、
#   コンテナ内から外への通信（Gradle の依存取得・yum）が証明書エラーになる。
#   その場合だけ、ビルド時に BuildKit のシークレット extra_ca として証明書（PEM、1ファイル1枚）を渡す。
#   シークレットはその RUN の間だけマウントされ、イメージには残さない。渡さなければ何もしない（CI など）。
#   docker compose では、環境変数 EXTRA_CA_CERT_FILE に証明書のパスを指定する（README 参照）。

# マルチステージビルド - Stage 1: ビルド環境
FROM gradle:jdk21 AS builder

WORKDIR /app

# 追加のCA証明書があれば、JVM の信頼ストアに追加する（このステージは最終イメージに含まれない）
RUN --mount=type=secret,id=extra_ca,required=false \
    if [ -s /run/secrets/extra_ca ]; then \
      keytool -importcert -cacerts -storepass changeit -noprompt \
        -alias extra-ca -file /run/secrets/extra_ca; \
    fi

# Gradleキャッシュの最適化のため、依存関係定義ファイルを先にコピー
COPY build.gradle settings.gradle ./

# 依存関係を先にダウンロード（キャッシュ利用のため）
RUN gradle dependencies --no-daemon || true

# ソースコードをコピー
COPY src ./src

# アプリケーションをビルド（テストはスキップ）
RUN gradle bootJar --no-daemon -x test

# マルチステージビルド - Stage 2: 実行環境
FROM amazoncorretto:21

WORKDIR /app

# アプリケーション実行用の非rootユーザーを作成
# 追加のCA証明書があれば、yum の実行中だけ信頼ストアに追加し、終わったら外して元に戻す（イメージに残さない）
RUN --mount=type=secret,id=extra_ca,required=false \
    if [ -s /run/secrets/extra_ca ]; then \
      cp /run/secrets/extra_ca /etc/pki/ca-trust/source/anchors/extra-ca.pem && \
      update-ca-trust; \
    fi && \
    yum install -y shadow-utils && \
    groupadd -r spring && \
    useradd -r -g spring spring && \
    yum clean all && \
    rm -f /etc/pki/ca-trust/source/anchors/extra-ca.pem && \
    update-ca-trust
USER spring:spring

# ビルドステージからJARファイルをコピー
COPY --from=builder /app/build/libs/*.jar app.jar

# アプリケーション起動
ENTRYPOINT ["java"]
CMD ["-jar", "app.jar"]
