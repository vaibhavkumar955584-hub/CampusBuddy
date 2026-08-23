package com.seniorconnect.user.repository;

import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    List<User> findByRole(Role role);
    List<User> findByRoleAndBranch(Role role, String branch);

    @Query(value = """
        SELECT DISTINCT u.* FROM users u 
        JOIN senior_profiles sp ON sp.user_id = u.id 
        WHERE (u.role = 'SENIOR' OR (u.role = 'JUNIOR' AND u.mentor_mode_active = true)) 
          AND u.is_suspended = false 
          AND (
              sp.tags && CAST(:queryTags AS text[]) 
              OR (CAST(:branch AS text) IS NOT NULL AND u.branch = :branch)
          )
    """, nativeQuery = true)
    List<User> findCandidateSeniorsNative(@Param("queryTags") String[] queryTags, @Param("branch") String branch);

    @Query("""
        SELECT u FROM User u 
        WHERE (u.role = com.seniorconnect.user.model.Role.SENIOR OR (u.role = com.seniorconnect.user.model.Role.JUNIOR AND u.mentorModeActive = true)) 
          AND u.isSuspended = false 
          AND (:branch IS NULL OR u.branch = :branch)
    """)
    List<User> findActiveSeniorsByBranch(@Param("branch") String branch);
}
