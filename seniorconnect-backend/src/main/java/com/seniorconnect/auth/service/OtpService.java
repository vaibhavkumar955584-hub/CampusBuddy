package com.seniorconnect.auth.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.ratelimit.RateLimiterService;
import com.seniorconnect.user.repository.AllowedDomainRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final AllowedDomainRepository allowedDomainRepository;
    private final RateLimiterService rateLimiterService;
    private final AuditService auditService;
    private final StringRedisTemplate redisTemplate;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    private final long otpExpirationSeconds;
    private final int maxAttempts;
    private final long lockoutSeconds;

    // Fallback in-memory store when Redis is absent
    private static class OtpEntry {
        final String hashedOtp;
        final Instant expiresAt;
        int attempts;

        OtpEntry(String hashedOtp, Instant expiresAt) {
            this.hashedOtp = hashedOtp;
            this.expiresAt = expiresAt;
            this.attempts = 0;
        }
    }

    private final ConcurrentHashMap<String, OtpEntry> localOtpStore = new ConcurrentHashMap<>();

    public OtpService(
            AllowedDomainRepository allowedDomainRepository,
            RateLimiterService rateLimiterService,
            AuditService auditService,
            @Autowired(required = false) StringRedisTemplate redisTemplate,
            @Value("${seniorconnect.security.otp.expiration-seconds:300}") long otpExpirationSeconds,
            @Value("${seniorconnect.security.otp.max-attempts:5}") int maxAttempts,
            @Value("${seniorconnect.security.otp.lockout-seconds:900}") long lockoutSeconds
    ) {
        this.allowedDomainRepository = allowedDomainRepository;
        this.rateLimiterService = rateLimiterService;
        this.auditService = auditService;
        this.redisTemplate = redisTemplate;
        this.otpExpirationSeconds = otpExpirationSeconds;
        this.maxAttempts = maxAttempts;
        this.lockoutSeconds = lockoutSeconds;
    }

    /**
     * Validates email domain against active allowed domains.
     */
    public void validateCollegeDomain(String email) {
        if (email == null || !email.contains("@")) {
            throw AppException.badRequest("Invalid email address", "INVALID_EMAIL");
        }
        String domain = email.substring(email.lastIndexOf("@") + 1).toLowerCase();
        boolean isAllowed = allowedDomainRepository.existsByDomainAndIsActiveTrue(domain);
        if (!isAllowed) {
            throw AppException.badRequest(
                    "Registration is only allowed for verified college domains (e.g. galgotiacollege.edu.in)",
                    "DOMAIN_NOT_ALLOWED"
            );
        }
    }

    /**
     * Generates a 6-digit OTP, hashes it with BCrypt, and stores it with 5-minute TTL.
     * Rate-limited to prevent OTP flooding.
     */
    public String generateAndSaveOtp(String email, String clientIp) {
        validateCollegeDomain(email);

        // Rate limit: 5 OTP requests per hour per email
        String rateLimitKey = "otp:request:" + email.toLowerCase();
        if (!rateLimiterService.tryAcquire(rateLimitKey, 5, 3600)) {
            throw AppException.tooManyRequests(
                    "Too many OTP requests. Please wait before requesting another code.",
                    "OTP_RATE_LIMIT_EXCEEDED"
            );
        }

        int code = 100000 + SECURE_RANDOM.nextInt(900000);
        String rawOtp = String.valueOf(code);
        String hashedOtp = passwordEncoder.encode(rawOtp);

        String otpKey = "otp:val:" + email.toLowerCase();
        String attemptsKey = "otp:attempts:" + email.toLowerCase();

        if (redisTemplate != null) {
            try {
                redisTemplate.opsForValue().set(otpKey, hashedOtp, Duration.ofSeconds(otpExpirationSeconds));
                redisTemplate.delete(attemptsKey);
            } catch (Exception e) {
                log.warn("Redis unavailable, using local memory store: {}", e.getMessage());
                localOtpStore.put(email.toLowerCase(), new OtpEntry(hashedOtp, Instant.now().plusSeconds(otpExpirationSeconds)));
            }
        } else {
            localOtpStore.put(email.toLowerCase(), new OtpEntry(hashedOtp, Instant.now().plusSeconds(otpExpirationSeconds)));
        }

        auditService.logEvent(AuditEventType.AUTH_OTP_REQUESTED, null, clientIp, "OTP generated for " + email);
        log.info("Secure OTP generated for {} [DEV/TEST PRINT: {}]", email, rawOtp);
        return rawOtp;
    }

    /**
     * Verifies user-provided OTP against the stored BCrypt hash.
     * Enforces max 5 attempts lockout.
     */
    public boolean verifyOtp(String email, String rawOtp, String clientIp) {
        String normEmail = email.toLowerCase();
        String lockoutKey = "otp:lockout:" + normEmail + ":" + clientIp;

        if (redisTemplate != null) {
            try {
                if (Boolean.TRUE.equals(redisTemplate.hasKey(lockoutKey))) {
                    throw AppException.tooManyRequests("Account temporarily locked due to too many failed OTP attempts. Try again in 15 minutes.", "OTP_LOCKED");
                }

                String otpKey = "otp:val:" + normEmail;
                String storedHashedOtp = redisTemplate.opsForValue().get(otpKey);
                if (storedHashedOtp == null) {
                    throw AppException.badRequest("OTP has expired or was not requested", "OTP_EXPIRED");
                }

                String attemptsKey = "otp:attempts:" + normEmail;
                Long attempts = redisTemplate.opsForValue().increment(attemptsKey);

                if (attempts != null && attempts > maxAttempts) {
                    redisTemplate.opsForValue().set(lockoutKey, "locked", Duration.ofSeconds(lockoutSeconds));
                    redisTemplate.delete(otpKey);
                    auditService.logEvent(AuditEventType.AUTH_OTP_FAILED, null, clientIp, "Account locked after max failed attempts: " + email);
                    throw AppException.tooManyRequests("Maximum OTP attempts exceeded. Account locked for 15 minutes.", "OTP_MAX_ATTEMPTS");
                }

                boolean matches = passwordEncoder.matches(rawOtp, storedHashedOtp);
                if (matches) {
                    redisTemplate.delete(otpKey);
                    redisTemplate.delete(attemptsKey);
                    auditService.logEvent(AuditEventType.AUTH_OTP_VERIFIED, null, clientIp, "OTP verified successfully for " + email);
                    return true;
                } else {
                    auditService.logEvent(AuditEventType.AUTH_OTP_FAILED, null, clientIp, "Invalid OTP attempt for " + email);
                    return false;
                }
            } catch (AppException ae) {
                throw ae;
            } catch (Exception e) {
                log.warn("Redis error during OTP verification, falling back: {}", e.getMessage());
            }
        }

        // In-memory fallback
        OtpEntry entry = localOtpStore.get(normEmail);
        if (entry == null || entry.expiresAt.isBefore(Instant.now())) {
            localOtpStore.remove(normEmail);
            throw AppException.badRequest("OTP has expired or was not requested", "OTP_EXPIRED");
        }

        entry.attempts++;
        if (entry.attempts > maxAttempts) {
            localOtpStore.remove(normEmail);
            auditService.logEvent(AuditEventType.AUTH_OTP_FAILED, null, clientIp, "Account locked after max failed attempts (memory): " + email);
            throw AppException.tooManyRequests("Maximum OTP attempts exceeded. Account locked for 15 minutes.", "OTP_MAX_ATTEMPTS");
        }

        boolean matches = passwordEncoder.matches(rawOtp, entry.hashedOtp);
        if (matches) {
            localOtpStore.remove(normEmail);
            auditService.logEvent(AuditEventType.AUTH_OTP_VERIFIED, null, clientIp, "OTP verified successfully for " + email);
            return true;
        } else {
            auditService.logEvent(AuditEventType.AUTH_OTP_FAILED, null, clientIp, "Invalid OTP attempt for " + email);
            return false;
        }
    }
}
