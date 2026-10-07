package com.fieldnotes.site.service;

import com.fieldnotes.customer.entity.Customer;
import com.fieldnotes.customer.repository.CustomerRepository;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.site.dto.CreateSiteRequest;
import com.fieldnotes.site.dto.SiteResponse;
import com.fieldnotes.site.dto.UpdateSiteRequest;
import com.fieldnotes.site.entity.Site;
import com.fieldnotes.site.repository.SiteRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class SiteService {

    private final SiteRepository siteRepository;
    private final CustomerRepository customerRepository;

    public SiteService(
        SiteRepository siteRepository,
        CustomerRepository customerRepository
    ) {
        this.siteRepository = siteRepository;
        this.customerRepository = customerRepository;
    }

    public SiteResponse create(
        UUID userId,
        UUID customerId,
        CreateSiteRequest request
    ) {
        Customer customer = getCustomer(userId, customerId);

        Site site = new Site(
            customer,
            request.name().trim(),
            request.address()
        );

        Site savedSite = siteRepository.save(site);

        return toResponse(savedSite);
    }

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

    public SiteResponse findById(
        UUID userId,
        UUID siteId
    ) {
        Site site = getSite(userId, siteId);

        return toResponse(site);
    }

    public SiteResponse update(
        UUID userId,
        UUID siteId,
        UpdateSiteRequest request
    ) {
        Site site = getSite(userId, siteId);

        site.setName(request.name().trim());
        site.setAddress(request.address());

        Site updatedSite = siteRepository.save(site);

        return toResponse(updatedSite);
    }

    public void delete(
        UUID userId,
        UUID siteId
    ) {
        Site site = getSite(userId, siteId);

        site.setDeletedAt(Instant.now());

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

    private SiteResponse toResponse(Site site) {
        return new SiteResponse(
            site.getId(),
            site.getCustomer().getId(),
            site.getName(),
            site.getAddress(),
            site.getCreatedAt(),
            site.getUpdatedAt()
        );
    }
}
