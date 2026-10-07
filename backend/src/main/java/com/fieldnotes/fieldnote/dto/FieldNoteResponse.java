package com.fieldnotes.fieldnote.dto;

import java.time.Instant;
import java.util.UUID;

public record FieldNoteResponse(
    UUID id,
    UUID siteId,
    String note,
    Instant createdAt,
    Instant updatedAt
) {
}
