package com.seniorconnect.auth.dto;

import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;

import java.util.UUID;

public record UserDto(
        UUID id,
        String email,
        String fullName,
        Role role,
        String branch,
        Integer semester,
        Integer currentYearOfStudy,
        boolean mentorEligible,
        boolean mentorModeActive,
        Integer admissionYear,
        boolean isSuspended
) {
    public static UserDto fromUser(User user) {
        return new UserDto(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole(),
                user.getBranch(),
                user.getSemester(),
                user.getCurrentYearOfStudy(),
                user.isMentorEligible(),
                user.isMentorModeActive(),
                user.getAdmissionYear(),
                user.isSuspended()
        );
    }
}
