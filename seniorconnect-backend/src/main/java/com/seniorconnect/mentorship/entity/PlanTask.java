package com.seniorconnect.mentorship.entity;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "mentorship_plan_tasks")
public class PlanTask {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_id", nullable = false)
    private MentorshipPlan plan;

    private int weekNumber;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 1000)
    private String description;

    private boolean isCompleted = false;

    public PlanTask() {}

    public PlanTask(MentorshipPlan plan, int weekNumber, String title, String description) {
        this.plan = plan;
        this.weekNumber = weekNumber;
        this.title = title;
        this.description = description;
        this.isCompleted = false;
    }

    public UUID getId() { return id; }
    public MentorshipPlan getPlan() { return plan; }
    public void setPlan(MentorshipPlan plan) { this.plan = plan; }
    public int getWeekNumber() { return weekNumber; }
    public void setWeekNumber(int weekNumber) { this.weekNumber = weekNumber; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public boolean isCompleted() { return isCompleted; }
    public void setCompleted(boolean completed) { isCompleted = completed; }
}
