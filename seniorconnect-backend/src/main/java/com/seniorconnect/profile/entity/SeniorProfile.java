package com.seniorconnect.profile.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
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

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "tags", columnDefinition = "text[]")
    private List<String> tags = new ArrayList<>();

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "badges", columnDefinition = "text[]")
    private List<String> badges = new ArrayList<>();

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
        this.tags = new ArrayList<>();
        if (placementTag != null && !placementTag.isBlank()) {
            this.tags.add(placementTag);
        }
        this.badges = new ArrayList<>();
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
        if (tags == null) {
            tags = new ArrayList<>();
        }
        if (badges == null) {
            badges = new ArrayList<>();
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
        if (placementTag != null && !placementTag.isBlank()) {
            if (tags == null) tags = new ArrayList<>();
            if (!tags.contains(placementTag)) {
                tags.add(placementTag);
            }
        }
    }

    public List<String> getTags() {
        if (tags == null) tags = new ArrayList<>();
        return tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags != null ? tags : new ArrayList<>();
    }

    public List<String> getBadges() {
        if (badges == null) badges = new ArrayList<>();
        return badges;
    }

    public void setBadges(List<String> badges) {
        this.badges = badges != null ? badges : new ArrayList<>();
    }

    public void addBadge(String badge) {
        if (badge == null || badge.isBlank()) return;
        if (badges == null) badges = new ArrayList<>();
        if (!badges.contains(badge)) {
            badges.add(badge);
        }
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
