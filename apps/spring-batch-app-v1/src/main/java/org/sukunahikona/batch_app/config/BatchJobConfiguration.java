package org.sukunahikona.batch_app.config;

import org.springframework.batch.core.job.Job;
import org.springframework.batch.core.step.Step;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.job.builder.FlowBuilder;
import org.springframework.batch.core.job.flow.Flow;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.SimpleAsyncTaskExecutor;
import org.springframework.transaction.PlatformTransactionManager;

@Configuration
public class BatchJobConfiguration {

    @Bean
    public Job sampleJob(JobRepository jobRepository,
                                PlatformTransactionManager transactionManager,
                                @Qualifier("sampleTaskletOne") Tasklet sampleTaskletOne) {

        Step stepOne = new StepBuilder("stepOne", jobRepository)
                .tasklet(sampleTaskletOne, transactionManager)
                .build();

        return new JobBuilder("sampleJob", jobRepository)
                .start(stepOne)
                .build();
    }

    @Bean
    public Job sampleContinuingJob(JobRepository jobRepository,
                         PlatformTransactionManager transactionManager,
                         @Qualifier("sampleTaskletOne") Tasklet sampleTaskletOne,
                         @Qualifier("sampleTaskletTwo") Tasklet sampleTaskletTwo) {

        Step stepOne = new StepBuilder("stepOne", jobRepository)
                .tasklet(sampleTaskletOne, transactionManager)
                .build();

        Step stepTwo = new StepBuilder("stepTwo", jobRepository)
                .tasklet(sampleTaskletTwo, transactionManager)
                .build();

        return new JobBuilder("sampleContinuingJob", jobRepository)
                .start(stepOne)
                .next(stepTwo)
                .build();
    }

    @Bean
    public Job parallelJob(JobRepository jobRepository,
                           PlatformTransactionManager transactionManager,
                           @Qualifier("parallelTaskletOne") Tasklet parallelTaskletOne,
                           @Qualifier("parallelTaskletTwo") Tasklet parallelTaskletTwo,
                           @Qualifier("parallelTaskletFinal") Tasklet parallelTaskletFinal) {

        // 並列実行するStep1
        Step parallelStepOne = new StepBuilder("parallelStepOne", jobRepository)
                .tasklet(parallelTaskletOne, transactionManager)
                .build();

        // 並列実行するStep2
        Step parallelStepTwo = new StepBuilder("parallelStepTwo", jobRepository)
                .tasklet(parallelTaskletTwo, transactionManager)
                .build();

        // 最後に実行するStep
        Step finalStep = new StepBuilder("finalStep", jobRepository)
                .tasklet(parallelTaskletFinal, transactionManager)
                .build();

        // Flow1: parallelStepOne を含むフロー
        Flow flow1 = new FlowBuilder<Flow>("flow1")
                .start(parallelStepOne)
                .build();

        // Flow2: parallelStepTwo を含むフロー
        Flow flow2 = new FlowBuilder<Flow>("flow2")
                .start(parallelStepTwo)
                .build();

        // 並列実行後にfinalStepを実行
        Flow splitFlow = new FlowBuilder<Flow>("splitFlow")
                .split(new SimpleAsyncTaskExecutor())
                .add(flow1, flow2)
                .build();

        return new JobBuilder("parallelJob", jobRepository)
                .start(splitFlow)
                .next(finalStep)
                .end()
                .build();
    }
}