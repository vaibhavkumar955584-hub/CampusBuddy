package com.seniorconnect.mentorship.entity;

import com.seniorconnect.query.entity.Query;
import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "mentorship_sessions")
public class MentorshipSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "junior_id", nullable = false)
    private User junior;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "senior_id", nullable = false)
    private User senior;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "query_id")
    private Query query;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_id")
    private MentorshipPlan plan;

    @Column(nullable = false, length = 32)
    private String status = "ACTIVE"; // ACTIVE, COMPLETED, ARCHIVED

    private int privacyLevel = 3; // Privacy Level 3: Direct Mentorship

    @Column(length = 500)
    private String meetingLink;

    @Column(length = 1000)
    private String sessionNotes;

    private Instant scheduledAt;
    private Instant createdAt = Instant.now();

    public MentorshipSession() {}

    public MentorshipSession(User junior, User senior, Query query, MentorshipPlan plan) {
        this.junior = junior;
        this.senior = senior;
        this.query = query;
        this.plan = plan;
        this.status = "ACTIVE";
        this.privacyLevel = 3;
    }

    public UUID getId() { return id; }
    public User getJunior() { return junior; }
    public void setJunior(User junior) { this.junior = junior; }
    public User getSenior() { return senior; }
    public void setSenior(User senior) { this.senior = senior; }
    public Query getQuery() { return query; }
    public void setQuery(Query query) { this.query = query; }
    public MentorshipPlan getPlan() { return plan; }
    public void setPlan(MentorshipPlan plan) { this.plan = plan; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public int getPrivacyLevel() { return privacyLevel; }
    public void setPrivacyLevel(int privacyLevel) { this.privacyLevel = privacyLevel; }
    public String getMeetingLink() { return meetingLink; }
    public void setMeetingLink(String meetingLink) { this.meetingLink = meetingLink; }
    public String getSessionNotes() { return sessionNotes; }
    public void setSessionNotes(String sessionNotes) { this.sessionNotes = sessionNotes; }
    public Instant getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(Instant scheduledAt) { this.scheduledAt = scheduledAt; }
    public Instant getCreatedAt() { return createdAt; }
}
