package com.fieldnotes.customer.service;

import com.fieldnotes.customer.dto.CreateCustomerRequest;
import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.customer.dto.UpdateCustomerRequest;
import com.fieldnotes.customer.entity.Customer;
import com.fieldnotes.customer.repository.CustomerRepository;
import com.fieldnotes.exception.DuplicateResourceException;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.fieldnote.entity.FieldNote;
import com.fieldnotes.fieldnote.repository.FieldNoteRepository;
import com.fieldnotes.site.entity.Site;
import com.fieldnotes.site.repository.SiteRepository;
import com.fieldnotes.user.entity.User;
import com.fieldnotes.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;
    private final SiteRepository siteRepository;
    private final FieldNoteRepository fieldNoteRepository;

    public CustomerService(
        CustomerRepository customerRepository,
        UserRepository userRepository,
        SiteRepository siteRepository,
        FieldNoteRepository fieldNoteRepository
    ) {
        this.customerRepository = customerRepository;
        this.userRepository = userRepository;
        this.siteRepository = siteRepository;
        this.fieldNoteRepository = fieldNoteRepository;
    }

    
    public CustomerResponse create(
        UUID userId,
        CreateCustomerRequest request
    ) {
        if (request.id() != null) {
            Optional<Customer> existing = customerRepository.findById(request.id());
            if (existing.isPresent()) {
                Customer customer = existing.get();
                if (!customer.getUser().getId().equals(userId)) {
                    throw new DuplicateResourceException("Customer id is already in use");
                }
                return toResponse(customer);
            }
        }

        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Customer customer = new Customer(
            request.id(),
            user,
            request.name().trim(),
            request.contactInformation(),
            request.contactPerson(),
            request.email(),
            request.phone(),
            request.address()
        );

        return toResponse(customerRepository.save(customer));
    }

    @Transactional(readOnly = true)
    public List<CustomerResponse> findAll(UUID userId) {
        return customerRepository
            .findAllByUserIdAndDeletedAtIsNull(userId)
            .stream()
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public CustomerResponse findById(UUID userId, UUID customerId) {
        return toResponse(getCustomer(userId, customerId));
    }

    public CustomerResponse update(
        UUID userId,
        UUID customerId,
        UpdateCustomerRequest request
    ) {
        Customer customer = getCustomer(userId, customerId);
        customer.setName(request.name().trim());
        customer.setContactInformation(request.contactInformation());
        customer.setContactPerson(request.contactPerson());
        customer.setEmail(request.email());
        customer.setPhone(request.phone());
        customer.setAddress(request.address());
        return toResponse(customerRepository.save(customer));
    }

    
    public void delete(UUID userId, UUID customerId) {
        Customer customer = getCustomer(userId, customerId);
        Instant now = Instant.now();

        for (Site site : siteRepository.findAllByCustomerIdAndDeletedAtIsNull(customerId)) {
            for (FieldNote note : fieldNoteRepository.findAllBySiteIdAndDeletedAtIsNull(site.getId())) {
                note.setDeletedAt(now);
            }
            site.setDeletedAt(now);
        }

        customer.setDeletedAt(now);
        customerRepository.save(customer);
    }

    private Customer getCustomer(UUID userId, UUID customerId) {
        return customerRepository
            .findByIdAndUserIdAndDeletedAtIsNull(customerId, userId)
            .orElseThrow(() ->
                new ResourceNotFoundException("Customer not found")
            );
    }

    public CustomerResponse toResponse(Customer customer) {
        return new CustomerResponse(
            customer.getId(),
            customer.getName(),
            customer.getContactInformation(),
            customer.getContactPerson(),
            customer.getEmail(),
            customer.getPhone(),
            customer.getAddress(),
            customer.getCreatedAt(),
            customer.getUpdatedAt(),
            customer.getDeletedAt()
        );
    }
}
