package com.seniorconnect.verification.repository;

import com.seniorconnect.verification.entity.VerificationRequest;
import com.seniorconnect.verification.entity.VerificationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VerificationRequestRepository extends JpaRepository<VerificationRequest, UUID> {

    List<VerificationRequest> findBySeniorIdOrderByCreatedAtDesc(UUID seniorId);

    Optional<VerificationRequest> findFirstBySeniorIdAndClaimedTagOrderByCreatedAtDesc(UUID seniorId, String claimedTag);

    @Query("""
        SELECT vr FROM VerificationRequest vr 
        JOIN FETCH vr.senior s 
        WHERE (:status IS NULL OR vr.status = :status) 
        ORDER BY 
            CASE WHEN vr.ocrKeywordMatch = true THEN 0 ELSE 1 END ASC,
            vr.createdAt DESC
    """)
    Page<VerificationRequest> findByStatusWithTriageSorting(@Param("status") VerificationStatus status, Pageable pageable);
}
