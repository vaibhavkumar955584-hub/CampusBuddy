package com.seniorconnect.mentorship.dto;

import java.time.Instant;
import java.util.UUID;

public record MentorshipSessionDto(
        UUID id,
        UUID juniorId,
        String juniorName,
        String juniorEmail,
        String juniorBranch,
        UUID seniorId,
        String seniorName,
        String seniorEmail,
        String seniorBranch,
        String seniorPlacementTag,
        UUID queryId,
        String queryTitle,
        UUID planId,
        String status,
        int privacyLevel,
        String meetingLink,
        String sessionNotes,
        Instant scheduledAt,
        Instant createdAt
) {}
