package com.fieldnotes.fieldnote.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateFieldNoteRequest(
    @NotBlank
    String note
) {
}
