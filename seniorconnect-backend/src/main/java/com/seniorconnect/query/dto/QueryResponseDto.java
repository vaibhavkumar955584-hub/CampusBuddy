package com.seniorconnect.query.dto;

import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.QueryStatus;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record QueryResponseDto(
        UUID id,
        String title,
        String content,
        String tags,
        boolean isAnonymousDisplay,
        UUID juniorId,
        String juniorName,
        String juniorBranch,
        Integer juniorSemester,
        boolean identityRevealedToViewer,
        QueryStatus status,
        int responsesCount,
        List<AnswerResponseDto> responses,
        Instant createdAt
) {
    public static QueryResponseDto fromEntity(
            Query query,
            boolean isIdentityRevealed,
            boolean isAuthorOrAdmin,
            List<AnswerResponseDto> responses
    ) {
        boolean showFullIdentity = !query.isAnonymousDisplay() || isAuthorOrAdmin || isIdentityRevealed;

        return new QueryResponseDto(
                query.getId(),
                query.getTitle(),
                query.getContent(),
                query.getTags(),
                query.isAnonymousDisplay(),
                showFullIdentity ? query.getJunior().getId() : null,
                showFullIdentity ? query.getJunior().getFullName() : "Anonymous Junior",
                showFullIdentity ? query.getJunior().getBranch() : generalizeBranch(query.getJunior().getBranch()),
                showFullIdentity ? query.getJunior().getSemester() : null,
                isIdentityRevealed,
                query.getStatus(),
                responses != null ? responses.size() : 0,
                responses,
                query.getCreatedAt()
        );
    }

    /**
     * Mitigates metadata leakage by providing broad category buckets rather than pinpoint identifiers
     */
    private static String generalizeBranch(String branch) {
        if (branch == null) return "Engineering";
        String lower = branch.toLowerCase();
        if (lower.contains("cs") || lower.contains("comp") || lower.contains("it") || lower.contains("ai")) {
            return "Computing / Tech";
        } else if (lower.contains("ec") || lower.contains("ee") || lower.contains("electrical")) {
            return "Electronics / Electrical";
        } else if (lower.contains("mech") || lower.contains("civil")) {
            return "Core Engineering";
        }
        return "General";
    }
}
