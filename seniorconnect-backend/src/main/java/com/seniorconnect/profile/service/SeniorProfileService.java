package com.seniorconnect.profile.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.common.util.SanitizerUtil;
import com.seniorconnect.gamification.service.BadgeService;
import com.seniorconnect.profile.dto.SeniorProfileDto;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
public class SeniorProfileService {

    private final SeniorProfileRepository seniorProfileRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;
    private final BadgeService badgeService;

    public SeniorProfileService(
            SeniorProfileRepository seniorProfileRepository,
            UserRepository userRepository,
            AuditService auditService,
            BadgeService badgeService
    ) {
        this.seniorProfileRepository = seniorProfileRepository;
        this.userRepository = userRepository;
        this.auditService = auditService;
        this.badgeService = badgeService;
    }

    @Transactional
    public SeniorProfile getOrCreateProfile(User user) {
        return seniorProfileRepository.findByUser(user).orElseGet(() -> {
            SeniorProfile profile = new SeniorProfile(
                    UUID.randomUUID(),
                    user,
                    0,
                    null,
                    false,
                    Instant.now()
            );
            return seniorProfileRepository.save(profile);
        });
    }

    @Transactional
    public SeniorProfileDto updatePlacementTag(UserPrincipal principal, String rawTag) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        if (user.getRole() != Role.SENIOR && user.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only seniors can claim placement tags", "FORBIDDEN");
        }

        String cleanTag = SanitizerUtil.sanitizeText(rawTag);
        SeniorProfile profile = getOrCreateProfile(user);
        profile.setPlacementTag(cleanTag);
        // Self-declared tags remain unverified until admin verifies proof
        profile.setTagVerified(false);
        SeniorProfile saved = seniorProfileRepository.save(profile);

        return SeniorProfileDto.fromEntity(saved);
    }

    @Transactional
    public SeniorProfileDto verifyTagByAdmin(UUID seniorUserId, boolean isVerified, UserPrincipal adminPrincipal, String clientIp) {
        if (adminPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only admins can verify placement tags", "ADMIN_REQUIRED");
        }

        User senior = userRepository.findById(seniorUserId)
                .orElseThrow(() -> AppException.notFound("Senior not found", "USER_NOT_FOUND"));

        SeniorProfile profile = getOrCreateProfile(senior);
        profile.setTagVerified(isVerified);
        badgeService.evaluateAndAwardBadges(profile);
        SeniorProfile saved = seniorProfileRepository.save(profile);

        auditService.logEvent(
                AuditEventType.TAG_VERIFIED,
                adminPrincipal.getId(),
                clientIp,
                "Admin " + (isVerified ? "VERIFIED" : "UNVERIFIED") + " placement tag for user " + senior.getEmail()
        );

        return SeniorProfileDto.fromEntity(saved);
    }

    @Transactional
    public void addPoints(User senior, int pointsToAdd) {
        SeniorProfile profile = getOrCreateProfile(senior);
        profile.setPoints(profile.getPoints() + pointsToAdd);
        badgeService.evaluateAndAwardBadges(profile);
        seniorProfileRepository.save(profile);
    }

    @Transactional
    public com.seniorconnect.auth.dto.UserDto toggleMentorMode(UserPrincipal principal, boolean active, String clientIp) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        if (!user.isMentorEligible() && user.getRole() != Role.SENIOR && user.getRole() != Role.ADMIN) {
            throw AppException.forbidden("You must be eligible for mentoring (Year 3+ or Alumni) to enable mentor mode", "NOT_MENTOR_ELIGIBLE");
        }

        user.setMentorModeActive(active);
        if (active) {
            getOrCreateProfile(user);
        }
        User saved = userRepository.save(user);

        auditService.logEvent(
                AuditEventType.PROFILE_UPDATED,
                user.getId(),
                clientIp,
                "Mentor mode toggled to " + active
        );

        return com.seniorconnect.auth.dto.UserDto.fromUser(saved);
    }

    @Transactional(readOnly = true)
    public SeniorProfileDto getProfile(UUID userId) {
        SeniorProfile profile = seniorProfileRepository.findByUserId(userId)
                .orElseThrow(() -> AppException.notFound("Profile not found", "PROFILE_NOT_FOUND"));
        return SeniorProfileDto.fromEntity(profile);
    }
}
