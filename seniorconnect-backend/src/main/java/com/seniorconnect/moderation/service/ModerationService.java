package com.seniorconnect.moderation.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.common.util.SanitizerUtil;
import com.seniorconnect.moderation.dto.CreateReportRequest;
import com.seniorconnect.moderation.dto.ReportDto;
import com.seniorconnect.moderation.entity.Report;
import com.seniorconnect.moderation.repository.ReportRepository;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.Response;
import com.seniorconnect.query.repository.QueryRepository;
import com.seniorconnect.query.repository.ResponseRepository;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
public class ModerationService {

    private static final Logger log = LoggerFactory.getLogger(ModerationService.class);

    private final ReportRepository reportRepository;
    private final QueryRepository queryRepository;
    private final ResponseRepository responseRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    public ModerationService(
            ReportRepository reportRepository,
            QueryRepository queryRepository,
            ResponseRepository responseRepository,
            UserRepository userRepository,
            AuditService auditService
    ) {
        this.reportRepository = reportRepository;
        this.queryRepository = queryRepository;
        this.responseRepository = responseRepository;
        this.userRepository = userRepository;
        this.auditService = auditService;
    }

    @Transactional
    public ReportDto submitReport(CreateReportRequest request, UserPrincipal reporterPrincipal, String clientIp) {
        User reporter = userRepository.findById(reporterPrincipal.getId())
                .orElseThrow(() -> AppException.notFound("Reporter user not found", "USER_NOT_FOUND"));

        User reportedUser;
        if ("QUERY".equalsIgnoreCase(request.targetType())) {
            Query query = queryRepository.findById(request.targetId())
                    .orElseThrow(() -> AppException.notFound("Target query not found", "TARGET_NOT_FOUND"));
            reportedUser = query.getJunior();
        } else if ("RESPONSE".equalsIgnoreCase(request.targetType())) {
            Response response = responseRepository.findById(request.targetId())
                    .orElseThrow(() -> AppException.notFound("Target response not found", "TARGET_NOT_FOUND"));
            reportedUser = response.getSenior();
        } else {
            throw AppException.badRequest("Invalid target type: must be QUERY or RESPONSE", "INVALID_TARGET_TYPE");
        }

        if (reporter.getId().equals(reportedUser.getId())) {
            throw AppException.badRequest("You cannot report your own content", "INVALID_REPORT");
        }

        String cleanReason = SanitizerUtil.sanitizeText(request.reason());

        Report report = new Report(
                UUID.randomUUID(),
                reporter,
                reportedUser,
                request.targetType().toUpperCase(),
                request.targetId(),
                cleanReason,
                "PENDING",
                Instant.now()
        );
        Report saved = reportRepository.save(report);

        auditService.logEvent(
                AuditEventType.REPORT_SUBMITTED,
                reporter.getId(),
                clientIp,
                "Report submitted against user " + reportedUser.getEmail() + " for " + request.targetType()
        );

        // Auto-Soft-Suspend Trigger: 3+ reports within 7 days
        Instant sevenDaysAgo = Instant.now().minus(7, ChronoUnit.DAYS);
        long recentReportsCount = reportRepository.countReportsForUserSince(reportedUser, sevenDaysAgo);

        if (recentReportsCount >= 3 && !reportedUser.isSuspended()) {
            reportedUser.setSuspended(true);
            userRepository.save(reportedUser);
            log.warn("USER AUTO-SUSPENDED: User {} accumulated {} reports in 7 days.", reportedUser.getEmail(), recentReportsCount);
            auditService.logEvent(
                    AuditEventType.USER_SOFT_SUSPENDED,
                    reportedUser.getId(),
                    clientIp,
                    "Auto-soft-suspended due to " + recentReportsCount + " reports within 7 days"
            );
        }

        return ReportDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<ReportDto> getPendingReports(UserPrincipal adminPrincipal) {
        if (adminPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only admins can view moderation reports", "ADMIN_REQUIRED");
        }
        return reportRepository.findByStatusOrderByCreatedAtDesc("PENDING")
                .stream()
                .map(ReportDto::fromEntity)
                .toList();
    }

    @Transactional
    public void resolveReport(UUID reportId, String resolution, UserPrincipal adminPrincipal, String clientIp) {
        if (adminPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only admins can resolve moderation reports", "ADMIN_REQUIRED");
        }
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> AppException.notFound("Report not found", "REPORT_NOT_FOUND"));

        report.setStatus(resolution != null ? resolution.toUpperCase() : "RESOLVED");
        reportRepository.save(report);

        auditService.logEvent(
                AuditEventType.ADMIN_ACTION,
                adminPrincipal.getId(),
                clientIp,
                "Report " + reportId + " marked as " + report.getStatus()
        );
    }

    @Transactional
    public void setUserSuspension(UUID userId, boolean suspend, UserPrincipal adminPrincipal, String clientIp) {
        if (adminPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only admins can suspend/unsuspend users", "ADMIN_REQUIRED");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        user.setSuspended(suspend);
        userRepository.save(user);

        auditService.logEvent(
                AuditEventType.ADMIN_ACTION,
                adminPrincipal.getId(),
                clientIp,
                "Admin " + (suspend ? "SUSPENDED" : "UNSUSPENDED") + " user " + user.getEmail()
        );
    }
}
