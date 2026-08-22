package com.seniorconnect.audit.entity;

import com.seniorconnect.audit.model.AuditEventType;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
public class AuditLog {

    @Id
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 64)
    private AuditEventType eventType;

    @Column(name = "actor_id")
    private UUID actorId;

    @Column(name = "ip_address", length = 128)
    private String ipAddress;

    @Column(name = "details", length = 2000)
    private String details;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public AuditLog() {
    }

    public AuditLog(UUID id, AuditEventType eventType, UUID actorId, String ipAddress, String details, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.eventType = eventType;
        this.actorId = actorId;
        this.ipAddress = ipAddress;
        this.details = details;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static AuditLog of(AuditEventType eventType, UUID actorId, String ipAddress, String details) {
        return new AuditLog(UUID.randomUUID(), eventType, actorId, ipAddress, details, Instant.now());
    }

    public UUID getId() {
        return id;
    }

    public AuditEventType getEventType() {
        return eventType;
    }

    public UUID getActorId() {
        return actorId;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public String getDetails() {
        return details;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
