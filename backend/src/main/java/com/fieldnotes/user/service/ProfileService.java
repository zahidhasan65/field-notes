package com.fieldnotes.user.service;

import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.user.dto.ChangePasswordRequest;
import com.fieldnotes.user.dto.UserResponse;
import com.fieldnotes.user.entity.User;
import com.fieldnotes.user.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;


@Service
@Transactional
public class ProfileService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public ProfileService(
        UserRepository userRepository,
        PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public UserResponse getProfile(UUID userId) {
        return toResponse(getUser(userId));
    }

    public UserResponse updateName(UUID userId, String name) {
        User user = getUser(userId);
        user.setName(name.trim());
        return toResponse(userRepository.save(user));
    }

    public void changePassword(UUID userId, ChangePasswordRequest request) {
        User user = getUser(userId);

        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }
        if (request.currentPassword().equals(request.newPassword())) {
            throw new IllegalArgumentException("New password must be different from the current one");
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }

    private User getUser(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (user.getDeletedAt() != null) {
            throw new ResourceNotFoundException("User not found");
        }
        return user;
    }

    private UserResponse toResponse(User user) {
        return new UserResponse(
            user.getId(),
            user.getName(),
            user.getEmail(),
            user.getCreatedAt()
        );
    }
}
