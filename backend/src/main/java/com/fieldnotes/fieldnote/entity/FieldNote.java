package com.fieldnotes.fieldnote.entity;

import com.fieldnotes.common.persistence.BaseEntity;
import com.fieldnotes.site.entity.Site;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "field_notes")
public class FieldNote extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "site_id", nullable = false)
    private Site site;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NoteStatus status;

    @Column(name = "note_datetime", nullable = false)
    private Instant noteDatetime;

    private Double latitude;

    private Double longitude;

    
    @Column(name = "photo_path", length = 500)
    private String photoPath;

    protected FieldNote() {
        super();
    }

    public FieldNote(
        UUID id,
        Site site,
        String title,
        String description,
        NoteStatus status,
        Instant noteDatetime,
        Double latitude,
        Double longitude
    ) {
        super(id != null ? id : UUID.randomUUID());
        this.site = site;
        this.title = title;
        this.description = description;
        this.status = status != null ? status : NoteStatus.PENDING;
        this.noteDatetime = noteDatetime != null ? noteDatetime : Instant.now();
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public Site getSite() { return site; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public NoteStatus getStatus() { return status; }
    public Instant getNoteDatetime() { return noteDatetime; }
    public Double getLatitude() { return latitude; }
    public Double getLongitude() { return longitude; }
    public String getPhotoPath() { return photoPath; }

    public void setSite(Site site) { this.site = site; }
    public void setTitle(String title) { this.title = title; }
    public void setDescription(String description) { this.description = description; }
    public void setStatus(NoteStatus status) { this.status = status; }
    public void setNoteDatetime(Instant noteDatetime) { this.noteDatetime = noteDatetime; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public void setPhotoPath(String photoPath) { this.photoPath = photoPath; }
}
