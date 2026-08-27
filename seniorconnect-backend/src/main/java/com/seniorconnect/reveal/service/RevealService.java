package com.seniorconnect.reveal.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.repository.QueryRepository;
import com.seniorconnect.ratelimit.RateLimiterService;
import com.seniorconnect.reveal.dto.RevealRequestDto;
import com.seniorconnect.reveal.entity.RevealRequest;
import com.seniorconnect.reveal.entity.RevealStatus;
import com.seniorconnect.reveal.repository.RevealRequestRepository;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class RevealService {

    private static final Logger log = LoggerFactory.getLogger(RevealService.class);

    private final RevealRequestRepository revealRequestRepository;
    private final QueryRepository queryRepository;
    private final UserRepository userRepository;
    private final RateLimiterService rateLimiterService;
    private final AuditService auditService;
    private final com.seniorconnect.mentorship.service.MentorshipService mentorshipService;

    public RevealService(
            RevealRequestRepository revealRequestRepository,
            QueryRepository queryRepository,
            UserRepository userRepository,
            RateLimiterService rateLimiterService,
            AuditService auditService,
            com.seniorconnect.mentorship.service.MentorshipService mentorshipService
    ) {
        this.revealRequestRepository = revealRequestRepository;
        this.queryRepository = queryRepository;
        this.userRepository = userRepository;
        this.rateLimiterService = rateLimiterService;
        this.auditService = auditService;
        this.mentorshipService = mentorshipService;
    }

    /**
     * Senior initiates an identity reveal request.
     * Rate-limited to 10 requests per day per senior to prevent mass deanonymization attempts.
     */
    @Transactional
    public RevealRequestDto requestReveal(UUID queryId, UserPrincipal seniorPrincipal, String clientIp) {
        if (seniorPrincipal.getRole() != Role.SENIOR && seniorPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only seniors or admins can request identity reveal", "ONLY_SENIORS_CAN_REQUEST_REVEAL");
        }

        // Rate-limiting: 10 reveals per day per senior
        String rateLimitKey = "reveal:senior:" + seniorPrincipal.getId();
        if (!rateLimiterService.tryAcquire(rateLimitKey, 10, 86400)) {
            throw AppException.tooManyRequests(
                    "You have reached your daily limit of 10 identity reveal requests.",
                    "REVEAL_RATE_LIMIT_EXCEEDED"
            );
        }

        Query query = queryRepository.findById(queryId)
                .orElseThrow(() -> AppException.notFound("Query not found", "QUERY_NOT_FOUND"));

        User senior = userRepository.findById(seniorPrincipal.getId())
                .orElseThrow(() -> AppException.notFound("Senior user not found", "USER_NOT_FOUND"));

        if (query.getJunior().getId().equals(senior.getId())) {
            throw AppException.badRequest("You cannot request identity reveal on your own query", "INVALID_REVEAL_TARGET");
        }

        Optional<RevealRequest> existingOpt = revealRequestRepository.findByQueryAndSenior(query, senior);
        if (existingOpt.isPresent()) {
            RevealRequest existing = existingOpt.get();
            if (existing.getStatus() == RevealStatus.PENDING) {
                throw AppException.badRequest("An identity reveal request is already pending junior approval", "REVEAL_ALREADY_PENDING");
            } else if (existing.getStatus() == RevealStatus.ACCEPTED) {
                throw AppException.badRequest("Identity has already been revealed", "REVEAL_ALREADY_ACCEPTED");
            } else {
                throw AppException.badRequest("Previous reveal request was rejected", "REVEAL_PREVIOUSLY_REJECTED");
            }
        }

        RevealRequest revealRequest = new RevealRequest(
                UUID.randomUUID(),
                query,
                query.getJunior(),
                senior,
                RevealStatus.PENDING,
                Instant.now(),
                null
        );
        RevealRequest saved = revealRequestRepository.save(revealRequest);

        auditService.logEvent(
                AuditEventType.REVEAL_REQUESTED,
                senior.getId(),
                clientIp,
                "Reveal requested for queryId=" + queryId + " juniorId=" + query.getJunior().getId()
        );

        return RevealRequestDto.fromEntity(saved, false);
    }

    /**
     * Junior explicitly accepts or rejects the reveal request.
     * Guaranteed IDOR safe: acting user must be the query's junior owner.
     */
    @Transactional
    public RevealRequestDto respondToReveal(UUID revealRequestId, boolean accept, UserPrincipal juniorPrincipal, String clientIp) {
        RevealRequest revealRequest = revealRequestRepository.findById(revealRequestId)
                .orElseThrow(() -> AppException.notFound("Reveal request not found", "REVEAL_NOT_FOUND"));

        if (!revealRequest.getJunior().getId().equals(juniorPrincipal.getId())) {
            throw AppException.forbidden("You do not have permission to respond to this reveal request", "IDOR_FORBIDDEN");
        }

        if (revealRequest.getStatus() != RevealStatus.PENDING) {
            throw AppException.badRequest("Reveal request is no longer pending", "REVEAL_NOT_PENDING");
        }

        revealRequest.setStatus(accept ? RevealStatus.ACCEPTED : RevealStatus.REJECTED);
        revealRequest.setResolvedAt(Instant.now());
        RevealRequest saved = revealRequestRepository.save(revealRequest);

        if (accept) {
            // Privacy Level 3 transition: auto-provision 1-on-1 Direct Mentorship Session
            mentorshipService.createOrGetSession(revealRequest.getJunior(), revealRequest.getSenior(), revealRequest.getQuery(), null);
        }

        AuditEventType eventType = accept ? AuditEventType.REVEAL_ACCEPTED : AuditEventType.REVEAL_REJECTED;
        auditService.logEvent(
                eventType,
                juniorPrincipal.getId(),
                clientIp,
                "Reveal response " + (accept ? "ACCEPTED" : "REJECTED") + " for revealRequestId=" + revealRequestId + " seniorId=" + revealRequest.getSenior().getId()
        );

        return RevealRequestDto.fromEntity(saved, true);
    }

    /**
     * Fresh, per-request transactional check to determine if senior has accepted reveal authorization.
     * Uses SELECT ... FOR SHARE isolation.
     */
    @Transactional(readOnly = true)
    public boolean isIdentityRevealed(UUID queryId, UUID seniorId) {
        if (queryId == null || seniorId == null) {
            return false;
        }
        Optional<RevealRequest> reqOpt = revealRequestRepository.findByQueryIdAndSeniorIdForShare(queryId, seniorId);
        return reqOpt.isPresent() && reqOpt.get().getStatus() == RevealStatus.ACCEPTED;
    }

    /**
     * Get pending reveal requests for a Junior.
     */
    @Transactional(readOnly = true)
    public List<RevealRequestDto> getPendingRevealsForJunior(UserPrincipal juniorPrincipal) {
        User junior = userRepository.findById(juniorPrincipal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));
        return revealRequestRepository.findByJuniorAndStatus(junior, RevealStatus.PENDING)
                .stream()
                .map(r -> RevealRequestDto.fromEntity(r, true))
                .toList();
    }
}
