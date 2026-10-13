package com.fieldnotes.site.dto;

import java.time.Instant;
import java.util.UUID;

public record SiteResponse(
    UUID id,
    UUID customerId,
    String name,
    String address,
    Double latitude,
    Double longitude,
    Instant createdAt,
    Instant updatedAt,
    Instant deletedAt
) {
}
