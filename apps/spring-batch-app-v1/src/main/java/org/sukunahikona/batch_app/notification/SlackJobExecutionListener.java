package org.sukunahikona.batch_app.notification;

import java.time.Duration;
import java.time.LocalDateTime;

import org.springframework.batch.core.BatchStatus;
import org.springframework.batch.core.job.JobExecution;
import org.springframework.batch.core.listener.JobExecutionListener;
import org.springframework.stereotype.Component;

/**
 * ジョブの起動前・終了後に Slack へ通知するリスナー。
 */
@Component
public class SlackJobExecutionListener implements JobExecutionListener {

    private static final int MAX_ERROR_LENGTH = 300;

    private final SlackNotifier slackNotifier;

    public SlackJobExecutionListener(SlackNotifier slackNotifier) {
        this.slackNotifier = slackNotifier;
    }

    @Override
    public void beforeJob(JobExecution jobExecution) {
        slackNotifier.notify(":rocket: バッチ起動: `" + jobName(jobExecution) + "` (executionId="
                + jobExecution.getId() + ")");
    }

    @Override
    public void afterJob(JobExecution jobExecution) {
        boolean completed = jobExecution.getStatus() == BatchStatus.COMPLETED;
        StringBuilder message = new StringBuilder()
                .append(completed ? ":white_check_mark: バッチ正常終了: " : ":x: バッチ異常終了: ")
                .append('`').append(jobName(jobExecution)).append('`')
                .append(" (executionId=").append(jobExecution.getId())
                .append(", status=").append(jobExecution.getStatus())
                .append(", exit=").append(jobExecution.getExitStatus().getExitCode());
        LocalDateTime start = jobExecution.getStartTime();
        LocalDateTime end = jobExecution.getEndTime() != null ? jobExecution.getEndTime() : LocalDateTime.now();
        if (start != null) {
            message.append(", 所要時間=").append(Duration.between(start, end).toMillis()).append("ms");
        }
        message.append(')');
        if (!completed && !jobExecution.getAllFailureExceptions().isEmpty()) {
            String error = String.valueOf(jobExecution.getAllFailureExceptions().get(0));
            if (error.length() > MAX_ERROR_LENGTH) {
                error = error.substring(0, MAX_ERROR_LENGTH) + "...";
            }
            message.append("\n```").append(error).append("```");
        }
        slackNotifier.notify(message.toString());
    }

    private static String jobName(JobExecution jobExecution) {
        return jobExecution.getJobInstance().getJobName();
    }
}
