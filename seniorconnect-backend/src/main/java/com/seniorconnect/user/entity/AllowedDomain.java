package com.seniorconnect.user.entity;

import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "allowed_domains")
public class AllowedDomain {

    @Id
    private UUID id;

    @Column(name = "domain", nullable = false, unique = true)
    private String domain;

    @Column(name = "college_name", nullable = false)
    private String collegeName;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public AllowedDomain() {
    }

    public AllowedDomain(UUID id, String domain, String collegeName, boolean isActive, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.domain = domain;
        this.collegeName = collegeName;
        this.isActive = isActive;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    @PrePersist
    protected void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public String getDomain() {
        return domain;
    }

    public void setDomain(String domain) {
        this.domain = domain;
    }

    public String getCollegeName() {
        return collegeName;
    }

    public void setCollegeName(String collegeName) {
        this.collegeName = collegeName;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
