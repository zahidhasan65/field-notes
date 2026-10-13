-- Customers: separate contact fields (contact_information is kept for old clients)
ALTER TABLE customers
    ADD COLUMN contact_person VARCHAR(150),
    ADD COLUMN email VARCHAR(255),
    ADD COLUMN phone VARCHAR(50),
    ADD COLUMN address VARCHAR(255);

-- Sites: optional map location
ALTER TABLE sites
    ADD COLUMN latitude DOUBLE PRECISION,
    ADD COLUMN longitude DOUBLE PRECISION;

-- Field notes: full set of fields required by the app
ALTER TABLE field_notes
    ADD COLUMN title VARCHAR(200),
    ADD COLUMN description TEXT,
    ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    ADD COLUMN note_datetime TIMESTAMPTZ,
    ADD COLUMN latitude DOUBLE PRECISION,
    ADD COLUMN longitude DOUBLE PRECISION,
    ADD COLUMN photo_path VARCHAR(500);

-- Migrate the old single "note" text
UPDATE field_notes
SET title = LEFT(note, 200),
    description = note,
    note_datetime = created_at;

ALTER TABLE field_notes
    ALTER COLUMN title SET NOT NULL,
    ALTER COLUMN note_datetime SET NOT NULL,
    ADD CONSTRAINT chk_field_notes_status
        CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED'));

ALTER TABLE field_notes DROP COLUMN note;

-- Indexes used by sync (updated_since) and search
CREATE INDEX idx_customers_user_updated ON customers(user_id, updated_at);
CREATE INDEX idx_sites_customer_updated ON sites(customer_id, updated_at);
CREATE INDEX idx_field_notes_site_updated ON field_notes(site_id, updated_at);
CREATE INDEX idx_field_notes_status ON field_notes(status);
