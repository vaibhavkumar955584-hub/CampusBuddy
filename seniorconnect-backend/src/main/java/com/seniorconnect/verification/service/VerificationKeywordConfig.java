package com.seniorconnect.verification.service;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
@ConfigurationProperties(prefix = "seniorconnect.verification")
public class VerificationKeywordConfig {

    private Map<String, List<String>> tagKeywords = new HashMap<>();

    public VerificationKeywordConfig() {
        // Default built-in keyword dictionary for common college placement & achievement tags
        tagKeywords.put("placed@amazon", List.of("amazon", "aws", "software development engineer", "sde"));
        tagKeywords.put("placed@google", List.of("google", "alphabet", "software engineer", "swe"));
        tagKeywords.put("placed@microsoft", List.of("microsoft", "redmond", "software engineer"));
        tagKeywords.put("placed@flipkart", List.of("flipkart", "walmart", "sde"));
        tagKeywords.put("placed@tcs", List.of("tata consultancy services", "tcs", "ninja", "digital", "prime"));
        tagKeywords.put("placed@infosys", List.of("infosys", "specialist programmer", "system engineer"));
        tagKeywords.put("sih winner", List.of("smart india hackathon", "sih", "ministry", "aicte", "winner", "first prize"));
        tagKeywords.put("gate qualified", List.of("graduate aptitude test", "gate", "iit", "scorecard", "qualifying marks"));
    }

    public Map<String, List<String>> getTagKeywords() {
        return tagKeywords;
    }

    public void setTagKeywords(Map<String, List<String>> tagKeywords) {
        this.tagKeywords = tagKeywords;
    }

    /**
     * Evaluates if extracted OCR text matches expected keywords for a claimed tag.
     * Uses config dictionary + fallback tag token matching.
     */
    public boolean evaluateKeywordMatch(String claimedTag, String extractedText) {
        if (claimedTag == null || extractedText == null || extractedText.isBlank()) {
            return false;
        }

        String normText = extractedText.toLowerCase();
        String normTag = claimedTag.toLowerCase().trim();

        // 1. Check exact dictionary configuration
        List<String> expectedKeywords = tagKeywords.get(normTag);
        if (expectedKeywords != null) {
            for (String kw : expectedKeywords) {
                if (normText.contains(kw.toLowerCase())) {
                    return true;
                }
            }
        }

        // 2. Generic fallback: if tag is "Placed@Company", extract "Company"
        if (normTag.contains("@")) {
            String company = normTag.substring(normTag.indexOf("@") + 1).trim();
            if (company.length() >= 3 && normText.contains(company)) {
                return true;
            }
        }

        // 3. Fallback token overlap
        String[] words = normTag.split("[\\s@_-]+");
        for (String word : words) {
            if (word.length() >= 4 && !word.equalsIgnoreCase("placed") && normText.contains(word)) {
                return true;
            }
        }

        return false;
    }
}
