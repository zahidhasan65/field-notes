package com.fieldnotes.fieldnote.service;

import com.fieldnotes.customer.entity.Customer;
import com.fieldnotes.exception.DuplicateResourceException;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.fieldnote.dto.CreateFieldNoteRequest;
import com.fieldnotes.fieldnote.dto.FieldNoteDetailResponse;
import com.fieldnotes.fieldnote.dto.FieldNoteResponse;
import com.fieldnotes.fieldnote.dto.UpdateFieldNoteRequest;
import com.fieldnotes.fieldnote.entity.FieldNote;
import com.fieldnotes.fieldnote.entity.NoteStatus;
import com.fieldnotes.fieldnote.repository.FieldNoteRepository;
import com.fieldnotes.fieldnote.storage.PhotoStorageService;
import com.fieldnotes.site.entity.Site;
import com.fieldnotes.site.repository.SiteRepository;
import jakarta.persistence.criteria.Fetch;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.Predicate;
import org.springframework.core.io.Resource;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional
public class FieldNoteService {

    private final FieldNoteRepository fieldNoteRepository;
    private final SiteRepository siteRepository;
    private final PhotoStorageService photoStorage;

    public FieldNoteService(
        FieldNoteRepository fieldNoteRepository,
        SiteRepository siteRepository,
        PhotoStorageService photoStorage
    ) {
        this.fieldNoteRepository = fieldNoteRepository;
        this.siteRepository = siteRepository;
        this.photoStorage = photoStorage;
    }

    /** Idempotent when request.id() is supplied. */
    public FieldNoteResponse create(
        UUID userId,
        UUID siteId,
        CreateFieldNoteRequest request
    ) {
        if (request.id() != null) {
            Optional<FieldNote> existing = fieldNoteRepository.findById(request.id());
            if (existing.isPresent()) {
                FieldNote note = existing.get();
                if (!note.getSite().getCustomer().getUser().getId().equals(userId)) {
                    throw new DuplicateResourceException("Field note id is already in use");
                }
                return toResponse(note);
            }
        }

        Site site = getSite(userId, siteId);

        FieldNote fieldNote = new FieldNote(
            request.id(),
            site,
            request.title().trim(),
            request.description(),
            request.status(),
            request.noteDatetime(),
            request.latitude(),
            request.longitude()
        );

        return toResponse(fieldNoteRepository.save(fieldNote));
    }

    @Transactional(readOnly = true)
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

    @Transactional(readOnly = true)
    public FieldNoteResponse findById(
        UUID userId,
        UUID fieldNoteId
    ) {
        return toResponse(getFieldNote(userId, fieldNoteId));
    }

    /**
     * Search / filter across notes using JOINs (note -> site -> customer).
     * search matches title, description, site name and customer name.
     */
    @Transactional(readOnly = true)
    @SuppressWarnings("unchecked")
    public List<FieldNoteDetailResponse> search(
        UUID userId,
        String search,
        NoteStatus status,
        UUID siteId
    ) {
        Specification<FieldNote> spec = (root, query, cb) -> {
            Join<FieldNote, Site> site;
            Join<Site, Customer> customer;

            if (query != null && query.getResultType() != Long.class) {
                Fetch<FieldNote, Site> siteFetch = root.fetch("site");
                site = (Join<FieldNote, Site>) siteFetch;
                Fetch<Site, Customer> customerFetch = siteFetch.fetch("customer");
                customer = (Join<Site, Customer>) customerFetch;
                query.orderBy(cb.desc(root.get("noteDatetime")));
            } else {
                site = root.join("site");
                customer = site.join("customer");
            }

            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(customer.get("user").get("id"), userId));
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.isNull(site.get("deletedAt")));
            predicates.add(cb.isNull(customer.get("deletedAt")));

            if (siteId != null) {
                predicates.add(cb.equal(site.get("id"), siteId));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (search != null && !search.isBlank()) {
                String like = "%" + search.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                    cb.like(cb.lower(root.get("title")), like),
                    cb.like(cb.lower(cb.coalesce(root.<String>get("description"), "")), like),
                    cb.like(cb.lower(site.<String>get("name")), like),
                    cb.like(cb.lower(customer.<String>get("name")), like)
                ));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return fieldNoteRepository.findAll(spec)
            .stream()
            .map(this::toDetailResponse)
            .toList();
    }

    public FieldNoteResponse update(
        UUID userId,
        UUID fieldNoteId,
        UpdateFieldNoteRequest request
    ) {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);

        if (request.siteId() != null
            && !request.siteId().equals(fieldNote.getSite().getId())) {
            fieldNote.setSite(getSite(userId, request.siteId()));
        }

        fieldNote.setTitle(request.title().trim());
        fieldNote.setDescription(request.description());
        if (request.status() != null) {
            fieldNote.setStatus(request.status());
        }
        if (request.noteDatetime() != null) {
            fieldNote.setNoteDatetime(request.noteDatetime());
        }
        fieldNote.setLatitude(request.latitude());
        fieldNote.setLongitude(request.longitude());

        return toResponse(fieldNoteRepository.save(fieldNote));
    }

    public void delete(
        UUID userId,
        UUID fieldNoteId
    ) {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);
        fieldNote.setDeletedAt(Instant.now());
        fieldNoteRepository.save(fieldNote);
    }

    // ---------------- photo ----------------

    public FieldNoteResponse savePhoto(
        UUID userId,
        UUID fieldNoteId,
        MultipartFile file
    ) throws IOException {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);
        String oldFile = fieldNote.getPhotoPath();
        fieldNote.setPhotoPath(photoStorage.store(fieldNoteId, file));
        FieldNote saved = fieldNoteRepository.save(fieldNote);
        photoStorage.delete(oldFile);
        return toResponse(saved);
    }

    public void deletePhoto(UUID userId, UUID fieldNoteId) {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);
        String oldFile = fieldNote.getPhotoPath();
        fieldNote.setPhotoPath(null);
        fieldNoteRepository.save(fieldNote);
        photoStorage.delete(oldFile);
    }

    @Transactional(readOnly = true)
    public PhotoFile loadPhoto(UUID userId, UUID fieldNoteId) {
        FieldNote fieldNote = getFieldNote(userId, fieldNoteId);
        String fileName = fieldNote.getPhotoPath();
        if (fileName == null) {
            throw new ResourceNotFoundException("Photo not found");
        }
        Resource resource = photoStorage.load(fileName);
        if (resource == null) {
            throw new ResourceNotFoundException("Photo not found");
        }
        return new PhotoFile(resource, photoStorage.contentTypeOf(fileName));
    }

    public record PhotoFile(Resource resource, String contentType) {
    }

    // ---------------- helpers ----------------

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

    private String photoUrl(FieldNote fieldNote) {
        return fieldNote.getPhotoPath() == null
            ? null
            : "/api/field-notes/" + fieldNote.getId() + "/photo";
    }

    public FieldNoteResponse toResponse(FieldNote fieldNote) {
        return new FieldNoteResponse(
            fieldNote.getId(),
            fieldNote.getSite().getId(),
            fieldNote.getTitle(),
            fieldNote.getDescription(),
            fieldNote.getStatus(),
            fieldNote.getNoteDatetime(),
            fieldNote.getLatitude(),
            fieldNote.getLongitude(),
            photoUrl(fieldNote),
            fieldNote.getCreatedAt(),
            fieldNote.getUpdatedAt(),
            fieldNote.getDeletedAt()
        );
    }

    public FieldNoteDetailResponse toDetailResponse(FieldNote fieldNote) {
        Site site = fieldNote.getSite();
        Customer customer = site.getCustomer();
        return new FieldNoteDetailResponse(
            fieldNote.getId(),
            site.getId(),
            site.getName(),
            customer.getId(),
            customer.getName(),
            fieldNote.getTitle(),
            fieldNote.getDescription(),
            fieldNote.getStatus(),
            fieldNote.getNoteDatetime(),
            fieldNote.getLatitude(),
            fieldNote.getLongitude(),
            photoUrl(fieldNote),
            fieldNote.getCreatedAt(),
            fieldNote.getUpdatedAt()
        );
    }
}
