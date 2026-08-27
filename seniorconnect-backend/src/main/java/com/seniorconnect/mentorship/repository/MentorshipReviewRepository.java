package com.seniorconnect.mentorship.repository;

import com.seniorconnect.mentorship.entity.MentorshipReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MentorshipReviewRepository extends JpaRepository<MentorshipReview, UUID> {
    List<MentorshipReview> findBySeniorIdOrderByCreatedAtDesc(UUID seniorId);
    Optional<MentorshipReview> findBySessionId(UUID sessionId);
}
