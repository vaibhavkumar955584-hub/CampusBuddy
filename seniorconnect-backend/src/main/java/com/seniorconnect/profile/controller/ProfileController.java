package com.seniorconnect.profile.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.profile.dto.SeniorProfileDto;
import com.seniorconnect.profile.service.SeniorProfileService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/profiles")
public class ProfileController {

    private final SeniorProfileService seniorProfileService;

    public ProfileController(SeniorProfileService seniorProfileService) {
        this.seniorProfileService = seniorProfileService;
    }

    @GetMapping("/{userId}")
    public ResponseEntity<SeniorProfileDto> getProfile(@PathVariable UUID userId) {
        return ResponseEntity.ok(seniorProfileService.getProfile(userId));
    }

    @PutMapping("/placement-tag")
    @PreAuthorize("hasAnyRole('SENIOR', 'ADMIN')")
    public ResponseEntity<SeniorProfileDto> updatePlacementTag(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        String tag = body.get("placementTag");
        return ResponseEntity.ok(seniorProfileService.updatePlacementTag(principal, tag));
    }

    @PostMapping("/verify-tag/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SeniorProfileDto> verifyTag(
            @PathVariable UUID userId,
            @RequestParam boolean isVerified,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        return ResponseEntity.ok(seniorProfileService.verifyTagByAdmin(userId, isVerified, principal, clientIp));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
