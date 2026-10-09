package com.fieldnotes.user.service;

import com.fieldnotes.auth.service.JwtService;
import com.fieldnotes.exception.DuplicateResourceException;
import com.fieldnotes.exception.InvalidCredentialsException;
import com.fieldnotes.user.dto.LoginRequest;
import com.fieldnotes.user.dto.LoginResponse;
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
    private final JwtService jwtService;

    public UserService(
        UserRepository userRepository,
        PasswordEncoder passwordEncoder,
        JwtService jwtService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
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

    public LoginResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase();

        User user = userRepository.findByEmailAndDeletedAtIsNull(email)
            .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }

        String token = jwtService.generateToken(
            user.getId(),
            user.getEmail()
        );

        return new LoginResponse(token, "Bearer");
    }
}


