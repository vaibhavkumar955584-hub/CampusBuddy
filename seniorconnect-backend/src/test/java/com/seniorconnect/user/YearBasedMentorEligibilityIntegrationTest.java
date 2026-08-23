package com.seniorconnect.user;

import com.seniorconnect.auth.dto.VerifyOtpRequest;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.auth.service.AuthService;
import com.seniorconnect.auth.service.OtpService;
import com.seniorconnect.matching.service.MatchingService;
import com.seniorconnect.notification.service.NotificationService;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.profile.service.SeniorProfileService;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.entity.QueryStatus;
import com.seniorconnect.query.repository.QueryRepository;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import com.seniorconnect.user.service.YearOfStudyService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@SpringBootTest
@ActiveProfiles("test")
public class YearBasedMentorEligibilityIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SeniorProfileRepository seniorProfileRepository;

    @Autowired
    private QueryRepository queryRepository;

    @Autowired
    private YearOfStudyService yearOfStudyService;

    @Autowired
    private AuthService authService;

    @Autowired
    private OtpService otpService;

    @Autowired
    private SeniorProfileService seniorProfileService;

    @Autowired
    private MatchingService matchingService;

    @MockBean
    private NotificationService notificationService;

    @Test
    @DisplayName("Evidence 1 & 3: JUNIOR user with Year 3+ advances to mentorEligible=true without role mutation, notifying exactly once")
    void testJuniorProgressionAndOneTimeNotification() {
        // Reset mock
        reset(notificationService);
        when(notificationService.sendGenericNotification(any(), any(), any())).thenReturn(true);

        String email = "rahul.23gcebit101@galgotiacollege.edu";
        UUID userId = UUID.randomUUID();

        // 1. Seed JUNIOR user with admission year 2023 (evaluates to Year 3+ in 2026)
        User juniorUser = new User(
                userId,
                email,
                "Rahul Sharma",
                Role.JUNIOR,
                "Information Technology",
                5,
                null,
                false,
                false,
                2023,
                false,
                Instant.now(),
                null
        );
        userRepository.save(juniorUser);

        // 2. Perform login verification flow (triggers login-time recalculation)
        String testOtp = otpService.generateAndSaveOtp(email, "127.0.0.1");
        assertNotNull(testOtp, "Generated OTP must not be null");

        authService.verifyOtpAndLogin(
                new VerifyOtpRequest(email, testOtp, "test-device-fp"),
                Role.JUNIOR,
                "Rahul Sharma",
                "Information Technology",
                5,
                "127.0.0.1"
        );

        // 3. Read directly from DB to prove state
        User updatedUser = userRepository.findById(userId).orElseThrow();
        assertEquals(Role.JUNIOR, updatedUser.getRole(), "Role must strictly remain JUNIOR throughout natural progression");
        assertTrue(updatedUser.isMentorEligible(), "mentorEligible must flip to TRUE for Year 3+ junior");
        assertFalse(updatedUser.isMentorModeActive(), "mentorModeActive must default to FALSE until explicit user opt-in");
        assertTrue(updatedUser.getCurrentYearOfStudy() >= 3, "currentYearOfStudy must be >= 3");

        System.out.println("=== EVIDENCE 1: REAL DB RECORD VERIFICATION ===");
        System.out.println("User: id=" + updatedUser.getId() + ", email=" + updatedUser.getEmail() +
                ", role=" + updatedUser.getRole() + ", currentYearOfStudy=" + updatedUser.getCurrentYearOfStudy() +
                ", mentorEligible=" + updatedUser.isMentorEligible() + ", mentorModeActive=" + updatedUser.isMentorModeActive());

        // 4. Verify notification was sent on first unlock
        verify(notificationService, times(1)).sendGenericNotification(
                eq("token_" + userId),
                eq("MENTOR_ELIGIBLE"),
                eq(userId)
        );

        // 5. Simulate subsequent login — notification must NOT be re-sent
        reset(notificationService);
        String secondOtp = otpService.generateAndSaveOtp(email, "127.0.0.1");
        authService.verifyOtpAndLogin(
                new VerifyOtpRequest(email, secondOtp, "test-device-fp"),
                Role.JUNIOR,
                "Rahul Sharma",
                "Information Technology",
                5,
                "127.0.0.1"
        );

        verify(notificationService, never()).sendGenericNotification(any(), any(), any());
        System.out.println("=== EVIDENCE 3: ONE-TIME NOTIFICATION GUARANTEE VERIFIED (Not re-sent on subsequent login) ===");
    }

    @Test
    @Transactional
    @DisplayName("Evidence 2: JUNIOR with mentorEligible=true does NOT appear in Matching until mentorModeActive=true")
    void testMentorModeOptInMatchingVisibility() {
        String email = "priya.22gcebcs042@galgotiacollege.edu";
        UUID juniorId = UUID.randomUUID();

        // 1. Seed JUNIOR user who is mentor-eligible (Year 4) but mentorModeActive is FALSE
        User juniorMentor = new User(
                juniorId,
                email,
                "Priya Patel",
                Role.JUNIOR,
                "Computer Science & Engineering",
                7,
                4,
                true,
                false, // NOT active
                2022,
                false,
                Instant.now(),
                null
        );
        juniorMentor = userRepository.save(juniorMentor);

        // Create senior profile with DSA tag for Priya
        SeniorProfile profile = new SeniorProfile(
                UUID.randomUUID(),
                juniorMentor,
                15,
                null,
                true,
                Instant.now()
        );
        profile.setTags(List.of("DSA", "Java", "Interview"));
        seniorProfileRepository.save(profile);

        // 2. Create a test Query by another junior
        User juniorAsker = new User(
                UUID.randomUUID(),
                "junior.asker@galgotiacollege.edu",
                "Junior Asker",
                Role.JUNIOR,
                "Computer Science & Engineering",
                1,
                1,
                false,
                false,
                2026,
                false,
                Instant.now(),
                null
        );
        juniorAsker = userRepository.save(juniorAsker);

        Query query = new Query(
                UUID.randomUUID(),
                juniorAsker,
                "How to prepare for Amazon DSA rounds?",
                "Seeking guidance on trees and dynamic programming",
                List.of("DSA", "Java"),
                true,
                QueryStatus.OPEN,
                Instant.now(),
                null
        );
        query = queryRepository.save(query);

        // 3. Test matching: When mentorModeActive = FALSE, Priya MUST NOT appear in matching results
        List<User> matchesBeforeToggle = matchingService.matchSeniorsForQuery(query);
        boolean foundBefore = matchesBeforeToggle.stream().anyMatch(u -> u.getId().equals(juniorId));
        assertFalse(foundBefore, "JUNIOR with mentorModeActive=false MUST NOT appear in candidate matches");
        System.out.println("=== EVIDENCE 2A: Candidate omitted while mentorModeActive = false ===");

        // 4. Toggle mentor mode ON via UserPrincipal
        UserPrincipal principal = new UserPrincipal(
                juniorId,
                email,
                Role.JUNIOR,
                false
        );
        seniorProfileService.toggleMentorMode(principal, true, "127.0.0.1");

        // 5. Test matching: Now Priya MUST appear in candidate matches
        List<User> matchesAfterToggle = matchingService.matchSeniorsForQuery(query);
        boolean foundAfter = matchesAfterToggle.stream().anyMatch(u -> u.getId().equals(juniorId));
        assertTrue(foundAfter, "JUNIOR with mentorModeActive=true MUST appear in candidate matches");

        // Confirm role remains JUNIOR in DB
        User verifyUser = userRepository.findById(juniorId).orElseThrow();
        assertEquals(Role.JUNIOR, verifyUser.getRole(), "User role must strictly remain JUNIOR");
        assertTrue(verifyUser.isMentorModeActive(), "mentorModeActive must be TRUE");

        System.out.println("=== EVIDENCE 2B: Candidate successfully matched after toggling mentorModeActive = true ===");
        System.out.println("Matched Senior Candidates: " + matchesAfterToggle.stream().map(User::getEmail).toList());
    }
}
