package com.seniorconnect.gamification.service;

import com.seniorconnect.gamification.config.BadgeConfig;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BadgeService {

    private static final Logger log = LoggerFactory.getLogger(BadgeService.class);

    private final SeniorProfileRepository seniorProfileRepository;

    public BadgeService(SeniorProfileRepository seniorProfileRepository) {
        this.seniorProfileRepository = seniorProfileRepository;
    }

    /**
     * Evaluates all badge conditions and appends newly earned badges to the senior profile.
     */
    @Transactional
    public boolean evaluateAndAwardBadges(SeniorProfile profile) {
        if (profile == null) return false;

        boolean changed = false;

        // 1. Points thresholds
        if (profile.getPoints() >= 1 && !profile.getBadges().contains(BadgeConfig.FIRST_RESPONSE)) {
            profile.addBadge(BadgeConfig.FIRST_RESPONSE);
            changed = true;
            log.info("Badge [{}] awarded to senior {}", BadgeConfig.FIRST_RESPONSE, profile.getUser().getEmail());
        }

        if (profile.getPoints() >= 10 && !profile.getBadges().contains(BadgeConfig.MENTOR_10)) {
            profile.addBadge(BadgeConfig.MENTOR_10);
            changed = true;
            log.info("Badge [{}] awarded to senior {}", BadgeConfig.MENTOR_10, profile.getUser().getEmail());
        }

        if (profile.getPoints() >= 50 && !profile.getBadges().contains(BadgeConfig.TOP_CONTRIBUTOR)) {
            profile.addBadge(BadgeConfig.TOP_CONTRIBUTOR);
            changed = true;
            log.info("Badge [{}] awarded to senior {}", BadgeConfig.TOP_CONTRIBUTOR, profile.getUser().getEmail());
        }

        // 2. Verified mentor status
        if (profile.isTagVerified() && !profile.getBadges().contains(BadgeConfig.VERIFIED_MENTOR)) {
            profile.addBadge(BadgeConfig.VERIFIED_MENTOR);
            changed = true;
            log.info("Badge [{}] awarded to senior {}", BadgeConfig.VERIFIED_MENTOR, profile.getUser().getEmail());
        }

        if (changed) {
            seniorProfileRepository.save(profile);
        }

        return changed;
    }
}
