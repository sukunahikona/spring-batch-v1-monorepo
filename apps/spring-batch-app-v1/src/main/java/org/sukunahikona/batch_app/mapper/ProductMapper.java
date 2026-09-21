package org.sukunahikona.batch_app.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.sukunahikona.batch_app.entity.Product;

import java.util.List;

@Mapper
public interface ProductMapper {
    List<Product> findAll();
}