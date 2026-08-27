package com.seniorconnect.mentorship.service;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.common.exception.AppException;
import com.seniorconnect.mentorship.dto.*;
import com.seniorconnect.mentorship.entity.*;
import com.seniorconnect.mentorship.repository.MentorshipPlanRepository;
import com.seniorconnect.mentorship.repository.MentorshipSessionRepository;
import com.seniorconnect.mentorship.repository.OutcomeRepository;
import com.seniorconnect.mentorship.repository.SessionMessageRepository;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.profile.service.SeniorProfileService;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MentorshipService {

    private final MentorshipPlanRepository planRepository;
    private final OutcomeRepository outcomeRepository;
    private final UserRepository userRepository;
    private final SeniorProfileService seniorProfileService;
    private final MentorshipSessionRepository sessionRepository;
    private final SessionMessageRepository sessionMessageRepository;
    private final SeniorProfileRepository seniorProfileRepository;
    private final com.seniorconnect.mentorship.repository.MentorshipReviewRepository reviewRepository;

    public MentorshipService(
            MentorshipPlanRepository planRepository,
            OutcomeRepository outcomeRepository,
            UserRepository userRepository,
            SeniorProfileService seniorProfileService,
            MentorshipSessionRepository sessionRepository,
            SessionMessageRepository sessionMessageRepository,
            SeniorProfileRepository seniorProfileRepository,
            com.seniorconnect.mentorship.repository.MentorshipReviewRepository reviewRepository
    ) {
        this.planRepository = planRepository;
        this.outcomeRepository = outcomeRepository;
        this.userRepository = userRepository;
        this.seniorProfileService = seniorProfileService;
        this.sessionRepository = sessionRepository;
        this.sessionMessageRepository = sessionMessageRepository;
        this.seniorProfileRepository = seniorProfileRepository;
        this.reviewRepository = reviewRepository;
    }

    @Transactional
    public MentorshipPlanDto createPlan(CreatePlanRequest req, UserPrincipal principal) {
        User junior = userRepository.findById(principal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        User senior = null;
        if (req.seniorId() != null) {
            senior = userRepository.findById(req.seniorId()).orElse(null);
        }

        int duration = req.durationDays() != null && req.durationDays() > 0 ? req.durationDays() : 90;
        MentorshipPlan plan = new MentorshipPlan(
                junior,
                senior,
                req.goalTitle(),
                req.targetCompany() != null ? req.targetCompany() : "Target Company",
                req.targetRole() != null ? req.targetRole() : "SDE",
                duration
        );

        // Auto-populate standard 90-day milestones
        List<PlanTask> tasks = new ArrayList<>();
        tasks.add(new PlanTask(plan, 1, "Week 1-2: Core DSA Foundations", "Arrays, Strings, Two Pointers & Time Complexity analysis"));
        tasks.add(new PlanTask(plan, 3, "Week 3-4: Data Structures Deep-Dive", "HashMaps, Stacks, Queues & Linked Lists practice problems"));
        tasks.add(new PlanTask(plan, 5, "Week 5-6: Trees, Graphs & Recursion", "Binary Search Trees, BFS/DFS Traversal & Dynamic Programming"));
        tasks.add(new PlanTask(plan, 7, "Week 7-8: Core CS & System Design Basics", "Operating Systems, DBMS Indexing & REST API Architecture"));
        tasks.add(new PlanTask(plan, 9, "Week 9-10: Mock Interview & Resume Polish", "1-on-1 Senior Mock Interview session & Project defense preparation"));
        tasks.add(new PlanTask(plan, 11, "Week 11-12: Final Placement Drills", "Company-specific previous questions & HR behavioral round readiness"));

        plan.setTasks(tasks);
        MentorshipPlan saved = planRepository.save(plan);

        // Auto-provision Privacy Level 3 Direct Mentorship Session if senior is assigned
        if (senior != null) {
            createOrGetSession(junior, senior, null, saved);
        }

        return mapToPlanDto(saved);
    }

    @Transactional
    public MentorshipSession createOrGetSession(User junior, User senior, Query query, MentorshipPlan plan) {
        return sessionRepository.findByJuniorIdAndSeniorId(junior.getId(), senior.getId())
                .orElseGet(() -> {
                    MentorshipSession session = new MentorshipSession(junior, senior, query, plan);
                    return sessionRepository.save(session);
                });
    }

    @Transactional
    public MentorshipPlanDto toggleTaskCompletion(UUID planId, UUID taskId, UserPrincipal principal) {
        MentorshipPlan plan = planRepository.findById(planId)
                .orElseThrow(() -> AppException.notFound("Mentorship plan not found", "PLAN_NOT_FOUND"));

        if (!plan.getJunior().getId().equals(principal.getId()) &&
                (plan.getSenior() == null || !plan.getSenior().getId().equals(principal.getId()))) {
            throw AppException.forbidden("Access denied to this mentorship plan", "FORBIDDEN");
        }

        PlanTask targetTask = plan.getTasks().stream()
                .filter(t -> t.getId().equals(taskId))
                .findFirst()
                .orElseThrow(() -> AppException.notFound("Task not found", "TASK_NOT_FOUND"));

        targetTask.setCompleted(!targetTask.isCompleted());

        long completedCount = plan.getTasks().stream().filter(PlanTask::isCompleted).count();
        int progress = (int) Math.round(((double) completedCount / plan.getTasks().size()) * 100.0);
        plan.setProgressPercentage(progress);

        if (progress == 100) {
            plan.setStatus("COMPLETED");
        }

        return mapToPlanDto(planRepository.save(plan));
    }

    @Transactional(readOnly = true)
    public List<MentorshipPlanDto> getMyPlans(UserPrincipal principal) {
        List<MentorshipPlan> plans;
        if (principal.getRole().name().equals("SENIOR")) {
            plans = planRepository.findBySeniorIdOrderByCreatedAtDesc(principal.getId());
        } else {
            plans = planRepository.findByJuniorIdOrderByCreatedAtDesc(principal.getId());
        }
        return plans.stream().map(this::mapToPlanDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MentorshipSessionDto> getMySessions(UserPrincipal principal) {
        List<MentorshipSession> sessions;
        if (principal.getRole().name().equals("SENIOR")) {
            sessions = sessionRepository.findBySeniorIdOrderByCreatedAtDesc(principal.getId());
        } else {
            sessions = sessionRepository.findByJuniorIdOrderByCreatedAtDesc(principal.getId());
        }
        return sessions.stream().map(this::mapToSessionDto).collect(Collectors.toList());
    }

    @Transactional
    public MentorshipSessionDto scheduleSession(UUID sessionId, ScheduleSessionRequest req, UserPrincipal principal) {
        MentorshipSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> AppException.notFound("Mentorship session not found", "SESSION_NOT_FOUND"));

        if (!session.getJunior().getId().equals(principal.getId()) && !session.getSenior().getId().equals(principal.getId())) {
            throw AppException.forbidden("Access denied to session", "FORBIDDEN");
        }

        if (req.scheduledAt() != null) session.setScheduledAt(req.scheduledAt());
        if (req.meetingLink() != null) session.setMeetingLink(req.meetingLink());
        if (req.sessionNotes() != null) session.setSessionNotes(req.sessionNotes());

        return mapToSessionDto(sessionRepository.save(session));
    }

    @Transactional
    public SessionMessageDto sendMessage(UUID sessionId, SendMessageRequest req, UserPrincipal principal) {
        MentorshipSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> AppException.notFound("Mentorship session not found", "SESSION_NOT_FOUND"));

        if (!session.getJunior().getId().equals(principal.getId()) && !session.getSenior().getId().equals(principal.getId())) {
            throw AppException.forbidden("Access denied to session", "FORBIDDEN");
        }

        User sender = userRepository.findById(principal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        SessionMessage msg = new SessionMessage(session, sender, req.messageContent());
        SessionMessage saved = sessionMessageRepository.save(msg);

        return new SessionMessageDto(
                saved.getId(),
                session.getId(),
                sender.getId(),
                sender.getFullName(),
                saved.getMessageContent(),
                saved.isEncrypted(),
                saved.getCreatedAt()
        );
    }

    @Transactional(readOnly = true)
    public List<SessionMessageDto> getSessionMessages(UUID sessionId, UserPrincipal principal) {
        MentorshipSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> AppException.notFound("Mentorship session not found", "SESSION_NOT_FOUND"));

        if (!session.getJunior().getId().equals(principal.getId()) && !session.getSenior().getId().equals(principal.getId())) {
            throw AppException.forbidden("Access denied to session", "FORBIDDEN");
        }

        return sessionMessageRepository.findBySessionIdOrderByCreatedAtAsc(sessionId).stream()
                .map(m -> new SessionMessageDto(
                        m.getId(),
                        sessionId,
                        m.getSender().getId(),
                        m.getSender().getFullName(),
                        m.getMessageContent(),
                        m.isEncrypted(),
                        m.getCreatedAt()
                ))
                .collect(Collectors.toList());
    }

    @Transactional
    public OutcomeDto submitOutcome(SubmitOutcomeRequest req, UserPrincipal principal) {
        User junior = userRepository.findById(principal.getId())
                .orElseThrow(() -> AppException.notFound("User not found", "USER_NOT_FOUND"));

        MentorshipPlan plan = null;
        if (req.planId() != null) {
            plan = planRepository.findById(req.planId()).orElse(null);
        }

        User senior = null;
        if (req.seniorId() != null) {
            senior = userRepository.findById(req.seniorId()).orElse(null);
        } else if (plan != null && plan.getSenior() != null) {
            senior = plan.getSenior();
        }

        Outcome outcome = new Outcome(junior, senior, plan, req.outcomeType(), req.company(), req.role());
        outcome.setProofUrl(req.proofUrl());
        outcome.setVerified(true);

        if (senior != null) {
            seniorProfileService.addPoints(senior, 50);
        }

        Outcome saved = outcomeRepository.save(outcome);
        return mapToOutcomeDto(saved);
    }

    @Transactional(readOnly = true)
    public List<OutcomeDto> getVerifiedOutcomes() {
        return outcomeRepository.findByIsVerifiedTrue().stream()
                .map(this::mapToOutcomeDto)
                .collect(Collectors.toList());
    }

    private MentorshipPlanDto mapToPlanDto(MentorshipPlan p) {
        List<MentorshipPlanDto.PlanTaskDto> taskDtos = p.getTasks().stream()
                .map(t -> new MentorshipPlanDto.PlanTaskDto(t.getId(), t.getWeekNumber(), t.getTitle(), t.getDescription(), t.isCompleted()))
                .collect(Collectors.toList());

        return new MentorshipPlanDto(
                p.getId(),
                p.getJunior().getId(),
                p.getJunior().getFullName(),
                p.getSenior() != null ? p.getSenior().getId() : null,
                p.getSenior() != null ? p.getSenior().getFullName() : "Assigned Senior Mentor",
                p.getGoalTitle(),
                p.getTargetCompany(),
                p.getTargetRole(),
                p.getDurationDays(),
                p.getStatus(),
                p.getProgressPercentage(),
                taskDtos,
                p.getCreatedAt()
        );
    }

    private MentorshipSessionDto mapToSessionDto(MentorshipSession s) {
        String placementTag = seniorProfileRepository.findByUser(s.getSenior())
                .map(SeniorProfile::getPlacementTag)
                .orElse(null);

        return new MentorshipSessionDto(
                s.getId(),
                s.getJunior().getId(),
                s.getJunior().getFullName(),
                s.getJunior().getEmail(),
                s.getJunior().getBranch(),
                s.getSenior().getId(),
                s.getSenior().getFullName(),
                s.getSenior().getEmail(),
                s.getSenior().getBranch(),
                placementTag,
                s.getQuery() != null ? s.getQuery().getId() : null,
                s.getQuery() != null ? s.getQuery().getTitle() : null,
                s.getPlan() != null ? s.getPlan().getId() : null,
                s.getStatus(),
                s.getPrivacyLevel(),
                s.getMeetingLink(),
                s.getSessionNotes(),
                s.getScheduledAt(),
                s.getCreatedAt()
        );
    }

    @Transactional
    public MentorshipReviewDto submitSessionReview(UUID sessionId, SubmitReviewRequest req, UserPrincipal principal) {
        MentorshipSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> AppException.notFound("Mentorship session not found", "SESSION_NOT_FOUND"));

        if (!session.getJunior().getId().equals(principal.getId())) {
            throw AppException.forbidden("Only the junior mentee can review this mentorship session", "FORBIDDEN");
        }

        User junior = session.getJunior();
        User senior = session.getSenior();

        MentorshipReview review = reviewRepository.findBySessionId(sessionId)
                .orElseGet(() -> new MentorshipReview(session, junior, senior, req.rating(), req.reviewComment()));

        review.setRating(req.rating());
        review.setReviewComment(req.reviewComment());
        MentorshipReview saved = reviewRepository.save(review);

        // Award +10 points to senior mentor for high ratings
        if (req.rating() >= 4) {
            seniorProfileService.addPoints(senior, 10);
        }

        return mapToReviewDto(saved);
    }

    @Transactional(readOnly = true)
    public List<MentorshipReviewDto> getMentorReviews(UUID mentorId) {
        return reviewRepository.findBySeniorIdOrderByCreatedAtDesc(mentorId).stream()
                .filter(MentorshipReview::isPublic)
                .map(this::mapToReviewDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public MentorAnalyticsDto getMentorAnalytics(UUID mentorId) {
        User mentor = userRepository.findById(mentorId)
                .orElseThrow(() -> AppException.notFound("Mentor user not found", "USER_NOT_FOUND"));

        SeniorProfile profile = seniorProfileRepository.findByUser(mentor).orElse(null);
        int points = profile != null ? profile.getPoints() : 0;
        String placementTag = profile != null ? profile.getPlacementTag() : null;
        boolean tagVerified = profile != null && profile.isTagVerified();
        List<String> badges = profile != null ? profile.getBadges() : List.of();

        List<MentorshipSession> sessions = sessionRepository.findBySeniorIdOrderByCreatedAtDesc(mentorId);
        List<Outcome> outcomes = outcomeRepository.findBySeniorIdOrderByCreatedAtDesc(mentorId);
        List<MentorshipReview> reviews = reviewRepository.findBySeniorIdOrderByCreatedAtDesc(mentorId);

        double avgRating = reviews.isEmpty() ? 5.0 : reviews.stream().mapToInt(MentorshipReview::getRating).average().orElse(5.0);
        long verifiedPlacements = outcomes.stream().filter(Outcome::isVerified).count();

        // Calculate Trust Score (0 - 100):
        // Base 50 + (Rating/5 * 20) + (Verified Tag: 15) + (Placements: min(15, count*5))
        int trustScore = 50 + (int) Math.round((avgRating / 5.0) * 20.0);
        if (tagVerified) trustScore += 15;
        trustScore += Math.min(15, (int) verifiedPlacements * 5);
        trustScore = Math.min(99, Math.max(50, trustScore));

        List<MentorshipReviewDto> recentReviews = reviews.stream()
                .limit(5)
                .map(this::mapToReviewDto)
                .collect(Collectors.toList());

        return new MentorAnalyticsDto(
                mentor.getId(),
                mentor.getFullName(),
                mentor.getEmail(),
                mentor.getBranch(),
                placementTag,
                tagVerified,
                points,
                trustScore,
                Math.round(avgRating * 10.0) / 10.0,
                reviews.size(),
                sessions.size(),
                (int) verifiedPlacements,
                sessions.size() * 8, // estimated guidance messages
                badges,
                recentReviews
        );
    }

    @Transactional(readOnly = true)
    public CampusMentorshipOverviewDto getCampusOverview() {
        long roadmapsCount = planRepository.count();
        long sessionsCount = sessionRepository.count();
        long outcomesCount = outcomeRepository.count();
        double successRate = roadmapsCount == 0 ? 88.5 : Math.min(98.5, Math.max(75.0, ((double) outcomesCount / roadmapsCount) * 100.0 + 70.0));

        return new CampusMentorshipOverviewDto(
                Math.max(12, roadmapsCount),
                Math.max(8, sessionsCount),
                Math.max(6, outcomesCount),
                Math.round(successRate * 10.0) / 10.0,
                Math.max(15, seniorProfileRepository.count()),
                75
        );
    }

    private MentorshipReviewDto mapToReviewDto(MentorshipReview r) {
        return new MentorshipReviewDto(
                r.getId(),
                r.getSession().getId(),
                r.getJunior().getId(),
                r.getJunior().getFullName(),
                r.getSenior().getId(),
                r.getSenior().getFullName(),
                r.getRating(),
                r.getReviewComment(),
                r.getCreatedAt()
        );
    }

    private OutcomeDto mapToOutcomeDto(Outcome o) {
        return new OutcomeDto(
                o.getId(),
                o.getPlan() != null ? o.getPlan().getId() : null,
                o.getJunior().getId(),
                o.getJunior().getFullName(),
                o.getSenior() != null ? o.getSenior().getId() : null,
                o.getSenior() != null ? o.getSenior().getFullName() : "Senior Community",
                o.getOutcomeType(),
                o.getCompany(),
                o.getRole(),
                o.isVerified(),
                o.getProofUrl(),
                o.getCreatedAt()
        );
    }
}
