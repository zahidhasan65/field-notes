package com.fieldnotes.customer.dto;

import java.time.Instant;
import java.util.UUID;

public record CustomerResponse(
    UUID id,
    String name,
    String contactInformation,
    Instant createdAt,
    Instant updatedAt
) {
}
