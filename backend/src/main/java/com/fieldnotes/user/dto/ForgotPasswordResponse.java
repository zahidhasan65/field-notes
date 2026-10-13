package com.fieldnotes.user.dto;

/**
 * devOtp is only filled in demo mode (app.auth.dev-otp-enabled=true): there is no
 * e-mail provider, so the app shows the OTP in a snackbar instead.
 */
public record ForgotPasswordResponse(
    String message,
    String devOtp
) {
}
