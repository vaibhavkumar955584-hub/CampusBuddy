package com.seniorconnect.mentorship.dto;

import java.time.Instant;
import java.util.UUID;

public record SessionMessageDto(
        UUID id,
        UUID sessionId,
        UUID senderId,
        String senderName,
        String messageContent,
        boolean isEncrypted,
        Instant createdAt
) {}
