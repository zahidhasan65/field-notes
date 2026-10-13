package com.fieldnotes.customer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * "id" is an optional client generated id. It makes the request idempotent
 * (safe to retry), which the offline sync relies on.
 */
public record CreateCustomerRequest(
    UUID id,

    @NotBlank
    @Size(max = 150)
    String name,

    @Size(max = 255)
    String contactInformation,

    @Size(max = 150)
    String contactPerson,

    @Size(max = 255)
    String email,

    @Size(max = 50)
    String phone,

    @Size(max = 255)
    String address
) {
}
