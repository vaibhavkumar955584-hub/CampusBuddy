package com.seniorconnect.moderation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateReportRequest(
        @NotBlank(message = "Target type must be QUERY or RESPONSE")
        String targetType,

        @NotNull(message = "Target ID is required")
        UUID targetId,

        @NotBlank(message = "Reason is required")
        @Size(max = 1000, message = "Reason must not exceed 1000 characters")
        String reason
) {}
