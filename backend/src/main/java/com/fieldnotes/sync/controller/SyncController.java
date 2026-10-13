package com.fieldnotes.sync.controller;

import com.fieldnotes.sync.dto.SyncChangesResponse;
import com.fieldnotes.sync.service.SyncService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/sync")
public class SyncController {

    private final SyncService syncService;

    public SyncController(SyncService syncService) {
        this.syncService = syncService;
    }

    /** GET /api/sync/changes            -> full snapshot (restore)
     *  GET /api/sync/changes?since=ISO  -> incremental changes + tombstones */
    @GetMapping("/changes")
    public ResponseEntity<SyncChangesResponse> changes(
        Authentication authentication,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant since
    ) {
        UUID userId = (UUID) authentication.getPrincipal();
        return ResponseEntity.ok(syncService.getChanges(userId, since));
    }
}
