package com.seniorconnect.common.exception;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(
        String message,
        String errorCode,
        int status,
        Instant timestamp,
        Map<String, String> fieldErrors
) {
    public static ErrorResponse of(String message, String errorCode, int status) {
        return new ErrorResponse(message, errorCode, status, Instant.now(), null);
    }

    public static ErrorResponse of(String message, String errorCode, int status, Map<String, String> fieldErrors) {
        return new ErrorResponse(message, errorCode, status, Instant.now(), fieldErrors);
    }
}
