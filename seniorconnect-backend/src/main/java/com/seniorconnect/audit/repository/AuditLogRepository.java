package com.seniorconnect.audit.repository;

import com.seniorconnect.audit.entity.AuditLog;
import com.seniorconnect.audit.model.AuditEventType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {
    List<AuditLog> findByActorIdOrderByCreatedAtDesc(UUID actorId);
    List<AuditLog> findByEventTypeOrderByCreatedAtDesc(AuditEventType eventType);
}
