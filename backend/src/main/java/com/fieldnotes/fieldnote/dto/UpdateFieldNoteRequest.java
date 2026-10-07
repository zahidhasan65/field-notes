package com.fieldnotes.fieldnote.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateFieldNoteRequest(
    @NotBlank
    String note
) {
}
