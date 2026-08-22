package com.seniorconnect.query.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "responses")
public class Response {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "query_id", nullable = false)
    private Query query;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "senior_id", nullable = false)
    private User senior;

    @Column(name = "content", nullable = false, length = 5000)
    private String content;

    @Column(name = "is_accepted_answer", nullable = false)
    private boolean isAcceptedAnswer = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    public Response() {
    }

    public Response(UUID id, Query query, User senior, String content, boolean isAcceptedAnswer, Instant createdAt, Instant updatedAt) {
        this.id = id != null ? id : UUID.randomUUID();
        this.query = query;
        this.senior = senior;
        this.content = content;
        this.isAcceptedAnswer = isAcceptedAnswer;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt;
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

    public Query getQuery() {
        return query;
    }

    public void setQuery(Query query) {
        this.query = query;
    }

    public User getSenior() {
        return senior;
    }

    public void setSenior(User senior) {
        this.senior = senior;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public boolean isAcceptedAnswer() {
        return isAcceptedAnswer;
    }

    public void setAcceptedAnswer(boolean acceptedAnswer) {
        isAcceptedAnswer = acceptedAnswer;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
