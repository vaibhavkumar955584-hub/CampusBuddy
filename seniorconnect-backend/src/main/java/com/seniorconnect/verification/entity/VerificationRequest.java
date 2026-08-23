package com.seniorconnect.verification.entity;

import com.seniorconnect.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "verification_requests")
public class VerificationRequest {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "senior_id", nullable = false)
    private User senior;

    @Column(name = "claimed_tag", nullable = false, columnDefinition = "text")
    private String claimedTag;

    @Column(name = "proof_file_url", nullable = false, columnDefinition = "text")
    private String proofFileUrl;

    @Column(name = "ocr_extracted_text", columnDefinition = "text")
    private String ocrExtractedText;

    @Column(name = "ocr_keyword_match")
    private Boolean ocrKeywordMatch;

    @Column(name = "ocr_confidence_score")
    private Double ocrConfidenceScore;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 32)
    private VerificationStatus status = VerificationStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    @Column(name = "reviewed_at")
    private Instant reviewedAt;

    @Column(name = "rejection_reason", columnDefinition = "text")
    private String rejectionReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public VerificationRequest() {
    }

    public VerificationRequest(
            UUID id,
            User senior,
            String claimedTag,
            String proofFileUrl,
            String ocrExtractedText,
            Boolean ocrKeywordMatch,
            Double ocrConfidenceScore,
            VerificationStatus status,
            Instant createdAt
    ) {
        this.id = id != null ? id : UUID.randomUUID();
        this.senior = senior;
        this.claimedTag = claimedTag;
        this.proofFileUrl = proofFileUrl;
        this.ocrExtractedText = ocrExtractedText;
        this.ocrKeywordMatch = ocrKeywordMatch;
        this.ocrConfidenceScore = ocrConfidenceScore;
        this.status = status != null ? status : VerificationStatus.PENDING;
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
        if (status == null) {
            status = VerificationStatus.PENDING;
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getSenior() {
        return senior;
    }

    public void setSenior(User senior) {
        this.senior = senior;
    }

    public String getClaimedTag() {
        return claimedTag;
    }

    public void setClaimedTag(String claimedTag) {
        this.claimedTag = claimedTag;
    }

    public String getProofFileUrl() {
        return proofFileUrl;
    }

    public void setProofFileUrl(String proofFileUrl) {
        this.proofFileUrl = proofFileUrl;
    }

    public String getOcrExtractedText() {
        return ocrExtractedText;
    }

    public void setOcrExtractedText(String ocrExtractedText) {
        this.ocrExtractedText = ocrExtractedText;
    }

    public Boolean getOcrKeywordMatch() {
        return ocrKeywordMatch;
    }

    public void setOcrKeywordMatch(Boolean ocrKeywordMatch) {
        this.ocrKeywordMatch = ocrKeywordMatch;
    }

    public Double getOcrConfidenceScore() {
        return ocrConfidenceScore;
    }

    public void setOcrConfidenceScore(Double ocrConfidenceScore) {
        this.ocrConfidenceScore = ocrConfidenceScore;
    }

    public VerificationStatus getStatus() {
        return status;
    }

    public void setStatus(VerificationStatus status) {
        this.status = status;
    }

    public User getReviewedBy() {
        return reviewedBy;
    }

    public void setReviewedBy(User reviewedBy) {
        this.reviewedBy = reviewedBy;
    }

    public Instant getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(Instant reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public String getRejectionReason() {
        return rejectionReason;
    }

    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
