package com.seniorconnect.matching.service;

import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class MatchingService {

    private final UserRepository userRepository;
    private final SeniorProfileRepository seniorProfileRepository;

    public MatchingService(UserRepository userRepository, SeniorProfileRepository seniorProfileRepository) {
        this.userRepository = userRepository;
        this.seniorProfileRepository = seniorProfileRepository;
    }

    /**
     * Matches seniors whose profile tags or branch match the query tags.
     * Ranked by total gamification points and branch relevance.
     */
    @Transactional(readOnly = true)
    public List<User> matchSeniorsForQuery(Query query) {
        if (query == null) return Collections.emptyList();

        Set<String> queryTagSet = new HashSet<>();
        if (query.getTags() != null && !query.getTags().isBlank()) {
            for (String t : query.getTags().split(",")) {
                queryTagSet.add(t.trim().toLowerCase());
            }
        }

        List<User> seniors = userRepository.findAll().stream()
                .filter(u -> u.getRole() == Role.SENIOR && !u.isSuspended())
                .filter(u -> !u.getId().equals(query.getJunior().getId()))
                .toList();

        // Rank seniors by match score (tag intersection + points bonus)
        return seniors.stream()
                .sorted((s1, s2) -> {
                    int score1 = calculateSeniorMatchScore(s1, query, queryTagSet);
                    int score2 = calculateSeniorMatchScore(s2, query, queryTagSet);
                    return Integer.compare(score2, score1); // Descending
                })
                .collect(Collectors.toList());
    }

    private int calculateSeniorMatchScore(User senior, Query query, Set<String> queryTags) {
        int score = 0;

        // Branch matching bonus (+10)
        if (senior.getBranch() != null && query.getJunior().getBranch() != null) {
            if (senior.getBranch().equalsIgnoreCase(query.getJunior().getBranch())) {
                score += 10;
            }
        }

        // Tag matching bonus (+20 per matched tag in placement / bio tag)
        SeniorProfile profile = seniorProfileRepository.findByUser(senior).orElse(null);
        if (profile != null) {
            score += profile.getPoints(); // Mentorship experience weight
            if (profile.getPlacementTag() != null) {
                String placementLower = profile.getPlacementTag().toLowerCase();
                for (String tag : queryTags) {
                    if (placementLower.contains(tag)) {
                        score += 20;
                        if (profile.isTagVerified()) {
                            score += 15; // Bonus for verified placement credentials
                        }
                    }
                }
            }
        }

        return score;
    }
}
