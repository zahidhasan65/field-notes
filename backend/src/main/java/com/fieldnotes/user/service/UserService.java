package com.fieldnotes.user.service;

import com.fieldnotes.auth.service.JwtService;
import com.fieldnotes.exception.DuplicateResourceException;
import com.fieldnotes.exception.InvalidCredentialsException;
import com.fieldnotes.user.dto.GoogleLoginRequest;
import com.fieldnotes.user.dto.LoginRequest;
import com.fieldnotes.user.dto.LoginResponse;
import com.fieldnotes.user.dto.RegisterRequest;
import com.fieldnotes.user.dto.UserResponse;
import com.fieldnotes.user.entity.User;
import com.fieldnotes.user.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final GoogleAuthService googleAuthService;

    public UserService(
        UserRepository userRepository,
        PasswordEncoder passwordEncoder,
        JwtService jwtService,
        GoogleAuthService googleAuthService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.googleAuthService = googleAuthService;
    }

    public boolean emailExists(String email) {
        return userRepository.existsByEmailAndDeletedAtIsNull(email);
    }

    public LoginResponse register(RegisterRequest request) {
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

        String token = jwtService.generateToken(
            savedUser.getId(),
            savedUser.getEmail()
        );

        UserResponse userResponse = new UserResponse(
            savedUser.getId(),
            savedUser.getName(),
            savedUser.getEmail(),
            savedUser.getCreatedAt()
        );

        return new LoginResponse(token, "Bearer", userResponse);
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

        UserResponse userResponse = new UserResponse(
            user.getId(),
            user.getName(),
            user.getEmail(),
            user.getCreatedAt()
        );

        return new LoginResponse(token, "Bearer", userResponse);
    }

    /**
     * "Continue with Google": verifies the Google ID token, then logs the user in.
     * First time = an account is created (random password, the user signs in with Google).
     */
    public LoginResponse loginWithGoogle(GoogleLoginRequest request) {
        GoogleAuthService.GoogleProfile profile =
            googleAuthService.verify(request.idToken());

        String email = profile.email().trim().toLowerCase();

        User user = userRepository.findByEmailAndDeletedAtIsNull(email)
            .orElseGet(() -> userRepository.save(new User(
                profile.name().trim(),
                email,
                passwordEncoder.encode(UUID.randomUUID() + UUID.randomUUID().toString())
            )));

        String token = jwtService.generateToken(user.getId(), user.getEmail());

        UserResponse userResponse = new UserResponse(
            user.getId(),
            user.getName(),
            user.getEmail(),
            user.getCreatedAt()
        );

        return new LoginResponse(token, "Bearer", userResponse);
    }
}
