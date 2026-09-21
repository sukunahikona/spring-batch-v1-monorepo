package org.sukunahikona.batch_app.job;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.batch.core.BatchStatus;
import org.springframework.batch.core.job.Job;
import org.springframework.batch.core.job.JobExecution;
import org.springframework.batch.core.job.parameters.JobParameters;
import org.springframework.batch.core.job.parameters.JobParametersBuilder;
import org.springframework.batch.core.step.StepExecution;
import org.springframework.batch.test.JobOperatorTestUtils;
import org.springframework.batch.test.JobRepositoryTestUtils;
import org.springframework.batch.test.context.SpringBatchTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBatchTest
@SpringBootTest
class ParallelJobTest {

    @Autowired
    private JobOperatorTestUtils jobOperatorTestUtils;

    @Autowired
    private JobRepositoryTestUtils jobRepositoryTestUtils;

    @Autowired
    @Qualifier("parallelJob")
    private Job parallelJob;

    @BeforeEach
    void setUp() {
        jobRepositoryTestUtils.removeJobExecutions();
        jobOperatorTestUtils.setJob(parallelJob);
    }

    @Test
    @DisplayName("parallelJob - 正常終了することを確認")
    void testParallelJobCompletes() throws Exception {
        // Given
        JobParameters jobParameters = new JobParametersBuilder()
                .addLong("time", System.currentTimeMillis())
                .toJobParameters();

        // When
        JobExecution jobExecution = jobOperatorTestUtils.startJob(jobParameters);

        // Then: Job全体がCOMPLETED
        assertEquals(BatchStatus.COMPLETED, jobExecution.getStatus());
    }

    @Test
    @DisplayName("parallelJob - 3つのステップが実行されることを確認")
    void testAllStepsExecuted() throws Exception {
        // Given
        JobParameters jobParameters = new JobParametersBuilder()
                .addLong("time", System.currentTimeMillis())
                .toJobParameters();

        // When
        JobExecution jobExecution = jobOperatorTestUtils.startJob(jobParameters);

        // Then: 3つのステップが実行される
        assertEquals(3, jobExecution.getStepExecutions().size());

        // ステップ名を確認
        Set<String> stepNames = jobExecution.getStepExecutions().stream()
                .map(StepExecution::getStepName)
                .collect(Collectors.toSet());

        assertTrue(stepNames.contains("parallelStepOne"));
        assertTrue(stepNames.contains("parallelStepTwo"));
        assertTrue(stepNames.contains("finalStep"));
    }

    @Test
    @DisplayName("parallelJob - 並列ステップが同時に実行されることを確認")
    void testStepsRunInParallel() throws Exception {
        // Given
        JobParameters jobParameters = new JobParametersBuilder()
                .addLong("time", System.currentTimeMillis())
                .toJobParameters();
        JobExecution jobExecution = jobOperatorTestUtils.startJob(jobParameters);

        StepExecution stepOne = jobExecution.getStepExecutions().stream()
                .filter(step -> "parallelStepOne".equals(step.getStepName()))
                .findFirst()
                .orElseThrow();

        StepExecution stepTwo = jobExecution.getStepExecutions().stream()
                .filter(step -> "parallelStepTwo".equals(step.getStepName()))
                .findFirst()
                .orElseThrow();

        assertTrue(
                stepOne.getStartTime().isBefore(stepTwo.getEndTime())
                && stepTwo.getStartTime().isBefore(stepOne.getEndTime())
        );
    }
}
