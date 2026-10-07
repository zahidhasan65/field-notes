CREATE TABLE sites (
    id UUID PRIMARY KEY,
    customer_id UUID NOT NULL,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT fk_sites_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(id)
);

CREATE INDEX idx_sites_customer_id
    ON sites(customer_id);
