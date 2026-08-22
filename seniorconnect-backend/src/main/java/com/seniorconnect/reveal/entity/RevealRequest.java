package com.seniorconnect.reveal.entity;

import com.seniorconnect.query.entity.Query;
import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "reveal_requests", uniqueConstraints = {
        @UniqueConstraint(name = "uq_query_senior", columnNames = {"query_id", "senior_id"})
})
public class RevealRequest {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "query_id", nullable = false)
    private Query query;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "junior_id", nullable = false)
    private User junior;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "senior_id", nullable = false)
    private User senior;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private RevealStatus status = RevealStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "resolved_at")
    private Instant resolvedAt;

    public RevealRequest() {
    }

    public RevealRequest(UUID id, Query query, User junior, User senior, RevealStatus status, Instant createdAt, Instant resolvedAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.query = query;
        this.junior = junior;
        this.senior = senior;
        this.status = status != null ? status : RevealStatus.PENDING;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.resolvedAt = resolvedAt;
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

    public void setId(UUID id) {
        this.id = id;
    }

    public Query getQuery() {
        return query;
    }

    public void setQuery(Query query) {
        this.query = query;
    }

    public User getJunior() {
        return junior;
    }

    public void setJunior(User junior) {
        this.junior = junior;
    }

    public User getSenior() {
        return senior;
    }

    public void setSenior(User senior) {
        this.senior = senior;
    }

    public RevealStatus getStatus() {
        return status;
    }

    public void setStatus(RevealStatus status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getResolvedAt() {
        return resolvedAt;
    }

    public void setResolvedAt(Instant resolvedAt) {
        this.resolvedAt = resolvedAt;
    }
}
