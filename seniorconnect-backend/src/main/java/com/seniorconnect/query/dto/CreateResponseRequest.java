package com.seniorconnect.query.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateResponseRequest(
        @NotBlank(message = "Response content cannot be blank")
        @Size(max = 5000, message = "Response content must not exceed 5000 characters")
        String content
) {}
