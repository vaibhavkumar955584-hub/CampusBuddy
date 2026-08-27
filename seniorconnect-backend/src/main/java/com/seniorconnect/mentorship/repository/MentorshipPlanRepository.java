package com.seniorconnect.mentorship.repository;

import com.seniorconnect.mentorship.entity.MentorshipPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MentorshipPlanRepository extends JpaRepository<MentorshipPlan, UUID> {
    List<MentorshipPlan> findByJuniorIdOrderByCreatedAtDesc(UUID juniorId);
    List<MentorshipPlan> findBySeniorIdOrderByCreatedAtDesc(UUID seniorId);
}
