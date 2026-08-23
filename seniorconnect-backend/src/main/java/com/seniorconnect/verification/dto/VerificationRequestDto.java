package com.seniorconnect.verification.dto;

import com.seniorconnect.verification.entity.VerificationRequest;
import com.seniorconnect.verification.entity.VerificationStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * User-facing DTO.
 * CRITICAL RULE: OCR extracted text and confidence scores are NOT exposed to the submitting user.
 */
public record VerificationRequestDto(
        UUID id,
        UUID seniorId,
        String claimedTag,
        VerificationStatus status,
        String rejectionReason,
        Instant createdAt,
        Instant reviewedAt
) {
    public static VerificationRequestDto fromEntity(VerificationRequest entity) {
        return new VerificationRequestDto(
                entity.getId(),
                entity.getSenior().getId(),
                entity.getClaimedTag(),
                entity.getStatus(),
                entity.getRejectionReason(),
                entity.getCreatedAt(),
                entity.getReviewedAt()
        );
    }
}
