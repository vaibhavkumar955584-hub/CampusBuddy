package com.seniorconnect.auth.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Configuration
@ConfigurationProperties(prefix = "seniorconnect.email-parsing")
public class EmailParsingConfig {

    private String requiredDomain = "galgotiacollege.edu";
    private String collegePrefix = "gce";
    private int academicStartMonth = 7; // July
    private Map<String, String> branches = new HashMap<>();

    public EmailParsingConfig() {
        // Default dictionary mappings if not overridden by YAML
        branches.put("bit", "Information Technology");
        branches.put("it", "Information Technology");
        branches.put("bcs", "Computer Science & Engineering");
        branches.put("cse", "Computer Science & Engineering");
        branches.put("bce", "Electronics & Communication Engineering");
        branches.put("ece", "Electronics & Communication Engineering");
        branches.put("bee", "Electrical & Electronics Engineering");
        branches.put("eee", "Electrical & Electronics Engineering");
        branches.put("bme", "Mechanical Engineering");
        branches.put("me", "Mechanical Engineering");
        branches.put("bcv", "Civil Engineering");
        branches.put("ce", "Civil Engineering");
        branches.put("bai", "Artificial Intelligence & Machine Learning");
        branches.put("aiml", "Artificial Intelligence & Machine Learning");
        branches.put("bds", "Data Science");
        branches.put("ds", "Data Science");
    }

    public String getRequiredDomain() {
        return requiredDomain;
    }

    public void setRequiredDomain(String requiredDomain) {
        this.requiredDomain = requiredDomain;
    }

    public String getCollegePrefix() {
        return collegePrefix;
    }

    public void setCollegePrefix(String collegePrefix) {
        this.collegePrefix = collegePrefix;
    }

    public int getAcademicStartMonth() {
        return academicStartMonth;
    }

    public void setAcademicStartMonth(int academicStartMonth) {
        this.academicStartMonth = academicStartMonth;
    }

    public Map<String, String> getBranches() {
        return branches;
    }

    public void setBranches(Map<String, String> branches) {
        this.branches = branches;
    }
}
