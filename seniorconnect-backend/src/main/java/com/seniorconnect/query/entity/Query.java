package com.seniorconnect.query.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Entity
@Table(name = "queries")
public class Query {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "junior_id", nullable = false)
    private User junior;

    @Column(name = "title", nullable = false, length = 300)
    private String title;

    @Column(name = "content", nullable = false, length = 5000)
    private String content;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "tags", columnDefinition = "text[]")
    private List<String> tags = new ArrayList<>();

    @Column(name = "is_anonymous_display", nullable = false)
    private boolean isAnonymousDisplay = true;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private QueryStatus status = QueryStatus.OPEN;

    @OneToMany(mappedBy = "query", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Response> responses = new ArrayList<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    public Query() {
    }

    public Query(UUID id, User junior, String title, String content, String tags, boolean isAnonymousDisplay, QueryStatus status, Instant createdAt, Instant updatedAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.junior = junior;
        this.title = title;
        this.content = content;
        this.tags = parseTags(tags);
        this.isAnonymousDisplay = isAnonymousDisplay;
        this.status = status != null ? status : QueryStatus.OPEN;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt;
    }

    public Query(UUID id, User junior, String title, String content, List<String> tags, boolean isAnonymousDisplay, QueryStatus status, Instant createdAt, Instant updatedAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.junior = junior;
        this.title = title;
        this.content = content;
        this.tags = tags != null ? tags : new ArrayList<>();
        this.isAnonymousDisplay = isAnonymousDisplay;
        this.status = status != null ? status : QueryStatus.OPEN;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt;
    }

    private static List<String> parseTags(String raw) {
        if (raw == null || raw.isBlank()) return new ArrayList<>();
        return Arrays.stream(raw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
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
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getJunior() {
        return junior;
    }

    public void setJunior(User junior) {
        this.junior = junior;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getTags() {
        if (tags == null || tags.isEmpty()) return "";
        return String.join(",", tags);
    }

    public List<String> getTagsList() {
        if (tags == null) tags = new ArrayList<>();
        return tags;
    }

    public void setTags(String tags) {
        this.tags = parseTags(tags);
    }

    public void setTagsList(List<String> tags) {
        this.tags = tags != null ? tags : new ArrayList<>();
    }

    public boolean isAnonymousDisplay() {
        return isAnonymousDisplay;
    }

    public void setAnonymousDisplay(boolean anonymousDisplay) {
        isAnonymousDisplay = anonymousDisplay;
    }

    public QueryStatus getStatus() {
        return status;
    }

    public void setStatus(QueryStatus status) {
        this.status = status;
    }

    public List<Response> getResponses() {
        return responses;
    }

    public void setResponses(List<Response> responses) {
        this.responses = responses;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
