package org.sukunahikona.batch_app.config;

import org.springframework.batch.core.job.Job;
import org.springframework.batch.core.job.builder.FlowBuilder;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.job.flow.Flow;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.Step;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.SimpleAsyncTaskExecutor;
import org.springframework.transaction.PlatformTransactionManager;

@Configuration
public class BatchRdsJobConfiguration {

    @Bean
    public Job productFetchJob(JobRepository jobRepository,
                               PlatformTransactionManager transactionManager,
                               @Qualifier("productFetchTasklet") Tasklet productFetchTasklet) {
        Step step = new StepBuilder("productFetchStep", jobRepository)
                .tasklet(productFetchTasklet, transactionManager)
                .build();

        return new JobBuilder("productFetchJob", jobRepository).start(step).build();
    }

    @Bean
    public Job userFetchJob(JobRepository jobRepository,
                            PlatformTransactionManager transactionManager,
                            @Qualifier("userFetchTasklet") Tasklet userFetchTasklet) {
        Step step = new StepBuilder("userFetchStep", jobRepository).tasklet(userFetchTasklet, transactionManager).build();
        return new JobBuilder("userFetchJob", jobRepository).start(step).build();
    }
}