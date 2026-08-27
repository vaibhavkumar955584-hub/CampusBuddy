package com.seniorconnect.mentorship.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "mentorship_outcomes")
public class Outcome {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_id")
    private MentorshipPlan plan;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "junior_id", nullable = false)
    private User junior;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "senior_id")
    private User senior;

    @Column(nullable = false, length = 50)
    private String outcomeType; // INTERNSHIP_RECEIVED, PLACEMENT_RECEIVED, INTERVIEW_CLEARED, SKILL_IMPROVED

    @Column(length = 100)
    private String company;

    @Column(length = 100)
    private String role;

    private boolean isVerified = false;

    @Column(length = 500)
    private String proofUrl;

    private Instant createdAt = Instant.now();

    public Outcome() {}

    public Outcome(User junior, User senior, MentorshipPlan plan, String outcomeType, String company, String role) {
        this.junior = junior;
        this.senior = senior;
        this.plan = plan;
        this.outcomeType = outcomeType;
        this.company = company;
        this.role = role;
        this.isVerified = false;
    }

    public UUID getId() { return id; }
    public MentorshipPlan getPlan() { return plan; }
    public User getJunior() { return junior; }
    public User getSenior() { return senior; }
    public String getOutcomeType() { return outcomeType; }
    public String getCompany() { return company; }
    public String getRole() { return role; }
    public boolean isVerified() { return isVerified; }
    public void setVerified(boolean verified) { isVerified = verified; }
    public String getProofUrl() { return proofUrl; }
    public void setProofUrl(String proofUrl) { this.proofUrl = proofUrl; }
    public Instant getCreatedAt() { return createdAt; }
}
