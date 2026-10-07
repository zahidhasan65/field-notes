package com.fieldnotes.customer.service;

import com.fieldnotes.customer.dto.CreateCustomerRequest;
import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.customer.dto.UpdateCustomerRequest;
import com.fieldnotes.customer.entity.Customer;
import com.fieldnotes.customer.repository.CustomerRepository;
import com.fieldnotes.exception.ResourceNotFoundException;
import com.fieldnotes.user.entity.User;
import com.fieldnotes.user.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;

    public CustomerService(
        CustomerRepository customerRepository,
        UserRepository userRepository
    ) {
        this.customerRepository = customerRepository;
        this.userRepository = userRepository;
    }

    public CustomerResponse create(
        UUID userId,
        CreateCustomerRequest request
    ) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Customer customer = new Customer(
            user,
            request.name().trim(),
            request.contactInformation()
        );

        Customer savedCustomer = customerRepository.save(customer);

        return toResponse(savedCustomer);
    }

    public List<CustomerResponse> findAll(UUID userId) {
        return customerRepository
            .findAllByUserIdAndDeletedAtIsNull(userId)
            .stream()
            .map(this::toResponse)
            .toList();
    }

    public CustomerResponse findById(UUID userId, UUID customerId) {
        Customer customer = getCustomer(userId, customerId);

        return toResponse(customer);
    }

    public CustomerResponse update(
        UUID userId,
        UUID customerId,
        UpdateCustomerRequest request
    ) {
        Customer customer = getCustomer(userId, customerId);

        customer.setName(request.name().trim());
        customer.setContactInformation(request.contactInformation());

        Customer updatedCustomer = customerRepository.save(customer);

        return toResponse(updatedCustomer);
    }

    public void delete(UUID userId, UUID customerId) {
        Customer customer = getCustomer(userId, customerId);

        customer.setDeletedAt(java.time.Instant.now());

        customerRepository.save(customer);
    }

    private Customer getCustomer(UUID userId, UUID customerId) {
        return customerRepository
            .findByIdAndUserIdAndDeletedAtIsNull(customerId, userId)
            .orElseThrow(() ->
                new ResourceNotFoundException("Customer not found")
            );
    }

    private CustomerResponse toResponse(Customer customer) {
        return new CustomerResponse(
            customer.getId(),
            customer.getName(),
            customer.getContactInformation(),
            customer.getCreatedAt(),
            customer.getUpdatedAt()
        );
    }
}
