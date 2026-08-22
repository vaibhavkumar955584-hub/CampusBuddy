package com.seniorconnect.audit.service;

import com.seniorconnect.audit.entity.AuditLog;
import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.repository.AuditLogRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuditService {

    private static final Logger log = LoggerFactory.getLogger(AuditService.class);
    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    /**
     * Persists an immutable audit log entry in a dedicated transaction so that
     * audit trails are preserved.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void logEvent(AuditEventType eventType, UUID actorId, String ipAddress, String details) {
        try {
            AuditLog auditLog = AuditLog.of(eventType, actorId, ipAddress, details);
            auditLogRepository.save(auditLog);
            log.info("AUDIT [{}] actor={} ip={} details={}", eventType, actorId, ipAddress, details);
        } catch (Exception e) {
            log.error("CRITICAL: Failed to write audit log [{}]: {}", eventType, e.getMessage(), e);
        }
    }
}
