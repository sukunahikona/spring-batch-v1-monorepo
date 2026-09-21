package org.sukunahikona.batch_app.job;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.batch.core.job.Job;
import org.springframework.batch.core.job.JobExecution;
import org.springframework.batch.core.job.parameters.JobParameters;
import org.springframework.batch.core.job.parameters.JobParametersBuilder;
import org.springframework.batch.core.BatchStatus;
import org.springframework.batch.test.JobOperatorTestUtils;
import org.springframework.batch.test.JobRepositoryTestUtils;
import org.springframework.batch.test.context.SpringBatchTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBatchTest
@SpringBootTest
class SampleJobTest {

    @Autowired
    private JobOperatorTestUtils jobOperatorTestUtils;

    @Autowired
    private JobRepositoryTestUtils jobRepositoryTestUtils;

    @Autowired
    @Qualifier("sampleJob")
    private Job sampleJob;

    @BeforeEach
    void setUp() {
        jobRepositoryTestUtils.removeJobExecutions();
        jobOperatorTestUtils.setJob(sampleJob);
    }

    @Test
    @DisplayName("sampleJob - 正常終了することを確認")
    void testSampleJobCompletes() throws Exception {
        // パラメタ付与
        // ※同じパラメタではジョブ実行できない
        JobParameters jobParameters = new JobParametersBuilder()
                .addLong("time", System.currentTimeMillis())
                .toJobParameters();

        JobExecution jobExecution = jobOperatorTestUtils.startJob(jobParameters);

        // ステップの実行数確認
        assertEquals(1, jobExecution.getStepExecutions().size());

        // 各ステップの実行結果確認
        jobExecution.getStepExecutions().forEach(stepExecution -> {
            assertEquals("stepOne", stepExecution.getStepName());
            assertEquals(BatchStatus.COMPLETED, stepExecution.getStatus());
        });

        // Job本体の実行結果確認
        assertEquals(BatchStatus.COMPLETED, jobExecution.getStatus());
    }
}
