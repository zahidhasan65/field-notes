package com.fieldnotes.fieldnote.entity;

import com.fieldnotes.common.persistence.BaseEntity;
import com.fieldnotes.site.entity.Site;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "field_notes")
public class FieldNote extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "site_id", nullable = false)
    private Site site;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String note;

    protected FieldNote() {
        super();
    }

    public FieldNote(
        Site site,
        String note
    ) {
        super();
        this.site = site;
        this.note = note;
    }

    public Site getSite() {
        return site;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
