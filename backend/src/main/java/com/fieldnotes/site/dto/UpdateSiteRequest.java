package com.fieldnotes.site.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/** "customerId" is optional: set it to move the site to another customer. */
public record UpdateSiteRequest(
    @NotBlank
    @Size(max = 150)
    String name,

    @Size(max = 255)
    String address,

    Double latitude,

    Double longitude,

    UUID customerId
) {
}
