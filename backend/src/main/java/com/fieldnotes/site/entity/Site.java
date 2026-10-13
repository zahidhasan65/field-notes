package com.fieldnotes.site.entity;

import com.fieldnotes.common.persistence.BaseEntity;
import com.fieldnotes.customer.entity.Customer;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "sites")
public class Site extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(length = 255)
    private String address;

    private Double latitude;

    private Double longitude;

    protected Site() {
        super();
    }

    public Site(
        UUID id,
        Customer customer,
        String name,
        String address,
        Double latitude,
        Double longitude
    ) {
        super(id != null ? id : UUID.randomUUID());
        this.customer = customer;
        this.name = name;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public Customer getCustomer() { return customer; }
    public String getName() { return name; }
    public String getAddress() { return address; }
    public Double getLatitude() { return latitude; }
    public Double getLongitude() { return longitude; }

    public void setCustomer(Customer customer) { this.customer = customer; }
    public void setName(String name) { this.name = name; }
    public void setAddress(String address) { this.address = address; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
}
