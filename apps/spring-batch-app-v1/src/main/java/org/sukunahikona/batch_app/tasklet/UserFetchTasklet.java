package org.sukunahikona.batch_app.tasklet;

import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.StepContribution;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.infrastructure.repeat.RepeatStatus;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.sukunahikona.batch_app.entity.Product;
import org.sukunahikona.batch_app.entity.User;
import org.sukunahikona.batch_app.service.ProductService;
import org.sukunahikona.batch_app.service.UserService;

import java.util.List;

@Component
@Qualifier("userFetchTasklet")
public class UserFetchTasklet implements Tasklet {

    private final UserService userService;

    public UserFetchTasklet(UserService userService) {
        this.userService = userService;
    }

    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
        System.out.println("=================================");
        System.out.println("User Fetch Tasklet is executing...");
        System.out.println("Job Name: " + chunkContext.getStepContext().getJobName());
        System.out.println("Step Name: " + chunkContext.getStepContext().getStepName());
        System.out.println("=================================");

        // ユーザデータを全件取得
        List<User> users = userService.findAllUsers();

        System.out.println("Total users found: " + users.size());
        System.out.println();

        // 取得した商品を表示
        for (User user : users) {
            System.out.println(user);
        }

        System.out.println();
        System.out.println("Product Fetch Tasklet completed!");
        System.out.println("=================================");

        return RepeatStatus.FINISHED;
    }
}