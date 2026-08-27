package com.seniorconnect.mentorship.controller;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.mentorship.dto.*;
import com.seniorconnect.mentorship.service.MentorshipService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/mentorships")
public class MentorshipController {

    private final MentorshipService mentorshipService;

    public MentorshipController(MentorshipService mentorshipService) {
        this.mentorshipService = mentorshipService;
    }

    @PostMapping("/plans")
    public ResponseEntity<MentorshipPlanDto> createPlan(
            @Valid @RequestBody CreatePlanRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(mentorshipService.createPlan(request, principal));
    }

    @GetMapping("/plans/my")
    public ResponseEntity<List<MentorshipPlanDto>> getMyPlans(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(mentorshipService.getMyPlans(principal));
    }

    @PatchMapping("/plans/{planId}/tasks/{taskId}/toggle")
    public ResponseEntity<MentorshipPlanDto> toggleTask(
            @PathVariable UUID planId,
            @PathVariable UUID taskId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(mentorshipService.toggleTaskCompletion(planId, taskId, principal));
    }

    @GetMapping("/sessions/my")
    public ResponseEntity<List<MentorshipSessionDto>> getMySessions(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(mentorshipService.getMySessions(principal));
    }

    @PatchMapping("/sessions/{sessionId}/schedule")
    public ResponseEntity<MentorshipSessionDto> scheduleSession(
            @PathVariable UUID sessionId,
            @RequestBody ScheduleSessionRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(mentorshipService.scheduleSession(sessionId, request, principal));
    }

    @PostMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<SessionMessageDto> sendMessage(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SendMessageRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(mentorshipService.sendMessage(sessionId, request, principal));
    }

    @GetMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<List<SessionMessageDto>> getSessionMessages(
            @PathVariable UUID sessionId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(mentorshipService.getSessionMessages(sessionId, principal));
    }

    @PostMapping("/sessions/{sessionId}/reviews")
    public ResponseEntity<MentorshipReviewDto> submitReview(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SubmitReviewRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(mentorshipService.submitSessionReview(sessionId, request, principal));
    }

    @GetMapping("/mentors/{mentorId}/analytics")
    public ResponseEntity<MentorAnalyticsDto> getMentorAnalytics(
            @PathVariable UUID mentorId
    ) {
        return ResponseEntity.ok(mentorshipService.getMentorAnalytics(mentorId));
    }

    @GetMapping("/mentors/{mentorId}/reviews")
    public ResponseEntity<List<MentorshipReviewDto>> getMentorReviews(
            @PathVariable UUID mentorId
    ) {
        return ResponseEntity.ok(mentorshipService.getMentorReviews(mentorId));
    }

    @GetMapping("/analytics/overview")
    public ResponseEntity<CampusMentorshipOverviewDto> getCampusOverview() {
        return ResponseEntity.ok(mentorshipService.getCampusOverview());
    }

    @PostMapping("/outcomes")
    public ResponseEntity<OutcomeDto> submitOutcome(
            @Valid @RequestBody SubmitOutcomeRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(mentorshipService.submitOutcome(request, principal));
    }

    @GetMapping("/outcomes/verified")
    public ResponseEntity<List<OutcomeDto>> getVerifiedOutcomes() {
        return ResponseEntity.ok(mentorshipService.getVerifiedOutcomes());
    }
}
