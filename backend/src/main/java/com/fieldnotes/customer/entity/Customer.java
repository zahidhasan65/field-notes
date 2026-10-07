package com.fieldnotes.customer.entity;

import com.fieldnotes.common.persistence.BaseEntity;
import com.fieldnotes.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

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

    protected Customer() {
        super();
    }

    public Customer(
        User user,
        String name,
        String contactInformation
    ) {
        super();
        this.user = user;
        this.name = name;
        this.contactInformation = contactInformation;
    }

    public User getUser() {
        return user;
    }

    public String getName() {
        return name;
    }

    public String getContactInformation() {
        return contactInformation;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setContactInformation(String contactInformation) {
        this.contactInformation = contactInformation;
    }
}
