package com.fieldnotes.fieldnote.controller;

import com.fieldnotes.fieldnote.dto.FieldNoteDetailResponse;
import com.fieldnotes.fieldnote.dto.FieldNoteResponse;
import com.fieldnotes.fieldnote.entity.NoteStatus;
import com.fieldnotes.fieldnote.service.FieldNoteService;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

/**
 * Cross-site queries and photo endpoints.
 *  GET    /api/field-notes?search=&status=&siteId=   (JOIN based search / filter)
 *  POST   /api/field-notes/{id}/photo                (multipart, field "file")
 *  GET    /api/field-notes/{id}/photo
 *  DELETE /api/field-notes/{id}/photo
 */
@RestController
@RequestMapping("/api/field-notes")
public class FieldNoteQueryController {

    private final FieldNoteService fieldNoteService;

    public FieldNoteQueryController(FieldNoteService fieldNoteService) {
        this.fieldNoteService = fieldNoteService;
    }

    @GetMapping
    public ResponseEntity<List<FieldNoteDetailResponse>> search(
        Authentication authentication,
        @RequestParam(required = false) String search,
        @RequestParam(required = false) NoteStatus status,
        @RequestParam(required = false) UUID siteId
    ) {
        return ResponseEntity.ok(
            fieldNoteService.search(getUserId(authentication), search, status, siteId)
        );
    }

    @PostMapping(path = "/{fieldNoteId}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<FieldNoteResponse> uploadPhoto(
        Authentication authentication,
        @PathVariable UUID fieldNoteId,
        @RequestParam("file") MultipartFile file
    ) throws IOException {
        return ResponseEntity.ok(
            fieldNoteService.savePhoto(getUserId(authentication), fieldNoteId, file)
        );
    }

    @PutMapping(path = "/{fieldNoteId}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<FieldNoteResponse> replacePhoto(
        Authentication authentication,
        @PathVariable UUID fieldNoteId,
        @RequestParam("file") MultipartFile file
    ) throws IOException {
        return uploadPhoto(authentication, fieldNoteId, file);
    }

    @GetMapping("/{fieldNoteId}/photo")
    public ResponseEntity<Resource> getPhoto(
        Authentication authentication,
        @PathVariable UUID fieldNoteId
    ) {
        FieldNoteService.PhotoFile photo =
            fieldNoteService.loadPhoto(getUserId(authentication), fieldNoteId);

        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(photo.contentType()))
            .cacheControl(CacheControl.noCache())
            .body(photo.resource());
    }

    @DeleteMapping("/{fieldNoteId}/photo")
    public ResponseEntity<Void> deletePhoto(
        Authentication authentication,
        @PathVariable UUID fieldNoteId
    ) {
        fieldNoteService.deletePhoto(getUserId(authentication), fieldNoteId);
        return ResponseEntity.noContent().build();
    }

    private UUID getUserId(Authentication authentication) {
        return (UUID) authentication.getPrincipal();
    }
}
