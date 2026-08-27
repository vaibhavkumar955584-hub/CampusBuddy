package com.seniorconnect.mentorship.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;

public record SendMessageRequest(
        @NotBlank(message = "Message cannot be blank")
        @Size(max = 4000)
        String messageContent
) {}
