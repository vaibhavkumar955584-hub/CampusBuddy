package com.seniorconnect.query.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.common.util.SanitizerUtil;
import com.seniorconnect.profile.dto.SeniorProfileDto;
import com.seniorconnect.profile.service.SeniorProfileService;
import com.seniorconnect.query.dto.AnswerResponseDto;
import com.seniorconnect.query.dto.CreateResponseRequest;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.QueryStatus;
import com.seniorconnect.query.entity.Response;
import com.seniorconnect.query.repository.QueryRepository;
import com.seniorconnect.query.repository.ResponseRepository;
import com.seniorconnect.ratelimit.RateLimiterService;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
public class ResponseService {

    private final ResponseRepository responseRepository;
    private final QueryRepository queryRepository;
    private final UserRepository userRepository;
    private final RateLimiterService rateLimiterService;
    private final AuditService auditService;
    private final SeniorProfileService seniorProfileService;

    public ResponseService(
            ResponseRepository responseRepository,
            QueryRepository queryRepository,
            UserRepository userRepository,
            RateLimiterService rateLimiterService,
            AuditService auditService,
            SeniorProfileService seniorProfileService
    ) {
        this.responseRepository = responseRepository;
        this.queryRepository = queryRepository;
        this.userRepository = userRepository;
        this.rateLimiterService = rateLimiterService;
        this.auditService = auditService;
        this.seniorProfileService = seniorProfileService;
    }

    @Transactional
    public AnswerResponseDto postResponse(UUID queryId, CreateResponseRequest request, UserPrincipal seniorPrincipal, String clientIp) {
        if (seniorPrincipal.getRole() != Role.SENIOR && seniorPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only verified seniors or administrators can provide mentorship responses", "SENIOR_REQUIRED");
        }

        // Rate-limiting: 20 responses per day per senior
        String rateLimitKey = "response:create:" + seniorPrincipal.getId();
        if (!rateLimiterService.tryAcquire(rateLimitKey, 20, 86400)) {
            throw AppException.tooManyRequests(
                    "You have reached your daily quota of 20 answers.",
                    "RESPONSE_RATE_LIMIT_EXCEEDED"
            );
        }

        Query query = queryRepository.findById(queryId)
                .orElseThrow(() -> AppException.notFound("Query not found", "QUERY_NOT_FOUND"));

        if (query.getStatus() == QueryStatus.CLOSED) {
            throw AppException.badRequest("Cannot answer a closed query", "QUERY_CLOSED");
        }

        User senior = userRepository.findById(seniorPrincipal.getId())
                .orElseThrow(() -> AppException.notFound("Senior user not found", "USER_NOT_FOUND"));

        String cleanContent = SanitizerUtil.sanitizeText(request.content());

        Response response = new Response(
                UUID.randomUUID(),
                query,
                senior,
                cleanContent,
                false,
                Instant.now(),
                null
        );
        Response saved = responseRepository.save(response);

        // Award mentorship points
        seniorProfileService.addPoints(senior, 10);

        auditService.logEvent(
                AuditEventType.RESPONSE_POSTED,
                senior.getId(),
                clientIp,
                "Response posted to queryId=" + queryId + " responseId=" + saved.getId()
        );

        SeniorProfileDto profile = null;
        try {
            profile = seniorProfileService.getProfile(senior.getId());
        } catch (Exception ignored) {
        }

        return AnswerResponseDto.fromEntity(saved, profile);
    }

    @Transactional
    public AnswerResponseDto acceptAnswer(UUID queryId, UUID responseId, UserPrincipal juniorPrincipal, String clientIp) {
        Query query = queryRepository.findById(queryId)
                .orElseThrow(() -> AppException.notFound("Query not found", "QUERY_NOT_FOUND"));

        // Strict Resource-Level Ownership Check (IDOR defense)
        if (!query.getJunior().getId().equals(juniorPrincipal.getId()) && juniorPrincipal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("Only the author of the query can accept an answer", "IDOR_FORBIDDEN");
        }

        Response response = responseRepository.findById(responseId)
                .orElseThrow(() -> AppException.notFound("Response not found", "RESPONSE_NOT_FOUND"));

        if (!response.getQuery().getId().equals(queryId)) {
            throw AppException.badRequest("Response does not belong to the specified query", "INVALID_ASSOCIATION");
        }

        response.setAcceptedAnswer(true);
        query.setStatus(QueryStatus.RESOLVED);

        queryRepository.save(query);
        Response saved = responseRepository.save(response);

        // Award bonus points for accepted answer
        seniorProfileService.addPoints(response.getSenior(), 25);

        SeniorProfileDto profile = null;
        try {
            profile = seniorProfileService.getProfile(response.getSenior().getId());
        } catch (Exception ignored) {
        }

        return AnswerResponseDto.fromEntity(saved, profile);
    }
}
