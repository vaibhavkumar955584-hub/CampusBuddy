package com.seniorconnect.query.dto;

import com.seniorconnect.profile.dto.SeniorProfileDto;
import com.seniorconnect.query.entity.Response;

import java.time.Instant;
import java.util.UUID;

public record AnswerResponseDto(
        UUID id,
        UUID seniorId,
        String seniorName,
        String seniorBranch,
        String placementTag,
        boolean isTagVerified,
        String content,
        boolean isAcceptedAnswer,
        Instant createdAt
) {
    public static AnswerResponseDto fromEntity(Response response, SeniorProfileDto profile) {
        return new AnswerResponseDto(
                response.getId(),
                response.getSenior().getId(),
                response.getSenior().getFullName(),
                response.getSenior().getBranch(),
                profile != null ? profile.placementTag() : null,
                profile != null && profile.isTagVerified(),
                response.getContent(),
                response.isAcceptedAnswer(),
                response.getCreatedAt()
        );
    }
}
