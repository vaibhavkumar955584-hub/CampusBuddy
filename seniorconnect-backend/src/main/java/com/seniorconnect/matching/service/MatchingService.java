package com.seniorconnect.matching.service;

import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import com.seniorconnect.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class MatchingService {

    private static final Logger log = LoggerFactory.getLogger(MatchingService.class);

    private final UserRepository userRepository;
    private final SeniorProfileRepository seniorProfileRepository;

    public MatchingService(UserRepository userRepository, SeniorProfileRepository seniorProfileRepository) {
        this.userRepository = userRepository;
        this.seniorProfileRepository = seniorProfileRepository;
    }

    /**
     * Matches seniors whose profile tags or branch match the query tags.
     * Uses DB-level native Postgres array overlap (sp.tags && :queryTags) and fast candidate joins
     * to eliminate O(N) full-table scans.
     * Ranked by total gamification points, verified status, and branch relevance.
     */
    @Transactional(readOnly = true)
    public List<User> matchSeniorsForQuery(Query query) {
        return matchSeniorsForQuery(query, 20);
    }

    @Transactional(readOnly = true)
    public List<User> matchSeniorsForQuery(Query query, int limit) {
        if (query == null) return Collections.emptyList();

        List<String> queryTagsList = query.getTagsList();
        Set<String> queryTagSet = queryTagsList.stream()
                .map(String::toLowerCase)
                .collect(Collectors.toSet());

        String branch = query.getJunior() != null ? query.getJunior().getBranch() : null;
        UUID juniorId = query.getJunior() != null ? query.getJunior().getId() : null;

        List<SeniorProfile> candidateProfiles;
        if (!queryTagsList.isEmpty()) {
            String csv = String.join(",", queryTagsList);
            try {
                candidateProfiles = seniorProfileRepository.findMatchingProfilesNative(csv);
                if (candidateProfiles.isEmpty() && branch != null) {
                    candidateProfiles = seniorProfileRepository.findCandidateProfilesByBranch(branch);
                }
            } catch (Exception e) {
                log.debug("Native array-overlap matching query skipped/failed [queryTags='{}']: {}", csv, e.getMessage());
                candidateProfiles = seniorProfileRepository.findCandidateProfilesByBranch(branch);
            }
        } else {
            candidateProfiles = seniorProfileRepository.findCandidateProfilesByBranch(branch);
        }

        // Apply scoring bonuses to the database-narrowed candidate list
        return candidateProfiles.stream()
                .filter(p -> p.getUser() != null && (p.getUser().getRole() == Role.SENIOR || (p.getUser().getRole() == Role.JUNIOR && p.getUser().isMentorModeActive())) && !p.getUser().isSuspended())
                .filter(p -> juniorId == null || !p.getUser().getId().equals(juniorId))
                .sorted((p1, p2) -> {
                    int score1 = calculateSeniorMatchScore(p1, query, queryTagSet);
                    int score2 = calculateSeniorMatchScore(p2, query, queryTagSet);
                    return Integer.compare(score2, score1); // Descending
                })
                .limit(limit > 0 ? limit : 20)
                .map(SeniorProfile::getUser)
                .collect(Collectors.toList());
    }

    private int calculateSeniorMatchScore(SeniorProfile profile, Query query, Set<String> queryTags) {
        int score = 0;
        User senior = profile.getUser();

        // Branch matching bonus (+10)
        if (senior.getBranch() != null && query.getJunior() != null && query.getJunior().getBranch() != null) {
            if (senior.getBranch().equalsIgnoreCase(query.getJunior().getBranch())) {
                score += 10;
            }
        }

        // Gamification points weight
        score += profile.getPoints();

        // Tag matching bonus (+20 per matched tag in placement / bio tags)
        for (String pTag : profile.getTags()) {
            String pTagLower = pTag.toLowerCase();
            for (String qTag : queryTags) {
                if (pTagLower.contains(qTag) || qTag.contains(pTagLower)) {
                    score += 20;
                    if (profile.isTagVerified()) {
                        score += 15; // Bonus for verified placement credentials
                    }
                }
            }
        }

        // Backwards compatibility for placementTag string field
        if (profile.getPlacementTag() != null && profile.getTags().isEmpty()) {
            String placementLower = profile.getPlacementTag().toLowerCase();
            for (String qTag : queryTags) {
                if (placementLower.contains(qTag)) {
                    score += 20;
                    if (profile.isTagVerified()) {
                        score += 15;
                    }
                }
            }
        }

        return score;
    }

    @Transactional(readOnly = true)
    public List<com.seniorconnect.matching.dto.MentorMatchResultDto> matchSeniorsWithDetails(Query query, int limit) {
        if (query == null) return Collections.emptyList();

        List<String> queryTagsList = query.getTagsList();
        Set<String> queryTagSet = queryTagsList.stream()
                .map(String::toLowerCase)
                .collect(Collectors.toSet());

        String branch = query.getJunior() != null ? query.getJunior().getBranch() : null;
        UUID juniorId = query.getJunior() != null ? query.getJunior().getId() : null;

        List<SeniorProfile> candidateProfiles;
        if (!queryTagsList.isEmpty()) {
            String csv = String.join(",", queryTagsList);
            try {
                candidateProfiles = seniorProfileRepository.findMatchingProfilesNative(csv);
                if (candidateProfiles.isEmpty() && branch != null) {
                    candidateProfiles = seniorProfileRepository.findCandidateProfilesByBranch(branch);
                }
            } catch (Exception e) {
                candidateProfiles = seniorProfileRepository.findCandidateProfilesByBranch(branch);
            }
        } else {
            candidateProfiles = seniorProfileRepository.findCandidateProfilesByBranch(branch);
        }

        return candidateProfiles.stream()
                .filter(p -> p.getUser() != null && (p.getUser().getRole() == Role.SENIOR || (p.getUser().getRole() == Role.JUNIOR && p.getUser().isMentorModeActive())) && !p.getUser().isSuspended())
                .filter(p -> juniorId == null || !p.getUser().getId().equals(juniorId))
                .map(p -> {
                    User u = p.getUser();
                    List<String> matched = new ArrayList<>();
                    boolean companyMatch = false;

                    for (String pt : p.getTags()) {
                        for (String qt : queryTagSet) {
                            if (pt.toLowerCase().contains(qt) || qt.contains(pt.toLowerCase())) {
                                matched.add(pt);
                            }
                        }
                    }

                    if (p.getPlacementTag() != null) {
                        for (String qt : queryTagSet) {
                            if (p.getPlacementTag().toLowerCase().contains(qt)) {
                                companyMatch = true;
                            }
                        }
                    }

                    int rawScore = calculateSeniorMatchScore(p, query, queryTagSet);
                    int percentage = Math.min(99, Math.max(65, rawScore * 2 + 50));

                    String headline = (companyMatch ? p.getPlacementTag() + " Mentor • " : "") +
                            (matched.isEmpty() ? "General Academic Mentor" : String.join(", ", matched.stream().limit(2).toList()));

                    return new com.seniorconnect.matching.dto.MentorMatchResultDto(
                            u.getId(),
                            u.getFullName(),
                            u.getEmail(),
                            u.getBranch(),
                            p.getPlacementTag(),
                            p.isTagVerified(),
                            p.getPoints(),
                            percentage,
                            matched,
                            companyMatch,
                            headline
                    );
                })
                .sorted(Comparator.comparingInt(com.seniorconnect.matching.dto.MentorMatchResultDto::matchPercentage).reversed())
                .limit(limit > 0 ? limit : 10)
                .collect(Collectors.toList());
    }
}
