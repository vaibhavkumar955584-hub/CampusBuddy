package com.seniorconnect.verification.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.verification.dto.AdminVerificationRequestDto;
import com.seniorconnect.verification.entity.VerificationStatus;
import com.seniorconnect.verification.service.ProofStorageService;
import com.seniorconnect.verification.service.VerificationService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/admin/verification-requests")
public class AdminVerificationController {

    private final VerificationService verificationService;
    private final ProofStorageService proofStorageService;

    public AdminVerificationController(VerificationService verificationService, ProofStorageService proofStorageService) {
        this.verificationService = verificationService;
        this.proofStorageService = proofStorageService;
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<AdminVerificationRequestDto>> listRequests(
            @RequestParam(value = "status", required = false) VerificationStatus status,
            @PageableDefault(size = 20) Pageable pageable
    ) {
        return ResponseEntity.ok(verificationService.getPendingRequestsForAdmin(status, pageable));
    }

    @PostMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminVerificationRequestDto> approveRequest(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal adminPrincipal,
            HttpServletRequest request
    ) {
        String clientIp = extractClientIp(request);
        return ResponseEntity.ok(verificationService.approveVerification(id, adminPrincipal, clientIp));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminVerificationRequestDto> rejectRequest(
            @PathVariable UUID id,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserPrincipal adminPrincipal,
            HttpServletRequest request
    ) {
        String reason = body != null ? body.get("rejectionReason") : null;
        String clientIp = extractClientIp(request);
        return ResponseEntity.ok(verificationService.rejectVerification(id, reason, adminPrincipal, clientIp));
    }

    @GetMapping("/proof-view/{filename}")
    public ResponseEntity<byte[]> viewProofFile(
            @PathVariable String filename,
            @RequestParam("token") String token
    ) {
        byte[] data = proofStorageService.loadProofFile(filename, token);
        MediaType mediaType = filename.endsWith(".png") ? MediaType.IMAGE_PNG :
                filename.endsWith(".pdf") ? MediaType.APPLICATION_PDF : MediaType.IMAGE_JPEG;

        return ResponseEntity.ok()
                .contentType(mediaType)
                .header(HttpHeaders.CACHE_CONTROL, "no-store, max-age=0")
                .body(data);
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
