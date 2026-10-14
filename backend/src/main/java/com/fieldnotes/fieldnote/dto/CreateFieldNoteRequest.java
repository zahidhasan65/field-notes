package com.fieldnotes.fieldnote.dto;

import com.fieldnotes.fieldnote.entity.NoteStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;


public record CreateFieldNoteRequest(
    UUID id,

    @NotBlank
    @Size(max = 200)
    String title,

    String description,

    NoteStatus status,

    Instant noteDatetime,

    Double latitude,

    Double longitude
) {
}
