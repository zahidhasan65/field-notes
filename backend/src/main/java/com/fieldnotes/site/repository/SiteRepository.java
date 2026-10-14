package com.fieldnotes.site.repository;

import com.fieldnotes.site.entity.Site;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SiteRepository extends JpaRepository<Site, UUID> {

    List<Site> findAllByCustomerUserIdAndCustomerIdAndDeletedAtIsNull(
        UUID userId,
        UUID customerId
    );

    List<Site> findAllByCustomerIdAndDeletedAtIsNull(UUID customerId);

    List<Site> findAllByCustomerUserIdAndDeletedAtIsNull(UUID userId);

    
    List<Site> findAllByCustomerUserIdAndUpdatedAtAfter(UUID userId, Instant since);

    Optional<Site> findByIdAndCustomerUserIdAndDeletedAtIsNull(
        UUID siteId,
        UUID userId
    );
}
