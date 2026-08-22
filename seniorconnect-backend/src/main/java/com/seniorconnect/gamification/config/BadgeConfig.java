package com.seniorconnect.gamification.config;

import java.util.List;

public class BadgeConfig {

    public static final String FIRST_RESPONSE = "First Response";
    public static final String MENTOR_10 = "10 Helped";
    public static final String VERIFIED_MENTOR = "Verified Mentor";
    public static final String TOP_CONTRIBUTOR = "Top Contributor";

    public record BadgeDefinition(String id, String name, String description, String icon) {}

    public static final List<BadgeDefinition> ALL_BADGES = List.of(
            new BadgeDefinition("first_response", FIRST_RESPONSE, "Provided the first helpful response to a junior query", "award"),
            new BadgeDefinition("mentor_10", MENTOR_10, "Helped over 10 junior queries in campus mentorship", "star"),
            new BadgeDefinition("verified_mentor", VERIFIED_MENTOR, "Verified placement / company credentials verified by admin", "verified"),
            new BadgeDefinition("top_contributor", TOP_CONTRIBUTOR, "Earned 50+ mentorship points across campus queries", "military_tech")
    );
}
