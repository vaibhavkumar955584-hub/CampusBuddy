package com.seniorconnect.auth.dto;

import com.seniorconnect.user.model.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record DirectLoginRequest(
        @NotBlank(message = "Email cannot be empty")
        @Email(message = "Invalid email format")
        String email,

        String fullName,
        String branch,
        Integer semester,
        Role role,
        String deviceFingerprint
) {}
