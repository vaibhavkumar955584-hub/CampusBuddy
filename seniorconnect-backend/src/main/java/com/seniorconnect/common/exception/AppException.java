package com.seniorconnect.common.exception;

import org.springframework.http.HttpStatus;

public class AppException extends RuntimeException {
    private final HttpStatus status;
    private final String errorCode;

    public AppException(String message, HttpStatus status, String errorCode) {
        super(message);
        this.status = status;
        this.errorCode = errorCode;
    }

    public static AppException badRequest(String message, String errorCode) {
        return new AppException(message, HttpStatus.BAD_REQUEST, errorCode);
    }

    public static AppException unauthorized(String message, String errorCode) {
        return new AppException(message, HttpStatus.UNAUTHORIZED, errorCode);
    }

    public static AppException forbidden(String message, String errorCode) {
        return new AppException(message, HttpStatus.FORBIDDEN, errorCode);
    }

    public static AppException notFound(String message, String errorCode) {
        return new AppException(message, HttpStatus.NOT_FOUND, errorCode);
    }

    public static AppException tooManyRequests(String message, String errorCode) {
        return new AppException(message, HttpStatus.TOO_MANY_REQUESTS, errorCode);
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getErrorCode() {
        return errorCode;
    }
}
