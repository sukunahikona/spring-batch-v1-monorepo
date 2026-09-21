package org.sukunahikona.batch_app.service;

import org.sukunahikona.batch_app.entity.User;

import java.util.List;

public interface UserService {
    List<User> findAllUsers();
}
