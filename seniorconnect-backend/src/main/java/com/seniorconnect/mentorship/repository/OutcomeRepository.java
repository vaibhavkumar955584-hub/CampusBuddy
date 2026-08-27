package com.seniorconnect.mentorship.repository;

import com.seniorconnect.mentorship.entity.Outcome;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OutcomeRepository extends JpaRepository<Outcome, UUID> {
    List<Outcome> findByJuniorIdOrderByCreatedAtDesc(UUID juniorId);
    List<Outcome> findBySeniorIdOrderByCreatedAtDesc(UUID seniorId);
    List<Outcome> findByIsVerifiedTrue();
}
