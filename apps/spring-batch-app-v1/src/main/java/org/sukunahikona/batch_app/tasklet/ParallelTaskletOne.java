package org.sukunahikona.batch_app.tasklet;

import org.springframework.batch.core.step.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.infrastructure.repeat.RepeatStatus;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;

@Component
@Qualifier("parallelTaskletOne")
public class ParallelTaskletOne implements Tasklet {

    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
        // ランダムな待ち時間（1秒〜5秒）
        long sleepTime = (long) (Math.random() * 4000 + 1000);

        System.out.println("=================================");
        System.out.println("Parallel Tasklet One is executing...");
        System.out.println("Thread: " + Thread.currentThread().getName());
        System.out.println("Job Name: " + chunkContext.getStepContext().getJobName());
        System.out.println("Step Name: " + chunkContext.getStepContext().getStepName());
        System.out.println("Sleep Time: " + sleepTime + "ms");

        // シミュレーション: 処理に時間がかかる
        Thread.sleep(sleepTime);

        System.out.println("Parallel Tasklet One completed!");
        System.out.println("=================================");

        return RepeatStatus.FINISHED;
    }
}