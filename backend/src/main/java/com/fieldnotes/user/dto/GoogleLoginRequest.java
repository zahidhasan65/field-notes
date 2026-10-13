package com.fieldnotes.user.dto;

import jakarta.validation.constraints.NotBlank;

/** Google ID token obtained by the app (google_sign_in). */
public record GoogleLoginRequest(
    @NotBlank
    String idToken
) {
}
