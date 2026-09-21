package org.sukunahikona.batch_app.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.sukunahikona.batch_app.entity.User;

import java.util.List;


@Mapper
public interface UserMapper {
    List<User> findAll();
}
