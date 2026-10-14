package com.fieldnotes.user.entity;

import com.fieldnotes.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "users")
public class User extends BaseEntity {

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, unique = true, length = 255)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    
    @Column(name = "reset_otp_hash", length = 255)
    private String resetOtpHash;

    @Column(name = "reset_otp_expires_at")
    private Instant resetOtpExpiresAt;

    @Column(name = "reset_otp_attempts", nullable = false)
    private int resetOtpAttempts;

    protected User() {
        super();
    }

    public User(String name, String email, String passwordHash) {
        super();
        this.name = name;
        this.email = email;
        this.passwordHash = passwordHash;
    }

    public User(
        UUID id,
        String name,
        String email,
        String passwordHash
    ) {
        super(id);
        this.name = name;
        this.email = email;
        this.passwordHash = passwordHash;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getResetOtpHash() {
        return resetOtpHash;
    }

    public Instant getResetOtpExpiresAt() {
        return resetOtpExpiresAt;
    }

    public int getResetOtpAttempts() {
        return resetOtpAttempts;
    }

    public void startPasswordReset(String otpHash, Instant expiresAt) {
        this.resetOtpHash = otpHash;
        this.resetOtpExpiresAt = expiresAt;
        this.resetOtpAttempts = 0;
    }

    public void registerFailedOtpAttempt() {
        this.resetOtpAttempts++;
    }

    public void clearPasswordReset() {
        this.resetOtpHash = null;
        this.resetOtpExpiresAt = null;
        this.resetOtpAttempts = 0;
    }
}
