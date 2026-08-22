package com.seniorconnect.moderation.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.moderation.dto.CreateReportRequest;
import com.seniorconnect.moderation.dto.ReportDto;
import com.seniorconnect.moderation.service.ModerationService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/moderation")
public class ModerationController {

    private final ModerationService moderationService;

    public ModerationController(ModerationService moderationService) {
        this.moderationService = moderationService;
    }

    @PostMapping("/reports")
    public ResponseEntity<ReportDto> submitReport(
            @Valid @RequestBody CreateReportRequest request,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        ReportDto report = moderationService.submitReport(request, principal, clientIp);
        return ResponseEntity.status(HttpStatus.CREATED).body(report);
    }

    @GetMapping("/reports")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<ReportDto>> getPendingReports(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(moderationService.getPendingReports(principal));
    }

    @PostMapping("/reports/{reportId}/resolve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> resolveReport(
            @PathVariable UUID reportId,
            @RequestParam(defaultValue = "RESOLVED") String resolution,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        moderationService.resolveReport(reportId, resolution, principal, clientIp);
        return ResponseEntity.ok(Map.of("message", "Report marked as " + resolution));
    }

    @PostMapping("/users/{userId}/suspension")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> setSuspension(
            @PathVariable UUID userId,
            @RequestParam boolean suspend,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        moderationService.setUserSuspension(userId, suspend, principal, clientIp);
        return ResponseEntity.ok(Map.of("message", "User suspension status updated to " + suspend));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
