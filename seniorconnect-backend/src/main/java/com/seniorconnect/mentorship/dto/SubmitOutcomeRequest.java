package com.seniorconnect.mentorship.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

public record SubmitOutcomeRequest(
        UUID planId,
        UUID seniorId,

        @NotBlank(message = "Outcome type is required (e.g. PLACEMENT_RECEIVED, INTERNSHIP_RECEIVED)")
        String outcomeType,

        String company,
        String role,
        String proofUrl
) {}
