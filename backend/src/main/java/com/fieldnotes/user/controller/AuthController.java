package com.fieldnotes.user.controller;

import com.fieldnotes.user.dto.LoginRequest;
import com.fieldnotes.user.dto.LoginResponse;
import com.fieldnotes.user.dto.RegisterRequest;
import com.fieldnotes.user.dto.UserResponse;
import com.fieldnotes.user.dto.ForgotPasswordRequest;
import com.fieldnotes.user.dto.ForgotPasswordResponse;
import com.fieldnotes.user.dto.GoogleLoginRequest;
import com.fieldnotes.user.dto.MessageResponse;
import com.fieldnotes.user.dto.ResetPasswordRequest;
import com.fieldnotes.user.service.PasswordResetService;
import com.fieldnotes.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final PasswordResetService passwordResetService;

    public AuthController(
        UserService userService,
        PasswordResetService passwordResetService
    ) {
        this.userService = userService;
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/register")
    public ResponseEntity<LoginResponse> register(
        @Valid @RequestBody RegisterRequest request
    ) {
        LoginResponse response = userService.register(request);

        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
        @Valid @RequestBody LoginRequest request
    ) {
        LoginResponse response = userService.login(request);

        return ResponseEntity.ok(response);
    }

    /** Step 1 of "forgot password": creates an OTP (demo mode returns it in the response). */
    @PostMapping("/forgot-password")
    public ResponseEntity<ForgotPasswordResponse> forgotPassword(
        @Valid @RequestBody ForgotPasswordRequest request
    ) {
        return ResponseEntity.ok(passwordResetService.requestOtp(request.email()));
    }

    /** Step 2: checks the OTP and sets the new password. */
    @PostMapping("/reset-password")
    public ResponseEntity<MessageResponse> resetPassword(
        @Valid @RequestBody ResetPasswordRequest request
    ) {
        passwordResetService.resetPassword(request);
        return ResponseEntity.ok(new MessageResponse("Password updated. You can log in now."));
    }

    /** "Continue with Google": body = { "idToken": "..." }. */
    @PostMapping("/google")
    public ResponseEntity<LoginResponse> google(
        @Valid @RequestBody GoogleLoginRequest request
    ) {
        return ResponseEntity.ok(userService.loginWithGoogle(request));
    }
}
