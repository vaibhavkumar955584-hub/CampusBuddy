package com.seniorconnect.moderation.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "reports")
public class Report {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reporter_id", nullable = false)
    private User reporter;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reported_user_id", nullable = false)
    private User reportedUser;

    @Column(name = "target_type", nullable = false, length = 32)
    private String targetType; // QUERY or RESPONSE

    @Column(name = "target_id", nullable = false)
    private UUID targetId;

    @Column(name = "reason", nullable = false, length = 1000)
    private String reason;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "PENDING"; // PENDING, RESOLVED, DISMISSED

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public Report() {
    }

    public Report(UUID id, User reporter, User reportedUser, String targetType, UUID targetId, String reason, String status, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.reporter = reporter;
        this.reportedUser = reportedUser;
        this.targetType = targetType;
        this.targetId = targetId;
        this.reason = reason;
        this.status = status != null ? status : "PENDING";
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

    public User getReporter() {
        return reporter;
    }

    public User getReportedUser() {
        return reportedUser;
    }

    public String getTargetType() {
        return targetType;
    }

    public UUID getTargetId() {
        return targetId;
    }

    public String getReason() {
        return reason;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
