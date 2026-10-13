package com.fieldnotes.customer.dto;

import java.time.Instant;
import java.util.UUID;

public record CustomerResponse(
    UUID id,
    String name,
    String contactInformation,
    String contactPerson,
    String email,
    String phone,
    String address,
    Instant createdAt,
    Instant updatedAt,
    Instant deletedAt
) {
}
