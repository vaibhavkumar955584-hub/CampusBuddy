package com.seniorconnect.user.repository;

import com.seniorconnect.user.entity.AllowedDomain;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AllowedDomainRepository extends JpaRepository<AllowedDomain, UUID> {
    Optional<AllowedDomain> findByDomainAndIsActiveTrue(String domain);
    boolean existsByDomainAndIsActiveTrue(String domain);
}
