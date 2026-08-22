package com.seniorconnect.profile.repository;

import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SeniorProfileRepository extends JpaRepository<SeniorProfile, UUID> {
    Optional<SeniorProfile> findByUser(User user);
    Optional<SeniorProfile> findByUserId(UUID userId);

    @Query("""
        SELECT sp FROM SeniorProfile sp 
        JOIN FETCH sp.user u 
        WHERE u.role = com.seniorconnect.user.model.Role.SENIOR 
          AND u.isSuspended = false 
          AND (:branch IS NULL OR u.branch = :branch)
    """)
    List<SeniorProfile> findCandidateProfilesByBranch(@Param("branch") String branch);

    @Query(value = """
        SELECT DISTINCT sp.* FROM senior_profiles sp 
        JOIN users u ON u.id = sp.user_id 
        WHERE u.role = 'SENIOR' 
          AND u.is_suspended = false 
          AND sp.tags && string_to_array(:queryTagsCsv, ',')
    """, nativeQuery = true)
    List<SeniorProfile> findMatchingProfilesNative(@Param("queryTagsCsv") String queryTagsCsv);
}
