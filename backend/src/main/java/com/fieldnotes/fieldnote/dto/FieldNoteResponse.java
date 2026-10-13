package com.fieldnotes.fieldnote.dto;

import com.fieldnotes.fieldnote.entity.NoteStatus;

import java.time.Instant;
import java.util.UUID;

public record FieldNoteResponse(
    UUID id,
    UUID siteId,
    String title,
    String description,
    NoteStatus status,
    Instant noteDatetime,
    Double latitude,
    Double longitude,
    String photoUrl,
    Instant createdAt,
    Instant updatedAt,
    Instant deletedAt
) {
}
