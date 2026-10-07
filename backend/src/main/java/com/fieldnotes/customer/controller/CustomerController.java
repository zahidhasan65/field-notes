package com.fieldnotes.customer.controller;

import com.fieldnotes.customer.dto.CreateCustomerRequest;
import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.customer.dto.UpdateCustomerRequest;
import com.fieldnotes.customer.service.CustomerService;
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
@RequestMapping("/api/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @PostMapping
    public ResponseEntity<CustomerResponse> create(
        Authentication authentication,
        @Valid @RequestBody CreateCustomerRequest request
    ) {
        UUID userId = getUserId(authentication);

        CustomerResponse response = customerService.create(
            userId,
            request
        );

        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(response);
    }

    @GetMapping
    public ResponseEntity<List<CustomerResponse>> findAll(
        Authentication authentication
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            customerService.findAll(userId)
        );
    }

    @GetMapping("/{customerId}")
    public ResponseEntity<CustomerResponse> findById(
        Authentication authentication,
        @PathVariable UUID customerId
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            customerService.findById(userId, customerId)
        );
    }

    @PutMapping("/{customerId}")
    public ResponseEntity<CustomerResponse> update(
        Authentication authentication,
        @PathVariable UUID customerId,
        @Valid @RequestBody UpdateCustomerRequest request
    ) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(
            customerService.update(
                userId,
                customerId,
                request
            )
        );
    }

    @DeleteMapping("/{customerId}")
    public ResponseEntity<Void> delete(
        Authentication authentication,
        @PathVariable UUID customerId
    ) {
        UUID userId = getUserId(authentication);

        customerService.delete(userId, customerId);

        return ResponseEntity.noContent().build();
    }

    private UUID getUserId(Authentication authentication) {
        return (UUID) authentication.getPrincipal();
    }
}
