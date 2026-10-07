CREATE TABLE field_notes (
    id UUID PRIMARY KEY,
    site_id UUID NOT NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT fk_field_notes_site
        FOREIGN KEY (site_id)
        REFERENCES sites(id)
);

CREATE INDEX idx_field_notes_site_id
    ON field_notes(site_id);
