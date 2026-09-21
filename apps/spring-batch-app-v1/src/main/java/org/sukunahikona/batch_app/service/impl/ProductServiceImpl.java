package org.sukunahikona.batch_app.service.impl;

import org.springframework.stereotype.Service;
import org.sukunahikona.batch_app.entity.Product;
import org.sukunahikona.batch_app.mapper.ProductMapper;
import org.sukunahikona.batch_app.service.ProductService;

import java.util.List;

@Service
public class ProductServiceImpl implements ProductService {

    private final ProductMapper productMapper;

    public ProductServiceImpl(ProductMapper productMapper) {
        this.productMapper = productMapper;
    }

    @Override
    public List<Product> findAllProducts() {
        return productMapper.findAll();
    }
}