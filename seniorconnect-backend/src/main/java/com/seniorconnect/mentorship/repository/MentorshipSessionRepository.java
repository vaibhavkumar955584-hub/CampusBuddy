package com.seniorconnect.mentorship.repository;

import com.seniorconnect.mentorship.entity.MentorshipSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MentorshipSessionRepository extends JpaRepository<MentorshipSession, UUID> {
    List<MentorshipSession> findByJuniorIdOrderByCreatedAtDesc(UUID juniorId);
    List<MentorshipSession> findBySeniorIdOrderByCreatedAtDesc(UUID seniorId);
    Optional<MentorshipSession> findByJuniorIdAndSeniorId(UUID juniorId, UUID seniorId);
}
