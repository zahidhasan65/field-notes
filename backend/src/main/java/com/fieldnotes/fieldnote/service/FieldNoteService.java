package com.fieldnotes.fieldnote.service;

import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.fieldnote.dto.CreateFieldNoteRequest;
import com.fieldnotes.fieldnote.dto.FieldNoteResponse;
import com.fieldnotes.fieldnote.dto.UpdateFieldNoteRequest;
import com.fieldnotes.fieldnote.entity.FieldNote;
import com.fieldnotes.fieldnote.repository.FieldNoteRepository;
import com.fieldnotes.site.entity.Site;
import com.fieldnotes.site.repository.SiteRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class FieldNoteService {

    private final FieldNoteRepository fieldNoteRepository;
    private final SiteRepository siteRepository;

    public FieldNoteService(
        FieldNoteRepository fieldNoteRepository,
        SiteRepository siteRepository
    ) {
        this.fieldNoteRepository = fieldNoteRepository;
        this.siteRepository = siteRepository;
    }

    public FieldNoteResponse create(
        UUID userId,
        UUID siteId,
        CreateFieldNoteRequest request
    ) {
        Site site = getSite(userId, siteId);

        FieldNote fieldNote = new FieldNote(
            site,
            request.note().trim()
        );

        FieldNote savedFieldNote = fieldNoteRepository.save(fieldNote);

        return toResponse(savedFieldNote);
    }

    public List<FieldNoteResponse> findAll(
        UUID userId,
        UUID siteId
    ) {
        getSite(userId, siteId);

        return fieldNoteRepository
            .findAllBySiteIdAndSiteCustomerUserIdAndDeletedAtIsNull(
                siteId,
                userId
            )
            .stream()
            .map(this::toResponse)
            .toList();
    }

    public FieldNoteResponse findById(
        UUID userId,
        UUID fieldNoteId
    ) {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);

        return toResponse(fieldNote);
    }

    public FieldNoteResponse update(
        UUID userId,
        UUID fieldNoteId,
        UpdateFieldNoteRequest request
    ) {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);

        fieldNote.setNote(request.note().trim());

        FieldNote updatedFieldNote = fieldNoteRepository.save(fieldNote);

        return toResponse(updatedFieldNote);
    }

    public void delete(
        UUID userId,
        UUID fieldNoteId
    ) {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);

        fieldNote.setDeletedAt(Instant.now());

        fieldNoteRepository.save(fieldNote);
    }

    private Site getSite(
        UUID userId,
        UUID siteId
    ) {
        return siteRepository
            .findByIdAndCustomerUserIdAndDeletedAtIsNull(
                siteId,
                userId
            )
            .orElseThrow(() ->
                new ResourceNotFoundException("Site not found")
            );
    }

    private FieldNote getFieldNote(
        UUID userId,
        UUID fieldNoteId
    ) {
        return fieldNoteRepository
            .findByIdAndSiteCustomerUserIdAndDeletedAtIsNull(
                fieldNoteId,
                userId
            )
            .orElseThrow(() ->
                new ResourceNotFoundException("Field note not found")
            );
    }

    private FieldNoteResponse toResponse(FieldNote fieldNote) {
        return new FieldNoteResponse(
            fieldNote.getId(),
            fieldNote.getSite().getId(),
            fieldNote.getNote(),
            fieldNote.getCreatedAt(),
            fieldNote.getUpdatedAt()
        );
    }
}
