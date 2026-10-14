package com.fieldnotes.site.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;


public record CreateSiteRequest(
    UUID id,

    @NotBlank
    @Size(max = 150)
    String name,

    @Size(max = 255)
    String address,

    Double latitude,

    Double longitude
) {
}
