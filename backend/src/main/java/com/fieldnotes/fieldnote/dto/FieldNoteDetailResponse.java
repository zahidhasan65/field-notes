package com.fieldnotes.fieldnote.dto;

import com.fieldnotes.fieldnote.entity.NoteStatus;

import java.time.Instant;
import java.util.UUID;

/** Note together with its site and customer (loaded with JOINs, nothing duplicated in the DB). */
public record FieldNoteDetailResponse(
    UUID id,
    UUID siteId,
    String siteName,
    UUID customerId,
    String customerName,
    String title,
    String description,
    NoteStatus status,
    Instant noteDatetime,
    Double latitude,
    Double longitude,
    String photoUrl,
    Instant createdAt,
    Instant updatedAt
) {
}
