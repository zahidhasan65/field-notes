package com.fieldnotes.customer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateCustomerRequest(
    @NotBlank
    @Size(max = 150)
    String name,

    @Size(max = 255)
    String contactInformation
) {
}
