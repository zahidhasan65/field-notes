package com.fieldnotes.user.dto;

import jakarta.validation.constraints.NotBlank;


public record GoogleLoginRequest(
    @NotBlank
    String idToken
) {
}
