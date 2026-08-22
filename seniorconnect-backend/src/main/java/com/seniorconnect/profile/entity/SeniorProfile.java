package com.seniorconnect.profile.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "senior_profiles")
public class SeniorProfile {

    @Id
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "points", nullable = false)
    private int points = 0;

    @Column(name = "placement_tag", length = 255)
    private String placementTag;

    @Column(name = "is_tag_verified", nullable = false)
    private boolean isTagVerified = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public SeniorProfile() {
    }

    public SeniorProfile(UUID id, User user, int points, String placementTag, boolean isTagVerified, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.user = user;
        this.points = points;
        this.placementTag = placementTag;
        this.isTagVerified = isTagVerified;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    @PrePersist
    protected void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public int getPoints() {
        return points;
    }

    public void setPoints(int points) {
        this.points = points;
    }

    public String getPlacementTag() {
        return placementTag;
    }

    public void setPlacementTag(String placementTag) {
        this.placementTag = placementTag;
    }

    public boolean isTagVerified() {
        return isTagVerified;
    }

    public void setTagVerified(boolean tagVerified) {
        isTagVerified = tagVerified;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
