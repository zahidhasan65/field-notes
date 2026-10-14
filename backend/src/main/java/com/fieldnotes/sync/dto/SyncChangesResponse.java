package com.fieldnotes.sync.dto;

import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.fieldnote.dto.FieldNoteResponse;
import com.fieldnotes.site.dto.SiteResponse;

import java.time.Instant;
import java.util.List;


public record SyncChangesResponse(
    Instant serverTime,
    List<CustomerResponse> customers,
    List<SiteResponse> sites,
    List<FieldNoteResponse> fieldNotes
) {
}
