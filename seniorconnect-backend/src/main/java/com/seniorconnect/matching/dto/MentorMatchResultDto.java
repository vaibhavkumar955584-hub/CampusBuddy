package com.seniorconnect.matching.dto;

import java.util.List;
import java.util.UUID;

public record MentorMatchResultDto(
        UUID mentorId,
        String mentorName,
        String email,
        String branch,
        String placementTag,
        boolean isTagVerified,
        int totalPoints,
        int matchPercentage,
        List<String> matchedSkills,
        boolean companyMatched,
        String matchHeadline
) {}
