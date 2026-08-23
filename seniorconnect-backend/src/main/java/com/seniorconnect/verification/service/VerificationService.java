package com.seniorconnect.verification.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.gamification.service.BadgeService;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.profile.service.SeniorProfileService;
import com.seniorconnect.ratelimit.RateLimiterService;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import com.seniorconnect.verification.dto.AdminVerificationRequestDto;
import com.seniorconnect.verification.dto.VerificationRequestDto;
import com.seniorconnect.verification.entity.VerificationRequest;
import com.seniorconnect.verification.entity.VerificationStatus;
import com.seniorconnect.verification.repository.VerificationRequestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class VerificationService {

    private static final Logger log = LoggerFactory.getLogger(VerificationService.class);

    private final VerificationRequestRepository verificationRequestRepository;
    private final UserRepository userRepository;
    private final SeniorProfileRepository seniorProfileRepository;
    private final SeniorProfileService seniorProfileService;
    private final ProofStorageService proofStorageService;
    private final ProofOcrService proofOcrService;
    private final VerificationKeywordConfig verificationKeywordConfig;
    private final RateLimiterService rateLimiterService;
    private final AuditService auditService;
    private final BadgeService badgeService;

    public VerificationService(
            VerificationRequestRepository verificationRequestRepository,
            UserRepository userRepository,
            SeniorProfileRepository seniorProfileRepository,
            SeniorProfileService seniorProfileService,
            ProofStorageService proofStorageService,
            ProofOcrService proofOcrService,
            VerificationKeywordConfig verificationKeywordConfig,
            RateLimiterService rateLimiterService,
            AuditService auditService,
            BadgeService badgeService
    ) {
        this.verificationRequestRepository = verificationRequestRepository;
        this.userRepository = userRepository;
        this.seniorProfileRepository = seniorProfileRepository;
        this.seniorProfileService = seniorProfileService;
        this.proofStorageService = proofStorageService;
        this.proofOcrService = proofOcrService;
        this.verificationKeywordConfig = verificationKeywordConfig;
        this.rateLimiterService = rateLimiterService;
        this.auditService = auditService;
        this.badgeService = badgeService;
    }

    /**
     * Submits proof for a claimed achievement tag.
     * Enforces IDOR protection: User can only submit proof for their own profile.
     * Rate limited to 5 submissions per 24 hours per user.
     */
    @Transactional
    public VerificationRequestDto submitProof(
            UserPrincipal principal,
            String claimedTag,
            MultipartFile file,
            String clientIp
    ) {
        if (principal == null) {
            throw AppException.unauthorized("Authentication required", "UNAUTHORIZED");
        }
        if (claimedTag == null || claimedTag.isBlank()) {
            throw AppException.badRequest("Claimed tag is required", "INVALID_TAG");
        }
        if (file == null || file.isEmpty()) {
            throw AppException.badRequest("Proof file is required", "EMPTY_FILE");
        }

        User senior = userRepository.findById(principal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        // Rate limit: 5 proof uploads per 24 hours (86400s)
        String rateLimitKey = "verification:proof:" + senior.getId();
        if (!rateLimiterService.tryAcquire(rateLimitKey, 5, 86400)) {
            throw AppException.tooManyRequests("You have reached the daily proof upload limit (5 per day). Please try again tomorrow.", "RATE_LIMIT_EXCEEDED");
        }

        byte[] rawBytes;
        try {
            rawBytes = file.getBytes();
        } catch (Exception e) {
            throw AppException.badRequest("Could not read uploaded file", "INVALID_FILE");
        }

        // 1. Content inspection & metadata stripping storage
        String storageKey = proofStorageService.storeProofFile(rawBytes, file.getOriginalFilename());

        // 2. OCR text extraction with timeout & graceful fallback
        ProofOcrService.OcrResult ocrResult = proofOcrService.extractText(rawBytes);

        // 3. Keyword matching evaluation
        Boolean keywordMatch = null;
        if (ocrResult.success() && ocrResult.text() != null && !ocrResult.text().isBlank()) {
            keywordMatch = verificationKeywordConfig.evaluateKeywordMatch(claimedTag, ocrResult.text());
        }

        // 4. Save verification request in PENDING status
        VerificationRequest request = new VerificationRequest(
                UUID.randomUUID(),
                senior,
                claimedTag.trim(),
                storageKey,
                ocrResult.text(),
                keywordMatch,
                ocrResult.confidenceScore(),
                VerificationStatus.PENDING,
                Instant.now()
        );

        VerificationRequest saved = verificationRequestRepository.save(request);

        auditService.logEvent(
                AuditEventType.ADMIN_ACTION,
                senior.getId(),
                clientIp,
                "Proof submitted for tag '" + claimedTag + "' [ocrMatch=" + keywordMatch + "]"
        );

        return VerificationRequestDto.fromEntity(saved);
    }

    /**
     * Admin review queue: Retrieves pending verification requests sorted with OCR-matched items at the top.
     */
    @Transactional(readOnly = true)
    public Page<AdminVerificationRequestDto> getPendingRequestsForAdmin(VerificationStatus status, Pageable pageable) {
        Page<VerificationRequest> page = verificationRequestRepository.findByStatusWithTriageSorting(status, pageable);
        return page.map(req -> {
            String signedUrl = proofStorageService.generateSignedUrl(req.getProofFileUrl());
            return AdminVerificationRequestDto.fromEntity(req, signedUrl);
        });
    }

    /**
     * Admin approval: The ONLY valid path in the system to verify an achievement tag.
     */
    @Transactional
    public AdminVerificationRequestDto approveVerification(
            UUID requestId,
            UserPrincipal adminPrincipal,
            String clientIp
    ) {
        if (adminPrincipal == null || adminPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only administrators can approve verification requests", "ADMIN_REQUIRED");
        }

        VerificationRequest request = verificationRequestRepository.findById(requestId)
                .orElseThrow(() -> AppException.notFound("Verification request not found", "REQUEST_NOT_FOUND"));

        User adminUser = userRepository.findById(adminPrincipal.getId())
                .orElseThrow(() -> AppException.notFound("Admin not found", "ADMIN_NOT_FOUND"));

        request.setStatus(VerificationStatus.APPROVED);
        request.setReviewedBy(adminUser);
        request.setReviewedAt(Instant.now());
        request.setRejectionReason(null);

        // Update SeniorProfile tag verification
        SeniorProfile profile = seniorProfileService.getOrCreateProfile(request.getSenior());
        profile.setTagVerified(true);
        profile.setPlacementTag(request.getClaimedTag());
        badgeService.evaluateAndAwardBadges(profile);
        seniorProfileRepository.save(profile);

        VerificationRequest saved = verificationRequestRepository.save(request);

        auditService.logEvent(
                AuditEventType.TAG_VERIFIED,
                adminPrincipal.getId(),
                clientIp,
                "Admin approved verification request " + requestId + " for user " + request.getSenior().getEmail()
        );

        String signedUrl = proofStorageService.generateSignedUrl(saved.getProofFileUrl());
        return AdminVerificationRequestDto.fromEntity(saved, signedUrl);
    }

    /**
     * Admin rejection with mandatory rejection reason.
     */
    @Transactional
    public AdminVerificationRequestDto rejectVerification(
            UUID requestId,
            String rejectionReason,
            UserPrincipal adminPrincipal,
            String clientIp
    ) {
        if (adminPrincipal == null || adminPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only administrators can reject verification requests", "ADMIN_REQUIRED");
        }
        if (rejectionReason == null || rejectionReason.isBlank()) {
            throw AppException.badRequest("Rejection reason is mandatory when rejecting verification proof", "REASON_REQUIRED");
        }

        VerificationRequest request = verificationRequestRepository.findById(requestId)
                .orElseThrow(() -> AppException.notFound("Verification request not found", "REQUEST_NOT_FOUND"));

        User adminUser = userRepository.findById(adminPrincipal.getId())
                .orElseThrow(() -> AppException.notFound("Admin not found", "ADMIN_NOT_FOUND"));

        request.setStatus(VerificationStatus.REJECTED);
        request.setReviewedBy(adminUser);
        request.setReviewedAt(Instant.now());
        request.setRejectionReason(rejectionReason.trim());

        // Ensure isTagVerified is false
        SeniorProfile profile = seniorProfileService.getOrCreateProfile(request.getSenior());
        profile.setTagVerified(false);
        seniorProfileRepository.save(profile);

        VerificationRequest saved = verificationRequestRepository.save(request);

        auditService.logEvent(
                AuditEventType.ADMIN_ACTION,
                adminPrincipal.getId(),
                clientIp,
                "Admin rejected verification request " + requestId + ". Reason: " + rejectionReason
        );

        String signedUrl = proofStorageService.generateSignedUrl(saved.getProofFileUrl());
        return AdminVerificationRequestDto.fromEntity(saved, signedUrl);
    }

    /**
     * Retrieves verification requests submitted by the current authenticated senior.
     */
    @Transactional(readOnly = true)
    public List<VerificationRequestDto> getMyVerificationRequests(UserPrincipal principal) {
        if (principal == null) {
            throw AppException.unauthorized("Authentication required", "UNAUTHORIZED");
        }
        return verificationRequestRepository.findBySeniorIdOrderByCreatedAtDesc(principal.getId())
                .stream()
                .map(VerificationRequestDto::fromEntity)
                .toList();
    }
}
