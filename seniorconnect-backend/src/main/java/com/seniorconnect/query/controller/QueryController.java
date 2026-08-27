package com.seniorconnect.query.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.query.dto.CreateQueryRequest;
import com.seniorconnect.query.dto.QueryResponseDto;
import com.seniorconnect.query.entity.QueryStatus;
import com.seniorconnect.query.service.QueryService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/queries")
public class QueryController {

    private final QueryService queryService;
    private final com.seniorconnect.query.service.QueryIntelligenceService queryIntelligenceService;

    public QueryController(
            QueryService queryService,
            com.seniorconnect.query.service.QueryIntelligenceService queryIntelligenceService
    ) {
        this.queryService = queryService;
        this.queryIntelligenceService = queryIntelligenceService;
    }

    @PostMapping("/analyze")
    public ResponseEntity<com.seniorconnect.query.dto.QueryAnalysisDto> analyzeQuery(
            @Valid @RequestBody com.seniorconnect.query.dto.AnalyzeQueryRequest request
    ) {
        return ResponseEntity.ok(queryIntelligenceService.analyzeQuery(request));
    }

    @PostMapping
    public ResponseEntity<QueryResponseDto> createQuery(
            @Valid @RequestBody CreateQueryRequest request,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        QueryResponseDto response = queryService.createQuery(request, principal, clientIp);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<QueryResponseDto> getQueryById(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(queryService.getQueryById(id, principal));
    }

    @GetMapping
    public ResponseEntity<Page<QueryResponseDto>> getQueriesFeed(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String tag,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        Pageable pageable = PageRequest.of(page, Math.min(size, 50));
        if (tag != null && !tag.isBlank()) {
            return ResponseEntity.ok(queryService.searchByTag(tag, pageable, principal));
        }
        return ResponseEntity.ok(queryService.getQueriesFeed(pageable, principal));
    }

    @GetMapping("/matched")
    @PreAuthorize("hasAnyRole('SENIOR', 'ADMIN')")
    public ResponseEntity<Page<QueryResponseDto>> getMatchedQueries(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        Pageable pageable = PageRequest.of(page, Math.min(size, 50));
        return ResponseEntity.ok(queryService.getMatchedQueriesForSenior(pageable, principal));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<QueryResponseDto> updateStatus(
            @PathVariable UUID id,
            @RequestParam QueryStatus status,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(queryService.updateStatus(id, status, principal));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
