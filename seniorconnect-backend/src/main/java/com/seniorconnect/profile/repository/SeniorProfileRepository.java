package com.seniorconnect.profile.repository;

import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SeniorProfileRepository extends JpaRepository<SeniorProfile, UUID> {
    Optional<SeniorProfile> findByUser(User user);
    Optional<SeniorProfile> findByUserId(UUID userId);
}
