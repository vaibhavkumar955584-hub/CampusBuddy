package com.seniorconnect.mentorship.dto;

public record CampusMentorshipOverviewDto(
        long totalRoadmapsCreated,
        long totalActiveSessions,
        long totalVerifiedOutcomes,
        double campusSuccessRatePercentage,
        long totalMentorsActive,
        int averageGoalCompletionDays
) {}
