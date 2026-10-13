package com.fieldnotes.site.service;

import com.fieldnotes.customer.entity.Customer;
import com.fieldnotes.customer.repository.CustomerRepository;
import com.fieldnotes.exception.DuplicateResourceException;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.fieldnote.entity.FieldNote;
import com.fieldnotes.fieldnote.repository.FieldNoteRepository;
import com.fieldnotes.site.dto.CreateSiteRequest;
import com.fieldnotes.site.dto.SiteResponse;
import com.fieldnotes.site.dto.UpdateSiteRequest;
import com.fieldnotes.site.entity.Site;
import com.fieldnotes.site.repository.SiteRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional
public class SiteService {

    private final SiteRepository siteRepository;
    private final CustomerRepository customerRepository;
    private final FieldNoteRepository fieldNoteRepository;

    public SiteService(
        SiteRepository siteRepository,
        CustomerRepository customerRepository,
        FieldNoteRepository fieldNoteRepository
    ) {
        this.siteRepository = siteRepository;
        this.customerRepository = customerRepository;
        this.fieldNoteRepository = fieldNoteRepository;
    }

    /** Idempotent when request.id() is supplied. */
    public SiteResponse create(
        UUID userId,
        UUID customerId,
        CreateSiteRequest request
    ) {
        if (request.id() != null) {
            Optional<Site> existing = siteRepository.findById(request.id());
            if (existing.isPresent()) {
                Site site = existing.get();
                if (!site.getCustomer().getUser().getId().equals(userId)) {
                    throw new DuplicateResourceException("Site id is already in use");
                }
                return toResponse(site);
            }
        }

        Customer customer = getCustomer(userId, customerId);

        Site site = new Site(
            request.id(),
            customer,
            request.name().trim(),
            request.address(),
            request.latitude(),
            request.longitude()
        );

        return toResponse(siteRepository.save(site));
    }

    @Transactional(readOnly = true)
    public List<SiteResponse> findAll(
        UUID userId,
        UUID customerId
    ) {
        getCustomer(userId, customerId);

        return siteRepository
            .findAllByCustomerUserIdAndCustomerIdAndDeletedAtIsNull(
                userId,
                customerId
            )
            .stream()
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public SiteResponse findById(
        UUID userId,
        UUID siteId
    ) {
        return toResponse(getSite(userId, siteId));
    }

    public SiteResponse update(
        UUID userId,
        UUID siteId,
        UpdateSiteRequest request
    ) {
        Site site = getSite(userId, siteId);

        if (request.customerId() != null
            && !request.customerId().equals(site.getCustomer().getId())) {
            site.setCustomer(getCustomer(userId, request.customerId()));
        }

        site.setName(request.name().trim());
        site.setAddress(request.address());
        site.setLatitude(request.latitude());
        site.setLongitude(request.longitude());

        return toResponse(siteRepository.save(site));
    }

    /** Soft deletes the site together with its field notes. */
    public void delete(
        UUID userId,
        UUID siteId
    ) {
        Site site = getSite(userId, siteId);
        Instant now = Instant.now();

        for (FieldNote note : fieldNoteRepository.findAllBySiteIdAndDeletedAtIsNull(siteId)) {
            note.setDeletedAt(now);
        }

        site.setDeletedAt(now);
        siteRepository.save(site);
    }

    private Customer getCustomer(
        UUID userId,
        UUID customerId
    ) {
        return customerRepository
            .findByIdAndUserIdAndDeletedAtIsNull(
                customerId,
                userId
            )
            .orElseThrow(() ->
                new ResourceNotFoundException("Customer not found")
            );
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

    public SiteResponse toResponse(Site site) {
        return new SiteResponse(
            site.getId(),
            site.getCustomer().getId(),
            site.getName(),
            site.getAddress(),
            site.getLatitude(),
            site.getLongitude(),
            site.getCreatedAt(),
            site.getUpdatedAt(),
            site.getDeletedAt()
        );
    }
}
