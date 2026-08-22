package com.seniorconnect.moderation.repository;

import com.seniorconnect.moderation.entity.Report;
import com.seniorconnect.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface ReportRepository extends JpaRepository<Report, UUID> {

    @Query("SELECT COUNT(r) FROM Report r WHERE r.reportedUser = :user AND r.createdAt >= :since")
    long countReportsForUserSince(@Param("user") User user, @Param("since") Instant since);

    List<Report> findByStatusOrderByCreatedAtDesc(String status);
}
