package com.seniorconnect.query.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.query.dto.AnswerResponseDto;
import com.seniorconnect.query.dto.CreateResponseRequest;
import com.seniorconnect.query.service.ResponseService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/queries/{queryId}/responses")
public class ResponseController {

    private final ResponseService responseService;

    public ResponseController(ResponseService responseService) {
        this.responseService = responseService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('SENIOR', 'ADMIN')")
    public ResponseEntity<AnswerResponseDto> postResponse(
            @PathVariable UUID queryId,
            @Valid @RequestBody CreateResponseRequest request,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        AnswerResponseDto response = responseService.postResponse(queryId, request, principal, clientIp);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/{responseId}/accept")
    public ResponseEntity<AnswerResponseDto> acceptAnswer(
            @PathVariable UUID queryId,
            @PathVariable UUID responseId,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        AnswerResponseDto response = responseService.acceptAnswer(queryId, responseId, principal, clientIp);
        return ResponseEntity.ok(response);
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
