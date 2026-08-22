package com.seniorconnect.auth.dto;

import java.util.List;

public record ParsedEmailDto(
        String email,
        boolean isMatched,
        Integer admissionYear,
        String batchLabel,
        String collegeCode,
        String branchCode,
        String branchName,
        Integer yearOfStudy,
        String yearLabel,
        String rollNumber,
        List<String> autoTags,
        boolean requiresManualEntry,
        String message
) {
    public static ParsedEmailDto unparsed(String email, String message) {
        return new ParsedEmailDto(
                email,
                false,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                List.of(),
                true,
                message
        );
    }
}
