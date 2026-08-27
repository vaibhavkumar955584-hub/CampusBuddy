package com.seniorconnect.mentorship.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "mentorship_reviews")
public class MentorshipReview {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private MentorshipSession session;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "junior_id", nullable = false)
    private User junior;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "senior_id", nullable = false)
    private User senior;

    @Column(nullable = false)
    private int rating; // 1 to 5

    @Column(length = 1000)
    private String reviewComment;

    private boolean isPublic = true;
    private Instant createdAt = Instant.now();

    public MentorshipReview() {}

    public MentorshipReview(MentorshipSession session, User junior, User senior, int rating, String reviewComment) {
        this.session = session;
        this.junior = junior;
        this.senior = senior;
        this.rating = Math.max(1, Math.min(5, rating));
        this.reviewComment = reviewComment;
        this.isPublic = true;
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public MentorshipSession getSession() { return session; }
    public void setSession(MentorshipSession session) { this.session = session; }
    public User getJunior() { return junior; }
    public void setJunior(User junior) { this.junior = junior; }
    public User getSenior() { return senior; }
    public void setSenior(User senior) { this.senior = senior; }
    public int getRating() { return rating; }
    public void setRating(int rating) { this.rating = Math.max(1, Math.min(5, rating)); }
    public String getReviewComment() { return reviewComment; }
    public void setReviewComment(String reviewComment) { this.reviewComment = reviewComment; }
    public boolean isPublic() { return isPublic; }
    public void setPublic(boolean isPublic) { this.isPublic = isPublic; }
    public Instant getCreatedAt() { return createdAt; }
}
