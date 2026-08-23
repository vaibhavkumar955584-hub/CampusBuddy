package com.seniorconnect.verification.dto;

import com.seniorconnect.verification.entity.VerificationRequest;
import com.seniorconnect.verification.entity.VerificationStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * Admin-facing DTO with full OCR triage context and short-lived signed URL for manual verification.
 */
public record AdminVerificationRequestDto(
        UUID id,
        UUID seniorId,
        String seniorEmail,
        String seniorName,
        String seniorBranch,
        String claimedTag,
        String proofSignedUrl,
        String ocrExtractedText,
        Boolean ocrKeywordMatch,
        Double ocrConfidenceScore,
        String triageFlag, // "AI-flagged: likely valid" vs "AI-flagged: needs closer look"
        VerificationStatus status,
        UUID reviewedBy,
        Instant reviewedAt,
        String rejectionReason,
        Instant createdAt
) {
    public static AdminVerificationRequestDto fromEntity(VerificationRequest entity, String proofSignedUrl) {
        String triage = (Boolean.TRUE.equals(entity.getOcrKeywordMatch()))
                ? "AI-flagged: likely valid"
                : "AI-flagged: needs closer look";

        return new AdminVerificationRequestDto(
                entity.getId(),
                entity.getSenior().getId(),
                entity.getSenior().getEmail(),
                entity.getSenior().getFullName(),
                entity.getSenior().getBranch(),
                entity.getClaimedTag(),
                proofSignedUrl,
                entity.getOcrExtractedText(),
                entity.getOcrKeywordMatch(),
                entity.getOcrConfidenceScore(),
                triage,
                entity.getStatus(),
                entity.getReviewedBy() != null ? entity.getReviewedBy().getId() : null,
                entity.getReviewedAt(),
                entity.getRejectionReason(),
                entity.getCreatedAt()
        );
    }
}
