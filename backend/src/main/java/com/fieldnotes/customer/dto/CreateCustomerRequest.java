package com.fieldnotes.customer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;


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
