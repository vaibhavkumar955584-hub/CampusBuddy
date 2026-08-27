package com.seniorconnect.mentorship.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record CreatePlanRequest(
        @NotBlank(message = "Goal title is required")
        @Size(max = 200)
        String goalTitle,

        String targetCompany,
        String targetRole,
        Integer durationDays,
        UUID seniorId
) {}
