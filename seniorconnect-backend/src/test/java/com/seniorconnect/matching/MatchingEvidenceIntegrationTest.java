package com.seniorconnect.matching;

import com.seniorconnect.matching.service.MatchingService;
import com.seniorconnect.profile.service.SeniorProfileService;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.QueryStatus;
import com.seniorconnect.query.repository.QueryRepository;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class MatchingEvidenceIntegrationTest {

    @Autowired
    private MatchingService matchingService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SeniorProfileService seniorProfileService;

    @Autowired
    private QueryRepository queryRepository;

    @Test
    @DisplayName("Phase 5 Matching Evidence: Query tags match relevant seniors with verified credentials ranked first")
    void testTagMatchingAndRanking() {
        // Create Junior
        User junior = userRepository.save(new User(
                UUID.randomUUID(), "junior.match@galgotiacollege.edu.in", "Junior Matcher",
                Role.JUNIOR, "CSE", 3, false, Instant.now(), null
        ));

        // Create Senior 1 (Google Placed - Verified)
        User seniorGoogle = userRepository.save(new User(
                UUID.randomUUID(), "senior.google@galgotiacollege.edu.in", "Google Senior",
                Role.SENIOR, "CSE", 8, false, Instant.now(), null
        ));
        seniorProfileService.addPoints(seniorGoogle, 50);
        var p1 = seniorProfileService.getOrCreateProfile(seniorGoogle);
        p1.setPlacementTag("Placed@Google");
        p1.setTagVerified(true);

        // Create Senior 2 (General Senior)
        User seniorGeneral = userRepository.save(new User(
                UUID.randomUUID(), "senior.gen@galgotiacollege.edu.in", "General Senior",
                Role.SENIOR, "ECE", 7, false, Instant.now(), null
        ));
        seniorProfileService.addPoints(seniorGeneral, 5);

        // Create Query with tags "google,placement,dsa"
        Query query = queryRepository.save(new Query(
                UUID.randomUUID(), junior, "Google Interview Preparation",
                "How to crack Google SWE intern interview?", "google,placement,dsa",
                true, QueryStatus.OPEN, Instant.now(), null
        ));

        // Execute matching algorithm
        List<User> matchedSeniors = matchingService.matchSeniorsForQuery(query);

        assertNotNull(matchedSeniors);
        assertFalse(matchedSeniors.isEmpty());
        // Verify that seniorGoogle is ranked first because of tag overlap ('google') and verified placement
        assertEquals(seniorGoogle.getId(), matchedSeniors.get(0).getId(), "Verified Google senior must be matched at top rank");
        System.out.println("=== MATCHING EVIDENCE LOG ===");
        System.out.println("Query: " + query.getTitle() + " [Tags: " + query.getTags() + "]");
        for (int i = 0; i < matchedSeniors.size(); i++) {
            System.out.println("Rank #" + (i + 1) + ": " + matchedSeniors.get(i).getFullName() + " (" + matchedSeniors.get(i).getEmail() + ")");
        }
        System.out.println("=============================");
    }
}
