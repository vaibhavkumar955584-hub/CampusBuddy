package com.seniorconnect.mentorship.dto;

import java.util.List;
import java.util.UUID;

public record MentorAnalyticsDto(
        UUID mentorId,
        String mentorName,
        String email,
        String branch,
        String placementTag,
        boolean isTagVerified,
        int totalPoints,
        int trustScore, // 0 - 100
        double averageRating, // 1.0 - 5.0
        int totalReviews,
        int activeMenteesCount,
        int verifiedPlacementsCount,
        int totalGuidanceMessagesSent,
        List<String> earnedBadges,
        List<MentorshipReviewDto> recentReviews
) {}
