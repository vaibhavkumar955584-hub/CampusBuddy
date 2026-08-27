package com.seniorconnect.mentorship.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "mentorship_plans")
public class MentorshipPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "junior_id", nullable = false)
    private User junior;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "senior_id")
    private User senior;

    @Column(nullable = false, length = 200)
    private String goalTitle;

    @Column(length = 100)
    private String targetCompany;

    @Column(length = 100)
    private String targetRole;

    private int durationDays = 90;

    @Column(nullable = false, length = 30)
    private String status = "ACTIVE"; // ACTIVE, COMPLETED, PAUSED

    private int progressPercentage = 0;

    @OneToMany(mappedBy = "plan", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PlanTask> tasks = new ArrayList<>();

    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    public MentorshipPlan() {}

    public MentorshipPlan(User junior, User senior, String goalTitle, String targetCompany, String targetRole, int durationDays) {
        this.junior = junior;
        this.senior = senior;
        this.goalTitle = goalTitle;
        this.targetCompany = targetCompany;
        this.targetRole = targetRole;
        this.durationDays = durationDays;
        this.status = "ACTIVE";
    }

    public UUID getId() { return id; }
    public User getJunior() { return junior; }
    public void setJunior(User junior) { this.junior = junior; }
    public User getSenior() { return senior; }
    public void setSenior(User senior) { this.senior = senior; }
    public String getGoalTitle() { return goalTitle; }
    public void setGoalTitle(String goalTitle) { this.goalTitle = goalTitle; }
    public String getTargetCompany() { return targetCompany; }
    public void setTargetCompany(String targetCompany) { this.targetCompany = targetCompany; }
    public String getTargetRole() { return targetRole; }
    public void setTargetRole(String targetRole) { this.targetRole = targetRole; }
    public int getDurationDays() { return durationDays; }
    public void setDurationDays(int durationDays) { this.durationDays = durationDays; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public int getProgressPercentage() { return progressPercentage; }
    public void setProgressPercentage(int progressPercentage) { this.progressPercentage = progressPercentage; }
    public List<PlanTask> getTasks() { return tasks; }
    public void setTasks(List<PlanTask> tasks) { this.tasks = tasks; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
