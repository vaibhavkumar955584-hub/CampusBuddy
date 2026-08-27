package com.seniorconnect.query.service;

import com.seniorconnect.matching.service.MatchingService;
import com.seniorconnect.profile.entity.SeniorProfile;
import com.seniorconnect.profile.repository.SeniorProfileRepository;
import com.seniorconnect.query.dto.AnalyzeQueryRequest;
import com.seniorconnect.query.dto.QueryAnalysisDto;
import com.seniorconnect.query.entity.Query;
import com.seniorconnect.query.repository.QueryRepository;
import com.seniorconnect.user.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class QueryIntelligenceService {

    private static final Logger log = LoggerFactory.getLogger(QueryIntelligenceService.class);

    private final QueryRepository queryRepository;
    private final SeniorProfileRepository seniorProfileRepository;
    private final MatchingService matchingService;

    // Standard skills dictionary for semantic extraction
    private static final List<String> KNOWN_SKILLS = List.of(
            "DSA", "Data Structures", "Algorithms", "System Design", "Java", "Spring Boot",
            "Python", "C++", "JavaScript", "React", "Node.js", "SQL", "Database", "DBMS",
            "Operating Systems", "Computer Networks", "AWS", "Docker", "Machine Learning",
            "Deep Learning", "Problem Solving", "Interview Preparation", "Resume Review", "Core CS"
    );

    // Standard companies dictionary
    private static final List<String> KNOWN_COMPANIES = List.of(
            "Amazon", "Google", "Microsoft", "Meta", "Apple", "Netflix", "Uber",
            "Atlassian", "Adobe", "Flipkart", "Swiggy", "Zomato", "Goldman Sachs",
            "Morgan Stanley", "TCS", "Infosys", "Wipro", "Cognizant", "Accenture"
    );

    public QueryIntelligenceService(
            QueryRepository queryRepository,
            SeniorProfileRepository seniorProfileRepository,
            MatchingService matchingService
    ) {
        this.queryRepository = queryRepository;
        this.seniorProfileRepository = seniorProfileRepository;
        this.matchingService = matchingService;
    }

    @Transactional(readOnly = true)
    public QueryAnalysisDto analyzeQuery(AnalyzeQueryRequest request) {
        String combinedText = (request.title() + " " + request.content()).trim();
        String lowerText = combinedText.toLowerCase();

        // 1. Extract Intent
        String intent = extractIntent(lowerText);

        // 2. Extract Domain
        String domain = extractDomain(lowerText);

        // 3. Extract Skills
        List<String> extractedSkills = extractSkills(combinedText);

        // 4. Extract Target Company
        String targetCompany = extractCompany(combinedText);

        // 5. Extract Target Role
        String targetRole = extractRole(combinedText);

        // 6. Extract Timeline
        Integer timelineDays = extractTimelineDays(lowerText);

        // 7. Extract Urgency & Experience Level
        String urgency = (timelineDays != null && timelineDays <= 30) || lowerText.contains("urgent") || lowerText.contains("soon")
                ? "HIGH" : "MEDIUM";
        String experienceLevel = lowerText.contains("beginner") || lowerText.contains("scratch") || lowerText.contains("start")
                ? "BEGINNER" : (lowerText.contains("advanced") || lowerText.contains("hard") ? "ADVANCED" : "INTERMEDIATE");

        // 8. Find Similar Questions
        List<QueryAnalysisDto.SimilarQuestionDto> similarQuestions = findSimilarQuestions(request.title(), extractedSkills);

        // 9. Find Recommended Mentors
        List<QueryAnalysisDto.RecommendedMentorDto> recommendedMentors = findRecommendedMentors(extractedSkills, targetCompany);

        return new QueryAnalysisDto(
                intent,
                domain,
                extractedSkills,
                targetCompany,
                targetRole,
                timelineDays,
                urgency,
                experienceLevel,
                similarQuestions,
                recommendedMentors
        );
    }

    private String extractIntent(String lowerText) {
        if (lowerText.contains("placement") || lowerText.contains("interview") || lowerText.contains("offer") || lowerText.contains("sde")) {
            return "PLACEMENT_PREPARATION";
        }
        if (lowerText.contains("intern") || lowerText.contains("internship") || lowerText.contains("summer")) {
            return "INTERNSHIP_ASSISTANCE";
        }
        if (lowerText.contains("exam") || lowerText.contains("semester") || lowerText.contains("notes") || lowerText.contains("syllabus")) {
            return "ACADEMIC_GUIDANCE";
        }
        if (lowerText.contains("roadmap") || lowerText.contains("career") || lowerText.contains("guidance") || lowerText.contains("path")) {
            return "CAREER_ROADMAP";
        }
        return "GENERAL_INQUIRY";
    }

    private String extractDomain(String lowerText) {
        if (lowerText.contains("data science") || lowerText.contains("ml") || lowerText.contains("ai") || lowerText.contains("machine learning")) {
            return "DATA_SCIENCE_AI";
        }
        if (lowerText.contains("embedded") || lowerText.contains("vlsi") || lowerText.contains("electronics") || lowerText.contains("ece")) {
            return "ELECTRONICS_HARDWARE";
        }
        if (lowerText.contains("higher study") || lowerText.contains("gate") || lowerText.contains("gre") || lowerText.contains("cat")) {
            return "HIGHER_EDUCATION";
        }
        return "SOFTWARE_ENGINEERING";
    }

    private List<String> extractSkills(String text) {
        Set<String> skills = new LinkedHashSet<>();
        String lowerText = text.toLowerCase();

        for (String skill : KNOWN_SKILLS) {
            if (Pattern.compile("\\b" + Pattern.quote(skill.toLowerCase()) + "\\b").matcher(lowerText).find()) {
                skills.add(skill);
            }
        }

        if (skills.isEmpty()) {
            skills.add("General Mentorship");
            skills.add("Interview Preparation");
        }
        return new ArrayList<>(skills);
    }

    private String extractCompany(String text) {
        for (String company : KNOWN_COMPANIES) {
            if (Pattern.compile("(?i)\\b" + Pattern.quote(company) + "\\b").matcher(text).find()) {
                return company;
            }
        }
        return null;
    }

    private String extractRole(String text) {
        if (Pattern.compile("(?i)\\b(sde|software engineer|developer|dev)\\b").matcher(text).find()) {
            return "Software Development Engineer (SDE)";
        }
        if (Pattern.compile("(?i)\\b(frontend|react|ui)\\b").matcher(text).find()) {
            return "Frontend Engineer";
        }
        if (Pattern.compile("(?i)\\b(backend|spring|node|api)\\b").matcher(text).find()) {
            return "Backend Engineer";
        }
        if (Pattern.compile("(?i)\\b(data scientist|analyst|ml engineer)\\b").matcher(text).find()) {
            return "Data / ML Engineer";
        }
        return "Engineering Candidate";
    }

    private Integer extractTimelineDays(String lowerText) {
        Pattern monthsPattern = Pattern.compile("(\\d+)\\s*(month|months|mo)");
        Matcher matcher = monthsPattern.matcher(lowerText);
        if (matcher.find()) {
            int months = Integer.parseInt(matcher.group(1));
            return months * 30;
        }

        Pattern daysPattern = Pattern.compile("(\\d+)\\s*(day|days)");
        matcher = daysPattern.matcher(lowerText);
        if (matcher.find()) {
            return Integer.parseInt(matcher.group(1));
        }

        Pattern weeksPattern = Pattern.compile("(\\d+)\\s*(week|weeks)");
        matcher = weeksPattern.matcher(lowerText);
        if (matcher.find()) {
            return Integer.parseInt(matcher.group(1)) * 7;
        }

        return 90; // Standard 90-day preparation default
    }

    private List<QueryAnalysisDto.SimilarQuestionDto> findSimilarQuestions(String title, List<String> skills) {
        try {
            List<Query> recentQueries = queryRepository.findAll(PageRequest.of(0, 15)).getContent();
            List<QueryAnalysisDto.SimilarQuestionDto> similarList = new ArrayList<>();

            Set<String> titleTokens = Arrays.stream(title.toLowerCase().split("\\W+"))
                    .filter(t -> t.length() > 2)
                    .collect(Collectors.toSet());

            for (Query q : recentQueries) {
                Set<String> candidateTokens = Arrays.stream(q.getTitle().toLowerCase().split("\\W+"))
                        .filter(t -> t.length() > 2)
                        .collect(Collectors.toSet());

                // Jaccard similarity
                Set<String> intersection = new HashSet<>(titleTokens);
                intersection.retainAll(candidateTokens);

                Set<String> union = new HashSet<>(titleTokens);
                union.addAll(candidateTokens);

                double similarity = union.isEmpty() ? 0.0 : (double) intersection.size() / union.size();

                if (similarity >= 0.25 || !intersection.isEmpty()) {
                    int scorePct = (int) Math.min(99.0, Math.max(65.0, similarity * 100.0 + 30.0));
                    similarList.add(new QueryAnalysisDto.SimilarQuestionDto(
                            q.getId(),
                            q.getTitle(),
                            scorePct,
                            q.getResponses() != null ? q.getResponses().size() : 0,
                            "Senior Community"
                    ));
                }
            }

            return similarList.stream()
                    .sorted(Comparator.comparingDouble(QueryAnalysisDto.SimilarQuestionDto::similarityScore).reversed())
                    .limit(3)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Similar question search skipped: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    private List<QueryAnalysisDto.RecommendedMentorDto> findRecommendedMentors(List<String> skills, String targetCompany) {
        try {
            List<SeniorProfile> profiles = seniorProfileRepository.findAll();
            List<QueryAnalysisDto.RecommendedMentorDto> mentors = new ArrayList<>();

            for (SeniorProfile p : profiles) {
                User u = p.getUser();
                if (u == null || u.isSuspended()) continue;

                int matchScore = 60; // Base match score
                List<String> matchedSkills = new ArrayList<>();

                for (String s : skills) {
                    for (String pt : p.getTags()) {
                        if (pt.equalsIgnoreCase(s) || pt.toLowerCase().contains(s.toLowerCase())) {
                            matchScore += 15;
                            matchedSkills.add(pt);
                        }
                    }
                }

                if (targetCompany != null && p.getPlacementTag() != null &&
                        p.getPlacementTag().toLowerCase().contains(targetCompany.toLowerCase())) {
                    matchScore += 20;
                }

                if (p.isTagVerified()) {
                    matchScore += 10;
                }

                int finalMatch = Math.min(99, Math.max(70, matchScore));
                mentors.add(new QueryAnalysisDto.RecommendedMentorDto(
                        u.getId(),
                        u.getFullName(),
                        p.getPlacementTag() != null ? p.getPlacementTag() : "Senior Mentor",
                        u.getBranch() != null ? u.getBranch() : "Engineering",
                        finalMatch,
                        Math.max(5, p.getPoints()),
                        matchedSkills.isEmpty() ? List.of("Career Guidance", "DSA") : matchedSkills,
                        p.isTagVerified()
                ));
            }

            return mentors.stream()
                    .sorted(Comparator.comparingInt(QueryAnalysisDto.RecommendedMentorDto::matchPercentage).reversed())
                    .limit(3)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Recommended mentors lookup skipped: {}", e.getMessage());
            return Collections.emptyList();
        }
    }
}
