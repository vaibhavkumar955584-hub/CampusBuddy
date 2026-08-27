package com.seniorconnect.matching.controller;

import com.seniorconnect.matching.dto.MentorMatchResultDto;
import com.seniorconnect.matching.service.MatchingService;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.repository.QueryRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/matching")
public class MatchingController {

    private final MatchingService matchingService;
    private final QueryRepository queryRepository;

    public MatchingController(MatchingService matchingService, QueryRepository queryRepository) {
        this.matchingService = matchingService;
        this.queryRepository = queryRepository;
    }

    @GetMapping("/queries/{queryId}/mentors")
    public ResponseEntity<List<MentorMatchResultDto>> getRankedMentorsForQuery(
            @PathVariable UUID queryId,
            @RequestParam(defaultValue = "10") int limit
    ) {
        Query query = queryRepository.findById(queryId).orElse(null);
        if (query == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(matchingService.matchSeniorsWithDetails(query, limit));
    }
}
