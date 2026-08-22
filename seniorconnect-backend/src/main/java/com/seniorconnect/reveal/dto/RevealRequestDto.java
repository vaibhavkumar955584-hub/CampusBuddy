package com.seniorconnect.reveal.dto;

import com.seniorconnect.reveal.entity.RevealRequest;
import com.seniorconnect.reveal.entity.RevealStatus;

import java.time.Instant;
import java.util.UUID;

public record RevealRequestDto(
        UUID id,
        UUID queryId,
        String queryTitle,
        UUID seniorId,
        String seniorName,
        UUID juniorId,
        String juniorName,
        RevealStatus status,
        Instant createdAt,
        Instant resolvedAt
) {
    public static RevealRequestDto fromEntity(RevealRequest request, boolean showJuniorIdentity) {
        return new RevealRequestDto(
                request.getId(),
                request.getQuery().getId(),
                request.getQuery().getTitle(),
                request.getSenior().getId(),
                request.getSenior().getFullName(),
                showJuniorIdentity ? request.getJunior().getId() : null,
                showJuniorIdentity ? request.getJunior().getFullName() : "Anonymous Junior",
                request.getStatus(),
                request.getCreatedAt(),
                request.getResolvedAt()
        );
    }
}
