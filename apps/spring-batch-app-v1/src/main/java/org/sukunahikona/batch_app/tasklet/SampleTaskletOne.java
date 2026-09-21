package org.sukunahikona.batch_app.tasklet;

import org.springframework.batch.core.step.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.infrastructure.repeat.RepeatStatus;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;

@Component
@Qualifier("sampleTaskletOne")
public class SampleTaskletOne implements Tasklet {

    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
        System.out.println("=================================");
        System.out.println("Sample Tasklet One is executing...");
        System.out.println("Job Name: " + chunkContext.getStepContext().getJobName());
        System.out.println("Step Name: " + chunkContext.getStepContext().getStepName());
        System.out.println("=================================");

        // ここに実際の処理を記述
        // 例: ファイル処理、データベース操作など

        return RepeatStatus.FINISHED;
    }
}