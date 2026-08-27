package com.seniorconnect.query.dto;

import java.util.List;
import java.util.UUID;

public record QueryAnalysisDto(
        String intent,
        String domain,
        List<String> skills,
        String targetCompany,
        String targetRole,
        Integer timelineDays,
        String urgency,
        String experienceLevel,
        List<SimilarQuestionDto> similarQuestions,
        List<RecommendedMentorDto> recommendedMentors
) {
    public record SimilarQuestionDto(
            UUID id,
            String title,
            double similarityScore,
            int responsesCount,
            String answeredBy
    ) {}

    public record RecommendedMentorDto(
            UUID mentorId,
            String mentorName,
            String currentCompany,
            String branch,
            int matchPercentage,
            int studentsHelped,
            List<String> matchedSkills,
            boolean isVerified
    ) {}
}
