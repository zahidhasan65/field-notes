package com.fieldnotes.sync.dto;

import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.fieldnote.dto.FieldNoteResponse;
import com.fieldnotes.site.dto.SiteResponse;

import java.time.Instant;
import java.util.List;

/**
 * Everything that changed since the client's last pull.
 * Items with a non-null deletedAt are tombstones (the client must delete them locally).
 * Store serverTime and send it back as "since" on the next pull.
 */
public record SyncChangesResponse(
    Instant serverTime,
    List<CustomerResponse> customers,
    List<SiteResponse> sites,
    List<FieldNoteResponse> fieldNotes
) {
}
