package com.seniorconnect.mentorship.dto;

import java.time.Instant;
import java.util.UUID;

public record MentorshipReviewDto(
        UUID id,
        UUID sessionId,
        UUID juniorId,
        String juniorName,
        UUID seniorId,
        String seniorName,
        int rating,
        String reviewComment,
        Instant createdAt
) {}
