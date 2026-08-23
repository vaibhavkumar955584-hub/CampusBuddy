package com.seniorconnect.verification.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.verification.dto.VerificationRequestDto;
import com.seniorconnect.verification.service.VerificationService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/profiles/verification")
public class ProofVerificationController {

    private final VerificationService verificationService;

    public ProofVerificationController(VerificationService verificationService) {
        this.verificationService = verificationService;
    }

    @PostMapping("/proof")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<VerificationRequestDto> uploadProof(
            @RequestParam("claimedTag") String claimedTag,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request
    ) {
        String clientIp = extractClientIp(request);
        VerificationRequestDto dto = verificationService.submitProof(principal, claimedTag, file, clientIp);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/my-requests")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<VerificationRequestDto>> getMyRequests(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(verificationService.getMyVerificationRequests(principal));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
