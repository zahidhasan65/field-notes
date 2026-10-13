package com.fieldnotes.sync.service;

import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.customer.entity.Customer;
import com.fieldnotes.customer.repository.CustomerRepository;
import com.fieldnotes.customer.service.CustomerService;
import com.fieldnotes.fieldnote.dto.FieldNoteResponse;
import com.fieldnotes.fieldnote.entity.FieldNote;
import com.fieldnotes.fieldnote.repository.FieldNoteRepository;
import com.fieldnotes.fieldnote.service.FieldNoteService;
import com.fieldnotes.site.dto.SiteResponse;
import com.fieldnotes.site.entity.Site;
import com.fieldnotes.site.repository.SiteRepository;
import com.fieldnotes.sync.dto.SyncChangesResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class SyncService {

    private final CustomerRepository customerRepository;
    private final SiteRepository siteRepository;
    private final FieldNoteRepository fieldNoteRepository;
    private final CustomerService customerService;
    private final com.fieldnotes.site.service.SiteService siteService;
    private final FieldNoteService fieldNoteService;

    public SyncService(
        CustomerRepository customerRepository,
        SiteRepository siteRepository,
        FieldNoteRepository fieldNoteRepository,
        CustomerService customerService,
        com.fieldnotes.site.service.SiteService siteService,
        FieldNoteService fieldNoteService
    ) {
        this.customerRepository = customerRepository;
        this.siteRepository = siteRepository;
        this.fieldNoteRepository = fieldNoteRepository;
        this.customerService = customerService;
        this.siteService = siteService;
        this.fieldNoteService = fieldNoteService;
    }

    /**
     * since == null  -> full snapshot of the user's live data (used to restore after reinstall)
     * since != null  -> only rows changed after "since", including soft deleted ones
     */
    public SyncChangesResponse getChanges(UUID userId, Instant since) {
        Instant serverTime = Instant.now();

        List<Customer> customers;
        List<Site> sites;
        List<FieldNote> notes;

        if (since == null) {
            customers = customerRepository.findAllByUserIdAndDeletedAtIsNull(userId);
            sites = siteRepository.findAllByCustomerUserIdAndDeletedAtIsNull(userId);
            notes = fieldNoteRepository.findAllBySiteCustomerUserIdAndDeletedAtIsNull(userId);
        } else {
            customers = customerRepository.findAllByUserIdAndUpdatedAtAfter(userId, since);
            sites = siteRepository.findAllByCustomerUserIdAndUpdatedAtAfter(userId, since);
            notes = fieldNoteRepository.findAllBySiteCustomerUserIdAndUpdatedAtAfter(userId, since);
        }

        List<CustomerResponse> customerDtos = customers.stream().map(customerService::toResponse).toList();
        List<SiteResponse> siteDtos = sites.stream().map(siteService::toResponse).toList();
        List<FieldNoteResponse> noteDtos = notes.stream().map(fieldNoteService::toResponse).toList();

        return new SyncChangesResponse(serverTime, customerDtos, siteDtos, noteDtos);
    }
}
