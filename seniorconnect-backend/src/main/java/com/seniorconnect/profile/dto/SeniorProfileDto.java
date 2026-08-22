package com.seniorconnect.profile.dto;

import com.seniorconnect.profile.entity.SeniorProfile;

import java.util.Collections;
import java.util.List;
import java.util.UUID;

public record SeniorProfileDto(
        UUID userId,
        String fullName,
        String email,
        String branch,
        int points,
        String placementTag,
        List<String> tags,
        List<String> badges,
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
                profile.getTags() != null ? profile.getTags() : Collections.emptyList(),
                profile.getBadges() != null ? profile.getBadges() : Collections.emptyList(),
                profile.isTagVerified()
        );
    }
}
