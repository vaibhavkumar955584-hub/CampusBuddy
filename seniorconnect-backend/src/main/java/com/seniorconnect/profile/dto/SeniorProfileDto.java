package com.seniorconnect.profile.dto;

import com.seniorconnect.profile.entity.SeniorProfile;

import java.util.UUID;

public record SeniorProfileDto(
        UUID userId,
        String fullName,
        String email,
        String branch,
        int points,
        String placementTag,
        boolean isTagVerified
) {
    public static SeniorProfileDto fromEntity(SeniorProfile profile) {
        return new SeniorProfileDto(
                profile.getUser().getId(),
                profile.getUser().getFullName(),
                profile.getUser().getEmail(),
                profile.getUser().getBranch(),
                profile.getPoints(),
                profile.getPlacementTag(),
                profile.isTagVerified()
        );
    }
}
