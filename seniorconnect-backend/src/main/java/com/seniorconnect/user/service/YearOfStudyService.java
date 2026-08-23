package com.seniorconnect.user.service;

import com.seniorconnect.auth.config.EmailParsingConfig;
import com.seniorconnect.auth.dto.ParsedEmailDto;
import com.seniorconnect.auth.service.EmailParserService;
import com.seniorconnect.notification.service.NotificationService;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class YearOfStudyService {

    private static final Logger log = LoggerFactory.getLogger(YearOfStudyService.class);

    private final UserRepository userRepository;
    private final EmailParserService emailParserService;
    private final EmailParsingConfig emailParsingConfig;
    private final NotificationService notificationService;
    private final int eligibleYearThreshold;

    public YearOfStudyService(
            UserRepository userRepository,
            EmailParserService emailParserService,
            EmailParsingConfig emailParsingConfig,
            NotificationService notificationService,
            @Value("${seniorconnect.mentorship.eligible-year-threshold:3}") int eligibleYearThreshold
    ) {
        this.userRepository = userRepository;
        this.emailParserService = emailParserService;
        this.emailParsingConfig = emailParsingConfig;
        this.notificationService = notificationService;
        this.eligibleYearThreshold = eligibleYearThreshold;
    }

    /**
     * Recalculates year of study and checks mentor eligibility for a user.
     * Returns true if mentor eligibility was newly unlocked on this run.
     */
    @Transactional
    public boolean recalculate(User user) {
        return recalculateAtDate(user, LocalDate.now());
    }

    /**
     * Date-parameterized recalculation for deterministic testing across academic cycles.
     */
    @Transactional
    public boolean recalculateAtDate(User user, LocalDate referenceDate) {
        if (user == null) return false;

        Integer admissionYear = user.getAdmissionYear();
        if (admissionYear == null && user.getEmail() != null) {
            try {
                ParsedEmailDto parsed = emailParserService.parseCollegeEmailAtDate(user.getEmail(), referenceDate);
                if (parsed != null && parsed.admissionYear() != null) {
                    admissionYear = parsed.admissionYear();
                    user.setAdmissionYear(admissionYear);
                }
            } catch (Exception e) {
                log.debug("Could not derive admission year from email {}: {}", user.getEmail(), e.getMessage());
            }
        }

        if (admissionYear == null) {
            return false;
        }

        int currentCalendarYear = referenceDate.getYear();
        int currentMonth = referenceDate.getMonthValue();
        int academicStartMonth = emailParsingConfig.getAcademicStartMonth();
        int monthAdjustment = (currentMonth >= academicStartMonth) ? 1 : 0;
        int computedYear = (currentCalendarYear - admissionYear) + monthAdjustment;

        int finalYearOfStudy = Math.max(1, computedYear);
        user.setCurrentYearOfStudy(finalYearOfStudy);

        boolean newlyUnlocked = false;
        // Role is permanently preserved; only additive capability mentor_eligible is updated
        if (user.getRole() == Role.JUNIOR) {
            boolean isEligible = finalYearOfStudy >= eligibleYearThreshold || computedYear > 4;
            if (isEligible && !user.isMentorEligible()) {
                user.setMentorEligible(true);
                newlyUnlocked = true;
                log.info("MENTOR_ELIGIBILITY_UNLOCKED: User {} (admissionYear={}) advanced to year {} and unlocked mentor eligibility.",
                        user.getEmail(), admissionYear, finalYearOfStudy);

                // Trigger one-time notification
                notificationService.sendGenericNotification("token_" + user.getId(), "MENTOR_ELIGIBLE", user.getId());
            }
        }

        userRepository.save(user);
        return newlyUnlocked;
    }

    /**
     * Scheduled bulk recalculation running monthly (e.g. at academic year boundary in July).
     */
    @Scheduled(cron = "${seniorconnect.mentorship.recalc-cron:0 0 0 1 * ?}")
    @Transactional
    public void recalculateAllJuniorUsers() {
        log.info("Starting scheduled bulk year-of-study and mentor eligibility recalculation...");
        List<User> juniorUsers = userRepository.findByRole(Role.JUNIOR);
        int unlockedCount = 0;
        for (User junior : juniorUsers) {
            if (recalculate(junior)) {
                unlockedCount++;
            }
        }
        log.info("Bulk recalculation completed: {} junior accounts scanned, {} newly unlocked mentor eligibility.",
                juniorUsers.size(), unlockedCount);
    }
}
