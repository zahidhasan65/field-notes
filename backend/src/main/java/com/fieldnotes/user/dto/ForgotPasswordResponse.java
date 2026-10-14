package com.fieldnotes.user.dto;


public record ForgotPasswordResponse(
    String message,
    String devOtp
) {
}
