package com.fieldnotes.user.service;

import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.user.dto.ForgotPasswordResponse;
import com.fieldnotes.user.dto.ResetPasswordRequest;
import com.fieldnotes.user.entity.User;
import com.fieldnotes.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

/**
 * Forgot password with a 6 digit OTP.
 *
 * Flow: POST /api/auth/forgot-password (email) -> OTP created, stored hashed, valid 10 min
 *       POST /api/auth/reset-password  (email, otp, newPassword) -> password changed
 *
 * DEMO MODE: there is no e-mail provider, so while app.auth.dev-otp-enabled=true the OTP
 * is returned in the response and the app shows it in a snackbar. In production set
 * DEV_OTP_ENABLED=false and send the OTP by e-mail instead.
 */
@Service
@Transactional
public class PasswordResetService {

    private static final Duration OTP_LIFETIME = Duration.ofMinutes(10);
    private static final int MAX_ATTEMPTS = 5;
    private static final String GENERIC_MESSAGE =
        "If this email is registered, an OTP has been sent.";

    private final SecureRandom random = new SecureRandom();
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final boolean devOtpEnabled;

    public PasswordResetService(
        UserRepository userRepository,
        PasswordEncoder passwordEncoder,
        @Value("${app.auth.dev-otp-enabled:true}") boolean devOtpEnabled
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.devOtpEnabled = devOtpEnabled;
    }

    public ForgotPasswordResponse requestOtp(String rawEmail) {
        String email = normalize(rawEmail);
        Optional<User> found = userRepository.findByEmailAndDeletedAtIsNull(email);

        if (found.isEmpty()) {
            if (devOtpEnabled) {
                // demo mode: tell the developer clearly what happened
                throw new ResourceNotFoundException("No account found with this email");
            }
            // production: do not reveal which e-mails are registered
            return new ForgotPasswordResponse(GENERIC_MESSAGE, null);
        }

        String otp = String.format("%06d", random.nextInt(1_000_000));

        User user = found.get();
        user.startPasswordReset(
            passwordEncoder.encode(otp),
            Instant.now().plus(OTP_LIFETIME)
        );
        userRepository.save(user);

        return new ForgotPasswordResponse(
            GENERIC_MESSAGE,
            devOtpEnabled ? otp : null
        );
    }

    /** noRollbackFor: a wrong OTP must still count as an attempt. */
    @Transactional(noRollbackFor = IllegalArgumentException.class)
    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository
            .findByEmailAndDeletedAtIsNull(normalize(request.email()))
            .orElseThrow(() -> new IllegalArgumentException("OTP is invalid or has expired"));

        boolean noActiveOtp = user.getResetOtpHash() == null
            || user.getResetOtpExpiresAt() == null
            || user.getResetOtpExpiresAt().isBefore(Instant.now());

        if (noActiveOtp) {
            throw new IllegalArgumentException("OTP is invalid or has expired");
        }

        if (user.getResetOtpAttempts() >= MAX_ATTEMPTS) {
            user.clearPasswordReset();
            userRepository.save(user);
            throw new IllegalArgumentException("Too many wrong attempts. Please request a new OTP.");
        }

        if (!passwordEncoder.matches(request.otp(), user.getResetOtpHash())) {
            user.registerFailedOtpAttempt();
            userRepository.save(user);
            throw new IllegalArgumentException("OTP is invalid or has expired");
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        user.clearPasswordReset();
        userRepository.save(user);
    }

    private String normalize(String email) {
        return email.trim().toLowerCase();
    }
}
