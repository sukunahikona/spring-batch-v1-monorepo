package org.sukunahikona.batch_app.service;

import org.sukunahikona.batch_app.entity.Product;

import java.util.List;

public interface ProductService {
    List<Product> findAllProducts();
}