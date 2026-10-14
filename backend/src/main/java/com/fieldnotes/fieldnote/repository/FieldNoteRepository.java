package com.fieldnotes.fieldnote.repository;

import com.fieldnotes.fieldnote.entity.FieldNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FieldNoteRepository
    extends JpaRepository<FieldNote, UUID>, JpaSpecificationExecutor<FieldNote> {

    List<FieldNote> findAllBySiteIdAndSiteCustomerUserIdAndDeletedAtIsNull(
        UUID siteId,
        UUID userId
    );

    List<FieldNote> findAllBySiteIdAndDeletedAtIsNull(UUID siteId);

    List<FieldNote> findAllBySiteCustomerUserIdAndDeletedAtIsNull(UUID userId);

    
    List<FieldNote> findAllBySiteCustomerUserIdAndUpdatedAtAfter(UUID userId, Instant since);

    Optional<FieldNote> findByIdAndSiteCustomerUserIdAndDeletedAtIsNull(
        UUID fieldNoteId,
        UUID userId
    );
}
