package com.seniorconnect.query.repository;

import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.Response;
import com.seniorconnect.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ResponseRepository extends JpaRepository<Response, UUID> {
    List<Response> findByQueryOrderByCreatedAtAsc(Query query);
    List<Response> findBySeniorOrderByCreatedAtDesc(User senior);
    boolean existsByQueryAndSenior(Query query, User senior);
}
