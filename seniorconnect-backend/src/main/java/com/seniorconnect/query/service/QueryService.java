package com.seniorconnect.query.service;

import com.seniorconnect.audit.model.AuditEventType;
import com.seniorconnect.audit.service.AuditService;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.common.util.SanitizerUtil;
import com.seniorconnect.profile.dto.SeniorProfileDto;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.profile.service.SeniorProfileService;
import com.seniorconnect.query.dto.AnswerResponseDto;
import com.seniorconnect.query.dto.CreateQueryRequest;
import com.seniorconnect.query.dto.QueryResponseDto;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.QueryStatus;
import com.seniorconnect.query.entity.Response;
import com.seniorconnect.query.repository.QueryRepository;
import com.seniorconnect.query.repository.ResponseRepository;
import com.seniorconnect.ratelimit.RateLimiterService;
import com.seniorconnect.reveal.service.RevealService;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class QueryService {

    private final QueryRepository queryRepository;
    private final ResponseRepository responseRepository;
    private final UserRepository userRepository;
    private final SeniorProfileRepository seniorProfileRepository;
    private final RateLimiterService rateLimiterService;
    private final AuditService auditService;
    private final RevealService revealService;
    private final SeniorProfileService seniorProfileService;

    public QueryService(
            QueryRepository queryRepository,
            ResponseRepository responseRepository,
            UserRepository userRepository,
            SeniorProfileRepository seniorProfileRepository,
            RateLimiterService rateLimiterService,
            AuditService auditService,
            RevealService revealService,
            SeniorProfileService seniorProfileService
    ) {
        this.queryRepository = queryRepository;
        this.responseRepository = responseRepository;
        this.userRepository = userRepository;
        this.seniorProfileRepository = seniorProfileRepository;
        this.rateLimiterService = rateLimiterService;
        this.auditService = auditService;
        this.revealService = revealService;
        this.seniorProfileService = seniorProfileService;
    }

    @Transactional
    public QueryResponseDto createQuery(CreateQueryRequest request, UserPrincipal principal, String clientIp) {
        // Rate limit: 5 queries per day per user
        String rateLimitKey = "query:create:" + principal.getId();
        if (!rateLimiterService.tryAcquire(rateLimitKey, 5, 86400)) {
            throw AppException.tooManyRequests(
                    "You have reached your daily quota of 5 queries.",
                    "QUERY_RATE_LIMIT_EXCEEDED"
            );
        }

        User junior = userRepository.findById(principal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        // Sanitize rich/free-text fields on write (Stored XSS defense)
        String cleanTitle = SanitizerUtil.sanitizeText(request.title());
        String cleanContent = SanitizerUtil.sanitizeText(request.content());
        String cleanTags = SanitizerUtil.sanitizeTags(request.tags());

        Query query = new Query(
                UUID.randomUUID(),
                junior,
                cleanTitle,
                cleanContent,
                cleanTags,
                request.isAnonymousDisplay(),
                QueryStatus.OPEN,
                Instant.now(),
                null
        );
        Query saved = queryRepository.save(query);

        auditService.logEvent(AuditEventType.QUERY_CREATED, junior.getId(), clientIp, "Query created id=" + saved.getId());

        return QueryResponseDto.fromEntity(saved, false, true, Collections.emptyList());
    }

    @Transactional(readOnly = true)
    public QueryResponseDto getQueryById(UUID queryId, UserPrincipal principal) {
        Query query = queryRepository.findById(queryId)
                .orElseThrow(() -> AppException.notFound("Query not found", "QUERY_NOT_FOUND"));

        boolean isAuthorOrAdmin = principal.getId().equals(query.getJunior().getId()) || principal.getRole() == Role.ADMIN;
        boolean isRevealed = !isAuthorOrAdmin && revealService.isIdentityRevealed(queryId, principal.getId());

        List<Response> responses = responseRepository.findByQueryOrderByCreatedAtAsc(query);
        List<AnswerResponseDto> responseDtos = responses.stream().map(r -> {
            SeniorProfileDto profile = null;
            try {
                profile = seniorProfileService.getProfile(r.getSenior().getId());
            } catch (Exception ignored) {
            }
            return AnswerResponseDto.fromEntity(r, profile);
        }).toList();

        return QueryResponseDto.fromEntity(query, isRevealed, isAuthorOrAdmin, responseDtos);
    }

    @Transactional(readOnly = true)
    public Page<QueryResponseDto> getQueriesFeed(Pageable pageable, UserPrincipal principal) {
        Page<Query> page = queryRepository.findAllByOrderByCreatedAtDesc(pageable);
        return page.map(query -> {
            boolean isAuthorOrAdmin = principal.getId().equals(query.getJunior().getId()) || principal.getRole() == Role.ADMIN;
            boolean isRevealed = !isAuthorOrAdmin && revealService.isIdentityRevealed(query.getId(), principal.getId());
            return QueryResponseDto.fromEntity(query, isRevealed, isAuthorOrAdmin, null);
        });
    }

    @Transactional(readOnly = true)
    public Page<QueryResponseDto> getMatchedQueriesForSenior(Pageable pageable, UserPrincipal principal) {
        SeniorProfile profile = seniorProfileRepository.findByUserId(principal.getId()).orElse(null);
        User senior = userRepository.findById(principal.getId()).orElse(null);

        Set<String> seniorTags = new HashSet<>();
        if (profile != null) {
            seniorTags.addAll(profile.getTags().stream().map(String::toLowerCase).toList());
            if (profile.getPlacementTag() != null) {
                seniorTags.add(profile.getPlacementTag().toLowerCase());
            }
        }
        String seniorBranch = senior != null ? senior.getBranch() : null;

        Page<Query> openQueries = queryRepository.findByStatusOrderByCreatedAtDesc(QueryStatus.OPEN, pageable);

        List<Query> filtered = openQueries.getContent().stream()
                .filter(q -> !q.getJunior().getId().equals(principal.getId()))
                .sorted((q1, q2) -> {
                    int score1 = calculateQueryMatchScore(q1, seniorTags, seniorBranch);
                    int score2 = calculateQueryMatchScore(q2, seniorTags, seniorBranch);
                    return Integer.compare(score2, score1);
                })
                .collect(Collectors.toList());

        Page<Query> matchedPage = new PageImpl<>(filtered, pageable, openQueries.getTotalElements());
        return matchedPage.map(query -> {
            boolean isAuthorOrAdmin = principal.getId().equals(query.getJunior().getId()) || principal.getRole() == Role.ADMIN;
            boolean isRevealed = !isAuthorOrAdmin && revealService.isIdentityRevealed(query.getId(), principal.getId());
            return QueryResponseDto.fromEntity(query, isRevealed, isAuthorOrAdmin, null);
        });
    }

    private int calculateQueryMatchScore(Query query, Set<String> seniorTags, String seniorBranch) {
        int score = 0;
        if (seniorBranch != null && query.getJunior().getBranch() != null && seniorBranch.equalsIgnoreCase(query.getJunior().getBranch())) {
            score += 10;
        }
        for (String qTag : query.getTagsList()) {
            String qTagLower = qTag.toLowerCase();
            for (String sTag : seniorTags) {
                if (sTag.contains(qTagLower) || qTagLower.contains(sTag)) {
                    score += 20;
                }
            }
        }
        return score;
    }

    @Transactional(readOnly = true)
    public Page<QueryResponseDto> searchByTag(String tag, Pageable pageable, UserPrincipal principal) {
        Page<Query> page = queryRepository.findByTagContaining(tag, pageable);
        return page.map(query -> {
            boolean isAuthorOrAdmin = principal.getId().equals(query.getJunior().getId()) || principal.getRole() == Role.ADMIN;
            boolean isRevealed = !isAuthorOrAdmin && revealService.isIdentityRevealed(query.getId(), principal.getId());
            return QueryResponseDto.fromEntity(query, isRevealed, isAuthorOrAdmin, null);
        });
    }

    @Transactional
    public QueryResponseDto updateStatus(UUID queryId, QueryStatus newStatus, UserPrincipal principal) {
        Query query = queryRepository.findById(queryId)
                .orElseThrow(() -> AppException.notFound("Query not found", "QUERY_NOT_FOUND"));

        // Strict Resource Ownership check (IDOR Defense)
        if (!query.getJunior().getId().equals(principal.getId()) && principal.getRole() != Role.ADMIN) {
            throw AppException.forbidden("You are not authorized to update this query", "IDOR_FORBIDDEN");
        }

        query.setStatus(newStatus);
        Query saved = queryRepository.save(query);
        return QueryResponseDto.fromEntity(saved, false, true, Collections.emptyList());
    }
}
