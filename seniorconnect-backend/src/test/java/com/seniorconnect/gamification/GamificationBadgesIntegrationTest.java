package com.seniorconnect.gamification;

import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.gamification.config.BadgeConfig;
import com.seniorconnect.profile.dto.SeniorProfileDto;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.profile.service.SeniorProfileService;
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
public class GamificationBadgesIntegrationTest {

    @Autowired
    private SeniorProfileService seniorProfileService;

    @Autowired
    private SeniorProfileRepository seniorProfileRepository;

    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("Gap 4 Evidence: Badges column exists, evaluates criteria, and appends to real database row")
    void testGamificationBadgesAwardFlow() {
        // 1. Create Senior user
        User senior = userRepository.save(new User(
                UUID.randomUUID(),
                "senior.badge.test@galgotiacollege.edu.in",
                "Badge Tester Senior",
                Role.SENIOR,
                "CSE",
                7,
                false,
                Instant.now(),
                null
        ));

        // Create Admin user for verification
        User admin = userRepository.save(new User(
                UUID.randomUUID(),
                "admin.badge@galgotiacollege.edu.in",
                "Admin Verifier",
                Role.ADMIN,
                "ADMIN",
                null,
                false,
                Instant.now(),
                null
        ));

        // 2. Initial state: Profile created with 0 points and empty badges
        SeniorProfile initialProfile = seniorProfileService.getOrCreateProfile(senior);
        assertNotNull(initialProfile.getBadges(), "Badges collection should not be null");
        assertTrue(initialProfile.getBadges().isEmpty(), "Initial profile should have no badges");

        // 3. Trigger 1st milestone: Award 1 point for first response
        seniorProfileService.addPoints(senior, 1);

        SeniorProfile dbRowAfter1Pt = seniorProfileRepository.findByUser(senior).orElseThrow();
        assertEquals(1, dbRowAfter1Pt.getPoints());
        assertTrue(dbRowAfter1Pt.getBadges().contains(BadgeConfig.FIRST_RESPONSE),
                "Database row must contain 'First Response' badge after 1 point");

        // 4. Trigger 2nd milestone: Award 10 points for '10 Helped'
        seniorProfileService.addPoints(senior, 9); // Total: 10
        SeniorProfile dbRowAfter10Pts = seniorProfileRepository.findByUser(senior).orElseThrow();
        assertEquals(10, dbRowAfter10Pts.getPoints());
        assertTrue(dbRowAfter10Pts.getBadges().contains(BadgeConfig.MENTOR_10),
                "Database row must contain '10 Helped' badge after 10 points");

        // 5. Trigger 3rd milestone: Admin verifies credentials for 'Verified Mentor'
        UserPrincipal adminPrincipal = new UserPrincipal(admin.getId(), admin.getEmail(), admin.getRole(), false);
        dbRowAfter10Pts.setPlacementTag("Google SDE-1");
        seniorProfileRepository.save(dbRowAfter10Pts);

        SeniorProfileDto verifiedDto = seniorProfileService.verifyTagByAdmin(senior.getId(), true, adminPrincipal, "127.0.0.1");
        assertTrue(verifiedDto.isTagVerified());
        assertTrue(verifiedDto.badges().contains(BadgeConfig.VERIFIED_MENTOR),
                "DTO must contain 'Verified Mentor' badge after admin tag verification");

        // 6. Trigger 4th milestone: Award 40 points (Total 50) for 'Top Contributor'
        seniorProfileService.addPoints(senior, 40);
        SeniorProfile finalDbRow = seniorProfileRepository.findByUser(senior).orElseThrow();
        assertEquals(50, finalDbRow.getPoints());
        assertTrue(finalDbRow.getBadges().contains(BadgeConfig.TOP_CONTRIBUTOR),
                "Database row must contain 'Top Contributor' badge after 50 points");

        // Verify all 4 badges persisted in the real DB row
        List<String> finalBadges = finalDbRow.getBadges();
        assertEquals(4, finalBadges.size());
        assertTrue(finalBadges.containsAll(List.of(
                BadgeConfig.FIRST_RESPONSE,
                BadgeConfig.MENTOR_10,
                BadgeConfig.VERIFIED_MENTOR,
                BadgeConfig.TOP_CONTRIBUTOR
        )));

        System.out.println("=== GAP 4 GAMIFICATION BADGES EVIDENCE ===");
        System.out.println("Senior User ID: " + senior.getId());
        System.out.println("Total Points: " + finalDbRow.getPoints());
        System.out.println("Persisted Badges Array (Real DB Row): " + finalBadges);
        System.out.println("Verified Status: " + finalDbRow.isTagVerified());
        System.out.println("=========================================");
    }
}
