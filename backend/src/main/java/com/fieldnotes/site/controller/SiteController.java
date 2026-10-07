package com.fieldnotes.site.controller;

import com.fieldnotes.site.dto.CreateSiteRequest;
import com.fieldnotes.site.dto.SiteResponse;
import com.fieldnotes.site.dto.UpdateSiteRequest;
import com.fieldnotes.site.service.SiteService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/customers/{customerId}/sites")
public class SiteController {

    private final SiteService siteService;

    public SiteController(SiteService siteService) {
        this.siteService = siteService;
    }

    @PostMapping
    public ResponseEntity<SiteResponse> create(
        Authentication authentication,
        @PathVariable UUID customerId,
        @Valid @RequestBody CreateSiteRequest request
    ) {
        UUID userId = getUserId(authentication);

        SiteResponse response = siteService.create(
            userId,
            customerId,
            request
        );

        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(response);
    }

    @GetMapping
    public ResponseEntity<List<SiteResponse>> findAll(
        Authentication authentication,
        @PathVariable UUID customerId
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            siteService.findAll(userId, customerId)
        );
    }

    @GetMapping("/{siteId}")
    public ResponseEntity<SiteResponse> findById(
        Authentication authentication,
        @PathVariable UUID siteId
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            siteService.findById(userId, siteId)
        );
    }

    @PutMapping("/{siteId}")
    public ResponseEntity<SiteResponse> update(
        Authentication authentication,
        @PathVariable UUID siteId,
        @Valid @RequestBody UpdateSiteRequest request
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            siteService.update(userId, siteId, request)
        );
    }

    @DeleteMapping("/{siteId}")
    public ResponseEntity<Void> delete(
        Authentication authentication,
        @PathVariable UUID siteId
    ) {
        UUID userId = getUserId(authentication);

        siteService.delete(userId, siteId);

        return ResponseEntity.noContent().build();
    }

    private UUID getUserId(Authentication authentication) {
        return (UUID) authentication.getPrincipal();
    }
}
