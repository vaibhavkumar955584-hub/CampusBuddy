package com.seniorconnect.mentorship.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record MentorshipPlanDto(
        UUID id,
        UUID juniorId,
        String juniorName,
        UUID seniorId,
        String seniorName,
        String goalTitle,
        String targetCompany,
        String targetRole,
        int durationDays,
        String status,
        int progressPercentage,
        List<PlanTaskDto> tasks,
        Instant createdAt
) {
    public record PlanTaskDto(
            UUID id,
            int weekNumber,
            String title,
            String description,
            boolean isCompleted
    ) {}
}
