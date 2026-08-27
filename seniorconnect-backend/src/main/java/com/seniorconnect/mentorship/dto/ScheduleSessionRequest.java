package com.seniorconnect.mentorship.dto;

import java.time.Instant;

public record ScheduleSessionRequest(
        Instant scheduledAt,
        String meetingLink,
        String sessionNotes
) {}
