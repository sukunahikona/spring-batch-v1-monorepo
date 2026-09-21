package org.sukunahikona.batch_app.notification;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Slack の Incoming Webhook へメッセージを投稿する。
 * Webhook URL が未設定、または https://hooks.slack.com/ 以外の場合は何もしない（ローカル実行・テスト用）。
 * 投稿に失敗してもジョブは失敗させず、警告ログのみ出力する（Webhook URL は秘密情報のためログに出さない）。
 */
@Component
public class SlackNotifier {

    private static final Logger log = LoggerFactory.getLogger(SlackNotifier.class);
    private static final String WEBHOOK_URL_PREFIX = "https://hooks.slack.com/";

    private final String webhookUrl;
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    public SlackNotifier(@Value("${slack.webhook-url:}") String webhookUrl) {
        this.webhookUrl = webhookUrl.trim();
        if (!this.webhookUrl.isEmpty() && !isEnabled()) {
            log.warn("slack.webhook-url が Slack の Webhook URL 形式ではないため、Slack通知は無効です");
        }
    }

    public boolean isEnabled() {
        return webhookUrl.startsWith(WEBHOOK_URL_PREFIX);
    }

    public void notify(String text) {
        if (!isEnabled()) {
            return;
        }
        String body = "{\"text\":\"" + escapeJson(text) + "\"}";
        HttpRequest request = HttpRequest.newBuilder(URI.create(webhookUrl))
                .timeout(Duration.ofSeconds(10))
                .header("Content-Type", "application/json; charset=utf-8")
                .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                .build();
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            // 成功時は HTTP 200 と本文 "ok" が返る
            if (response.statusCode() != 200) {
                log.warn("Slack通知に失敗しました: status={}, body={}", response.statusCode(), response.body());
            }
        } catch (IOException | IllegalArgumentException e) {
            log.warn("Slack通知に失敗しました: {}", e.getClass().getSimpleName());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Slack通知が中断されました");
        }
    }

    static String escapeJson(String value) {
        StringBuilder sb = new StringBuilder(value.length() + 16);
        for (char c : value.toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
                }
            }
        }
        return sb.toString();
    }
}
