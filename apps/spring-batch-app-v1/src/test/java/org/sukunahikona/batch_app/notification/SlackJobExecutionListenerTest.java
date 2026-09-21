package org.sukunahikona.batch_app.notification;

import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import org.junit.jupiter.api.Test;
import org.springframework.batch.core.BatchStatus;
import org.springframework.batch.core.ExitStatus;
import org.springframework.batch.core.job.JobExecution;
import org.springframework.batch.core.job.JobInstance;
import org.springframework.batch.core.job.parameters.JobParameters;

class SlackJobExecutionListenerTest {

    private final SlackNotifier notifier = mock(SlackNotifier.class);
    private final SlackJobExecutionListener listener = new SlackJobExecutionListener(notifier);

    private JobExecution jobExecution() {
        return new JobExecution(1L, new JobInstance(1L, "sampleJob"), new JobParameters());
    }

    @Test
    void 起動前にジョブ名を通知する() {
        listener.beforeJob(jobExecution());
        verify(notifier).notify(contains("バッチ起動: `sampleJob`"));
    }

    @Test
    void 正常終了を通知する() {
        JobExecution execution = jobExecution();
        execution.setStatus(BatchStatus.COMPLETED);
        execution.setExitStatus(ExitStatus.COMPLETED);
        listener.afterJob(execution);
        verify(notifier).notify(contains("バッチ正常終了: `sampleJob`"));
    }

    @Test
    void 異常終了とエラー内容を通知する() {
        JobExecution execution = jobExecution();
        execution.setStatus(BatchStatus.FAILED);
        execution.setExitStatus(ExitStatus.FAILED);
        execution.addFailureException(new IllegalStateException("boom"));
        listener.afterJob(execution);
        verify(notifier).notify(contains("バッチ異常終了: `sampleJob`"));
        verify(notifier).notify(contains("boom"));
    }
}
