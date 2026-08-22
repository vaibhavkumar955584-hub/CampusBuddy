package com.seniorconnect.query.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateQueryRequest(
        @NotBlank(message = "Title is required")
        @Size(max = 300, message = "Title must not exceed 300 characters")
        String title,

        @NotBlank(message = "Content is required")
        @Size(max = 5000, message = "Content must not exceed 5000 characters")
        String content,

        @Size(max = 500, message = "Tags must not exceed 500 characters")
        String tags,

        boolean isAnonymousDisplay
) {
    public CreateQueryRequest {
        if (title == null) title = "";
    }
}
