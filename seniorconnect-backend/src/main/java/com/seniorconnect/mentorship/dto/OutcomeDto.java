package com.seniorconnect.mentorship.dto;

import java.time.Instant;
import java.util.UUID;

public record OutcomeDto(
        UUID id,
        UUID planId,
        UUID juniorId,
        String juniorName,
        UUID seniorId,
        String seniorName,
        String outcomeType,
        String company,
        String role,
        boolean isVerified,
        String proofUrl,
        Instant createdAt
) {}
