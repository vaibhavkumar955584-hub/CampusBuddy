package com.seniorconnect.reveal.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.reveal.dto.RevealRequestDto;
import com.seniorconnect.reveal.service.RevealService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/reveals")
public class RevealController {

    private final RevealService revealService;

    public RevealController(RevealService revealService) {
        this.revealService = revealService;
    }

    @PostMapping("/query/{queryId}/request")
    @PreAuthorize("hasAnyRole('SENIOR', 'ADMIN')")
    public ResponseEntity<RevealRequestDto> requestReveal(
            @PathVariable UUID queryId,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        RevealRequestDto dto = revealService.requestReveal(queryId, principal, clientIp);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    @PostMapping("/{revealRequestId}/respond")
    public ResponseEntity<RevealRequestDto> respondToReveal(
            @PathVariable UUID revealRequestId,
            @RequestParam boolean accept,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        RevealRequestDto dto = revealService.respondToReveal(revealRequestId, accept, principal, clientIp);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/pending")
    public ResponseEntity<List<RevealRequestDto>> getPendingReveals(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(revealService.getPendingRevealsForJunior(principal));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
