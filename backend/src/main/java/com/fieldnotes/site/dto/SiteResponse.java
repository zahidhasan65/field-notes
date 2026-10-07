package com.fieldnotes.site.dto;

import java.time.Instant;
import java.util.UUID;

public record SiteResponse(
    UUID id,
    UUID customerId,
    String name,
    String address,
    Instant createdAt,
    Instant updatedAt
) {
}
