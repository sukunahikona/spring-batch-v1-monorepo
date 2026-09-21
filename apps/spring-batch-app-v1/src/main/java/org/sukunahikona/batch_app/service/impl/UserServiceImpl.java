package org.sukunahikona.batch_app.service.impl;

import org.springframework.stereotype.Service;
import org.sukunahikona.batch_app.entity.User;
import org.sukunahikona.batch_app.mapper.UserMapper;
import org.sukunahikona.batch_app.service.UserService;

import java.util.List;

@Service
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;

    public UserServiceImpl(UserMapper userMapper) {
        this.userMapper = userMapper;
    }

    @Override
    public List<User> findAllUsers() {
        return userMapper.findAll();
    }
}