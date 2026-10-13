package com.fieldnotes.fieldnote.dto;

import com.fieldnotes.fieldnote.entity.NoteStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

/** "siteId" is optional: set it to move the note to another site. */
public record UpdateFieldNoteRequest(
    UUID siteId,

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
