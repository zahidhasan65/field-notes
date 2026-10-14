package com.fieldnotes.customer.entity;

import com.fieldnotes.common.persistence.BaseEntity;
import com.fieldnotes.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "customers")
public class Customer extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(name = "contact_information", length = 255)
    private String contactInformation;

    @Column(name = "contact_person", length = 150)
    private String contactPerson;

    @Column(length = 255)
    private String email;

    @Column(length = 50)
    private String phone;

    @Column(length = 255)
    private String address;

    protected Customer() {
        super();
    }

    
    public Customer(
        UUID id,
        User user,
        String name,
        String contactInformation,
        String contactPerson,
        String email,
        String phone,
        String address
    ) {
        super(id != null ? id : UUID.randomUUID());
        this.user = user;
        this.name = name;
        this.contactInformation = contactInformation;
        this.contactPerson = contactPerson;
        this.email = email;
        this.phone = phone;
        this.address = address;
    }

    public User getUser() { return user; }
    public String getName() { return name; }
    public String getContactInformation() { return contactInformation; }
    public String getContactPerson() { return contactPerson; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public String getAddress() { return address; }

    public void setName(String name) { this.name = name; }
    public void setContactInformation(String v) { this.contactInformation = v; }
    public void setContactPerson(String v) { this.contactPerson = v; }
    public void setEmail(String v) { this.email = v; }
    public void setPhone(String v) { this.phone = v; }
    public void setAddress(String v) { this.address = v; }
}
