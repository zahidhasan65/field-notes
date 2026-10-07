package com.fieldnotes.user.service;

import com.fieldnotes.exception.DuplicateResourceException;
import com.fieldnotes.user.dto.RegisterRequest;
import com.fieldnotes.user.dto.UserResponse;
import com.fieldnotes.user.entity.User;
import com.fieldnotes.user.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(
        UserRepository userRepository,
        PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public boolean emailExists(String email) {
        return userRepository.existsByEmailAndDeletedAtIsNull(email);
    }

    public UserResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase();

        if (emailExists(email)) {
            throw new DuplicateResourceException("Email already exists");
        }

        String passwordHash = passwordEncoder.encode(request.password());

        User user = new User(
            request.name().trim(),
            email,
            passwordHash
        );

        User savedUser = userRepository.save(user);

        return new UserResponse(
            savedUser.getId(),
            savedUser.getName(),
            savedUser.getEmail(),
            savedUser.getCreatedAt()
        );
    }
}
