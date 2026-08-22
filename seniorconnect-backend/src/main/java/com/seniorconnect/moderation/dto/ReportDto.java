package com.seniorconnect.moderation.dto;

import com.seniorconnect.moderation.entity.Report;

import java.time.Instant;
import java.util.UUID;

public record ReportDto(
        UUID id,
        UUID reporterId,
        UUID reportedUserId,
        String reportedUserEmail,
        String targetType,
        UUID targetId,
        String reason,
        String status,
        Instant createdAt
) {
    public static ReportDto fromEntity(Report report) {
        return new ReportDto(
                report.getId(),
                report.getReporter().getId(),
                report.getReportedUser().getId(),
                report.getReportedUser().getEmail(),
                report.getTargetType(),
                report.getTargetId(),
                report.getReason(),
                report.getStatus(),
                report.getCreatedAt()
        );
    }
}
