package com.fieldnotes.fieldnote.controller;

import com.fieldnotes.fieldnote.dto.CreateFieldNoteRequest;
import com.fieldnotes.fieldnote.dto.FieldNoteResponse;
import com.fieldnotes.fieldnote.dto.UpdateFieldNoteRequest;
import com.fieldnotes.fieldnote.service.FieldNoteService;
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
@RequestMapping("/api/sites/{siteId}/field-notes")
public class FieldNoteController {

    private final FieldNoteService fieldNoteService;

    public FieldNoteController(FieldNoteService fieldNoteService) {
        this.fieldNoteService = fieldNoteService;
    }

    @PostMapping
    public ResponseEntity<FieldNoteResponse> create(
        Authentication authentication,
        @PathVariable UUID siteId,
        @Valid @RequestBody CreateFieldNoteRequest request
    ) {
        UUID userId = getUserId(authentication);

        FieldNoteResponse response = fieldNoteService.create(
            userId,
            siteId,
            request
        );

        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(response);
    }

    @GetMapping
    public ResponseEntity<List<FieldNoteResponse>> findAll(
        Authentication authentication,
        @PathVariable UUID siteId
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            fieldNoteService.findAll(userId, siteId)
        );
    }

    @GetMapping("/{fieldNoteId}")
    public ResponseEntity<FieldNoteResponse> findById(
        Authentication authentication,
        @PathVariable UUID fieldNoteId
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            fieldNoteService.findById(userId, fieldNoteId)
        );
    }

    @PutMapping("/{fieldNoteId}")
    public ResponseEntity<FieldNoteResponse> update(
        Authentication authentication,
        @PathVariable UUID fieldNoteId,
        @Valid @RequestBody UpdateFieldNoteRequest request
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            fieldNoteService.update(
                userId,
                fieldNoteId,
                request
            )
        );
    }

    @DeleteMapping("/{fieldNoteId}")
    public ResponseEntity<Void> delete(
        Authentication authentication,
        @PathVariable UUID fieldNoteId
    ) {
        UUID userId = getUserId(authentication);

        fieldNoteService.delete(userId, fieldNoteId);

        return ResponseEntity.noContent().build();
    }

    private UUID getUserId(Authentication authentication) {
        return (UUID) authentication.getPrincipal();
    }
}
