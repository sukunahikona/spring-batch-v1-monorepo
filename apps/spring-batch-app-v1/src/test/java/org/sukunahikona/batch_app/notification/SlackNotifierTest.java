package org.sukunahikona.batch_app.notification;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class SlackNotifierTest {

    @Test
    void WebhookURLが未設定または形式不正なら無効() {
        assertFalse(new SlackNotifier("").isEnabled());
        assertFalse(new SlackNotifier("dummy").isEnabled());
        assertFalse(new SlackNotifier("https://example.com/hook").isEnabled());
        assertTrue(new SlackNotifier("https://hooks.slack.com/services/T000/B000/XXXX").isEnabled());
    }

    @Test
    void 無効時は通信せず例外も出さない() {
        assertDoesNotThrow(() -> new SlackNotifier("dummy").notify("テスト"));
    }

    @Test
    void JSON特殊文字をエスケープする() {
        assertEquals("a\\\"b\\\\c\\nd", SlackNotifier.escapeJson("a\"b\\c\nd"));
    }
}
