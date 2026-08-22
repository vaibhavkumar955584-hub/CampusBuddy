package com.seniorconnect.auth.dto;

import com.seniorconnect.user.model.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record SendOtpRequest(
        @NotBlank(message = "College email is required")
        @Email(message = "Must be a valid email address")
        String email,

        @NotNull(message = "Role must be specified (JUNIOR or SENIOR)")
        Role role,

        @Size(max = 100, message = "Full name must not exceed 100 characters")
        String fullName,

        String branch,
        Integer semester
) {}
