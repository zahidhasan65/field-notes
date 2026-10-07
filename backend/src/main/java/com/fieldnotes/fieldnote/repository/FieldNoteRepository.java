package com.fieldnotes.fieldnote.repository;

import com.fieldnotes.fieldnote.entity.FieldNote;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FieldNoteRepository extends JpaRepository<FieldNote, UUID> {

    List<FieldNote> findAllBySiteIdAndSiteCustomerUserIdAndDeletedAtIsNull(
        UUID siteId,
        UUID userId
    );

    Optional<FieldNote> findByIdAndSiteCustomerUserIdAndDeletedAtIsNull(
        UUID fieldNoteId,
        UUID userId
    );
}
