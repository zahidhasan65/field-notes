package com.fieldnotes.site.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateSiteRequest(
    @NotBlank
    @Size(max = 150)
    String name,

    @Size(max = 255)
    String address
) {
}
