package com.seniorconnect.query.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AnalyzeQueryRequest(
        @NotBlank(message = "Title is required for analysis")
        @Size(max = 200, message = "Title cannot exceed 200 characters")
        String title,

        @NotBlank(message = "Content details are required for analysis")
        @Size(max = 2000, message = "Content cannot exceed 2000 characters")
        String content
) {}
