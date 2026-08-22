package com.seniorconnect.reveal.repository;

import com.seniorconnect.query.entity.Query;
import com.seniorconnect.reveal.entity.RevealRequest;
import com.seniorconnect.reveal.entity.RevealStatus;
import com.seniorconnect.user.entity.User;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RevealRequestRepository extends JpaRepository<RevealRequest, UUID> {

    Optional<RevealRequest> findByQueryAndSenior(Query query, User senior);

    @Lock(LockModeType.PESSIMISTIC_READ)
    @org.springframework.data.jpa.repository.Query("SELECT r FROM RevealRequest r WHERE r.query.id = :queryId AND r.senior.id = :seniorId")
    Optional<RevealRequest> findByQueryIdAndSeniorIdForShare(@Param("queryId") UUID queryId, @Param("seniorId") UUID seniorId);

    List<RevealRequest> findByJuniorAndStatus(User junior, RevealStatus status);

    List<RevealRequest> findBySeniorOrderByCreatedAtDesc(User senior);

    boolean existsByQueryAndSeniorAndStatus(Query query, User senior, RevealStatus status);
}
