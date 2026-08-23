package com.seniorconnect.auth.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.auth.dto.*;
import com.seniorconnect.auth.entity.RefreshToken;
import com.seniorconnect.auth.repository.RefreshTokenRepository;
import com.seniorconnect.auth.security.JwtService;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final OtpService otpService;
    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final AuditService auditService;
    private final EmailParserService emailParserService;
    private final com.seniorconnect.user.service.YearOfStudyService yearOfStudyService;
    private final long refreshTokenExpirationSeconds;
    private final long accessTokenExpirationSeconds;

    public AuthService(
            OtpService otpService,
            UserRepository userRepository,
            RefreshTokenRepository refreshTokenRepository,
            JwtService jwtService,
            AuditService auditService,
            EmailParserService emailParserService,
            com.seniorconnect.user.service.YearOfStudyService yearOfStudyService,
            @Value("${seniorconnect.security.jwt.refresh-token-expiration-seconds:2592000}") long refreshTokenExpirationSeconds,
            @Value("${seniorconnect.security.jwt.access-token-expiration-seconds:900}") long accessTokenExpirationSeconds
    ) {
        this.otpService = otpService;
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtService = jwtService;
        this.auditService = auditService;
        this.emailParserService = emailParserService;
        this.yearOfStudyService = yearOfStudyService;
        this.refreshTokenExpirationSeconds = refreshTokenExpirationSeconds;
        this.accessTokenExpirationSeconds = accessTokenExpirationSeconds;
    }

    public void sendOtp(SendOtpRequest request, String clientIp) {
        otpService.generateAndSaveOtp(request.email(), clientIp);
    }

    @Transactional
    public AuthResponse verifyOtpAndLogin(VerifyOtpRequest request, Role requestedRole, String fullName, String branch, Integer semester, String clientIp) {
        boolean valid = otpService.verifyOtp(request.email(), request.otp(), clientIp);
        if (!valid) {
            throw AppException.badRequest("Invalid OTP code", "INVALID_OTP");
        }

        String normEmail = request.email().toLowerCase();
        User user = userRepository.findByEmail(normEmail).orElseGet(() -> {
            Role role = requestedRole != null ? requestedRole : Role.JUNIOR;
            String name = fullName != null && !fullName.isBlank() ? fullName : normEmail.split("@")[0];

            Integer admissionYear = null;
            Integer currentYearOfStudy = null;
            try {
                ParsedEmailDto parsed = emailParserService.parseCollegeEmail(normEmail);
                if (parsed != null && parsed.isMatched()) {
                    admissionYear = parsed.admissionYear();
                    currentYearOfStudy = parsed.yearOfStudy();
                }
            } catch (Exception ignored) {
            }

            User newUser = new User(
                    UUID.randomUUID(),
                    normEmail,
                    name,
                    role,
                    branch,
                    semester,
                    currentYearOfStudy,
                    false,
                    false,
                    admissionYear,
                    false,
                    Instant.now(),
                    null
            );
            return userRepository.save(newUser);
        });

        if (user.isSuspended()) {
            throw AppException.forbidden("Your account is currently suspended pending review", "ACCOUNT_SUSPENDED");
        }

        // Run self-healing year-of-study and mentor-eligibility recalculation on every successful login
        yearOfStudyService.recalculate(user);

        String accessToken = jwtService.generateAccessToken(user);
        String rawRefreshToken = generateSecureToken();
        String tokenHash = hashToken(rawRefreshToken);

        RefreshToken token = new RefreshToken(
                UUID.randomUUID(),
                UUID.randomUUID(), // New family ID
                user,
                tokenHash,
                request.deviceFingerprint(),
                false,
                false,
                Instant.now().plusSeconds(refreshTokenExpirationSeconds),
                Instant.now()
        );
        refreshTokenRepository.save(token);

        auditService.logEvent(AuditEventType.AUTH_TOKEN_ISSUED, user.getId(), clientIp, "Logged in via OTP");

        return AuthResponse.of(
                accessToken,
                rawRefreshToken,
                accessTokenExpirationSeconds,
                UserDto.fromUser(user)
        );
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request, String clientIp) {
        String tokenHash = hashToken(request.refreshToken());
        Optional<RefreshToken> tokenOpt = refreshTokenRepository.findByTokenHash(tokenHash);

        if (tokenOpt.isEmpty()) {
            log.warn("Invalid refresh token attempted from IP: {}", clientIp);
            throw AppException.unauthorized("Invalid refresh token", "INVALID_REFRESH_TOKEN");
        }

        RefreshToken token = tokenOpt.get();
        User user = token.getUser();

        // Stolen Token / Replay Detection:
        // If an already-used or revoked refresh token is presented, this is a token replay attack!
        if (token.isUsed() || token.isRevoked() || token.getExpiresAt().isBefore(Instant.now())) {
            log.error("SECURITY BREACH: Refresh token reuse/replay detected for user: {} in family: {}! Revoking token family.",
                    user.getEmail(), token.getFamilyId());
            refreshTokenRepository.revokeFamily(token.getFamilyId());
            auditService.logEvent(
                    AuditEventType.AUTH_TOKEN_REPLAY_DETECTED,
                    user.getId(),
                    clientIp,
                    "Replay attack detected on token family " + token.getFamilyId() + ". Family revoked."
            );
            throw AppException.unauthorized("Security violation: Session compromised. Please log in again.", "SESSION_REVOKED");
        }

        if (user.isSuspended()) {
            throw AppException.forbidden("Account suspended", "ACCOUNT_SUSPENDED");
        }

        // Mark current token as used
        token.setUsed(true);
        refreshTokenRepository.save(token);

        // Issue new token in the same family
        String newRawRefreshToken = generateSecureToken();
        String newTokenHash = hashToken(newRawRefreshToken);

        RefreshToken newToken = new RefreshToken(
                UUID.randomUUID(),
                token.getFamilyId(),
                user,
                newTokenHash,
                request.deviceFingerprint() != null ? request.deviceFingerprint() : token.getDeviceFingerprint(),
                false,
                false,
                Instant.now().plusSeconds(refreshTokenExpirationSeconds),
                Instant.now()
        );
        refreshTokenRepository.save(newToken);

        String newAccessToken = jwtService.generateAccessToken(user);
        auditService.logEvent(AuditEventType.AUTH_TOKEN_REFRESHED, user.getId(), clientIp, "Token rotated successfully in family " + token.getFamilyId());

        return AuthResponse.of(
                newAccessToken,
                newRawRefreshToken,
                accessTokenExpirationSeconds,
                UserDto.fromUser(user)
        );
    }

    @Transactional
    public void logout(UserPrincipal principal, String clientIp) {
        if (principal != null) {
            userRepository.findById(principal.getId()).ifPresent(user -> {
                refreshTokenRepository.revokeAllForUser(user);
                auditService.logEvent(AuditEventType.AUTH_LOGOUT, user.getId(), clientIp, "User logged out");
            });
        }
    }

    private String generateSecureToken() {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
