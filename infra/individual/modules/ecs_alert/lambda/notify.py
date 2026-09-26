"""ECS Task State Change（異常終了）を Slack へ通知する Lambda。

EventBridge ルールが、対象クラスタで次のどちらかに該当したタスクだけを渡してくる。
  - コンテナの exitCode が 0 以外で STOPPED になった
  - 起動に失敗した（stopCode = TaskFailedToStart。イメージ取得失敗など）
"""
import json
import logging
import os
import urllib.request

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SLACK_WEBHOOK_PREFIX = "https://hooks.slack.com/"
MAX_REASON_LENGTH = 500

_ssm = boto3.client("ssm")
_webhook_url = None


def _get_webhook_url():
    """Webhook URL を SSM から取得する（コンテナ再利用中はキャッシュする）。"""
    global _webhook_url
    if _webhook_url is None:
        response = _ssm.get_parameter(
            Name=os.environ["SLACK_WEBHOOK_SSM_PARAM"], WithDecryption=True
        )
        _webhook_url = response["Parameter"]["Value"]
    return _webhook_url


def _truncate(text, limit=MAX_REASON_LENGTH):
    text = str(text)
    return text if len(text) <= limit else text[:limit] + "..."


def _job_name(detail):
    """バッチ識別子（環境変数 JOB_NAME の上書き値）を取り出す。"""
    for container in detail.get("overrides", {}).get("containerOverrides", []):
        for env in container.get("environment", []):
            if env.get("name") == "JOB_NAME":
                return env.get("value")
    return None


def build_message(event):
    """通知メッセージを組み立てる。"""
    detail = event.get("detail", {})
    task_arn = detail.get("taskArn", "")
    task_id = task_arn.rsplit("/", 1)[-1]
    task_definition = detail.get("taskDefinitionArn", "").rsplit("/", 1)[-1]
    cluster = detail.get("clusterArn", "").rsplit("/", 1)[-1]

    job_name = _job_name(detail)
    job_label = f"`{job_name}`" if job_name else "(JOB_NAME の上書きなし。タスク定義の既定値)"

    lines = [
        ":rotating_light: ECSタスク異常終了",
        f"• バッチ: {job_label}",
        f"• タスク: `{task_id}`（{task_definition}）",
        f"• クラスタ: `{cluster}`",
        f"• 停止コード: `{detail.get('stopCode', '-')}`",
        f"• 理由: {_truncate(detail.get('stoppedReason', '-'))}",
    ]

    for container in detail.get("containers", []):
        name = container.get("name", "-")
        exit_code = container.get("exitCode", "-")
        reason = container.get("reason")
        line = f"• コンテナ `{name}`: exitCode={exit_code}"
        if reason:
            line += f"（{_truncate(reason)}）"
        lines.append(line)

    log_group = os.environ.get("LOG_GROUP_NAME")
    container_name = os.environ.get("CONTAINER_NAME")
    if log_group and container_name and task_id:
        lines.append(f"• ログ: `{log_group}` / `ecs/{container_name}/{task_id}`")

    return "\n".join(lines)


def handler(event, context):
    logger.info("received: %s", json.dumps(event))

    webhook_url = _get_webhook_url()
    if not webhook_url.startswith(SLACK_WEBHOOK_PREFIX):
        # 未設定（初期値 dummy など）の場合は通知しない
        logger.warning("Slack の Webhook URL が未設定のため通知しません")
        return {"notified": False}

    body = json.dumps({"text": build_message(event)}).encode("utf-8")
    request = urllib.request.Request(
        webhook_url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    # 失敗時は例外を投げる（EventBridge の非同期呼び出しで自動的に再試行される）
    with urllib.request.urlopen(request, timeout=5) as response:
        logger.info("slack status: %s", response.status)
    return {"notified": True}
