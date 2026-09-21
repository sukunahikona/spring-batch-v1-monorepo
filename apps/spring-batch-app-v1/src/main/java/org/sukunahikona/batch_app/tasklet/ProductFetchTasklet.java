package org.sukunahikona.batch_app.tasklet;

import org.springframework.batch.core.step.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.infrastructure.repeat.RepeatStatus;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.sukunahikona.batch_app.entity.Product;
import org.sukunahikona.batch_app.service.ProductService;

import java.util.List;

@Component
@Qualifier("productFetchTasklet")
public class ProductFetchTasklet implements Tasklet {

    private final ProductService productService;

    public ProductFetchTasklet(ProductService productService) {
        this.productService = productService;
    }

    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
        System.out.println("=================================");
        System.out.println("Product Fetch Tasklet is executing...");
        System.out.println("Job Name: " + chunkContext.getStepContext().getJobName());
        System.out.println("Step Name: " + chunkContext.getStepContext().getStepName());
        System.out.println("=================================");

        // 商品データを全件取得
        List<Product> products = productService.findAllProducts();

        System.out.println("Total products found: " + products.size());
        System.out.println();

        // 取得した商品を表示
        for (Product product : products) {
            System.out.println(product);
        }

        System.out.println();
        System.out.println("Product Fetch Tasklet completed!");
        System.out.println("=================================");

        return RepeatStatus.FINISHED;
    }
}