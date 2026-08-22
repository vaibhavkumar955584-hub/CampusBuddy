package com.seniorconnect.query.repository;

import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.QueryStatus;
import com.seniorconnect.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface QueryRepository extends JpaRepository<Query, UUID> {

    Page<Query> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<Query> findByStatusOrderByCreatedAtDesc(QueryStatus status, Pageable pageable);

    List<Query> findByJuniorOrderByCreatedAtDesc(User junior);

    @org.springframework.data.jpa.repository.Query("SELECT q FROM Query q WHERE LOWER(q.tags) LIKE LOWER(CONCAT('%', :tag, '%')) ORDER BY q.createdAt DESC")
    Page<Query> findByTagContaining(@Param("tag") String tag, Pageable pageable);
}
