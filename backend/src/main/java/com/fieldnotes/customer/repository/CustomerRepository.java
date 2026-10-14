package com.fieldnotes.customer.repository;

import com.fieldnotes.customer.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CustomerRepository extends JpaRepository<Customer, UUID> {

    List<Customer> findAllByUserIdAndDeletedAtIsNull(UUID userId);

    
    List<Customer> findAllByUserIdAndUpdatedAtAfter(UUID userId, Instant since);

    Optional<Customer> findByIdAndUserIdAndDeletedAtIsNull(
        UUID id,
        UUID userId
    );
}
