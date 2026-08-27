package com.seniorconnect.auth.service;

import com.seniorconnect.auth.config.EmailParsingConfig;
import com.seniorconnect.auth.dto.ParsedEmailDto;
import com.seniorconnect.common.exception.AppException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class EmailParserService {

    private static final Logger log = LoggerFactory.getLogger(EmailParserService.class);

    // Pattern: ^(?:[a-z0-9._%+-]+[._])?(\\d{2})([a-z]+)(\\d+)@.*$
    private static final Pattern STUDENT_EMAIL_PATTERN = Pattern.compile(
            "^(?:[a-z0-9._%+-]+[._])?(\\d{2})([a-z]+)(\\d+)@.*$",
            Pattern.CASE_INSENSITIVE
    );

    private final EmailParsingConfig config;

    public EmailParserService(EmailParsingConfig config) {
        this.config = config;
    }

    /**
     * Parses student college email to extract admission year, branch, year-of-study, and auto-tags.
     *
     * @param email Full college email (e.g. vk.24gcebit093@galgotiacollege.edu)
     * @return ParsedEmailDto with extracted metadata or fallback flag for manual entry.
     */
    public ParsedEmailDto parseCollegeEmail(String email) {
        return parseCollegeEmailAtDate(email, LocalDate.now());
    }

    /**
     * Date-parameterized parsing logic for deterministic testing across academic cycles.
     */
    public ParsedEmailDto parseCollegeEmailAtDate(String email, LocalDate referenceDate) {
        if (email == null || email.isBlank()) {
            throw AppException.badRequest("College email cannot be empty", "INVALID_EMAIL");
        }

        String normEmail = email.trim().toLowerCase();

        // 1. Domain validation (allows galgotiacollege.edu or galgotiacollege.edu.in)
        String baseDomain = config.getRequiredDomain().toLowerCase();
        if (!normEmail.contains("@" + baseDomain) && !normEmail.contains("@" + baseDomain + ".in")) {
            log.warn("DOMAIN_REJECTION: Email [{}] does not match required domain [{}]", email, baseDomain);
            throw AppException.badRequest(
                    "Registration requires a @" + config.getRequiredDomain() + " college email address.",
                    "DOMAIN_NOT_ALLOWED"
            );
        }

        // 2. Regex-based extraction
        Matcher matcher = STUDENT_EMAIL_PATTERN.matcher(normEmail);
        if (!matcher.matches()) {
            log.info("NON_STANDARD_EMAIL: Email [{}] did not match student roll format. Falling back to manual entry.", normEmail);
            return ParsedEmailDto.unparsed(normEmail, "Email did not match roll number pattern. Please enter profile details manually.");
        }

        String yearStr = matcher.group(1);       // e.g. "24"
        String alphaBlock = matcher.group(2);    // e.g. "gcebit"
        String rollNumber = matcher.group(3);    // e.g. "093"

        int admissionYear = 2000 + Integer.parseInt(yearStr);
        String batchLabel = admissionYear + " Batch";

        // 3. Branch code lookup
        String collegePrefix = config.getCollegePrefix().toLowerCase();
        String branchCode = alphaBlock;
        if (alphaBlock.startsWith(collegePrefix)) {
            branchCode = alphaBlock.substring(collegePrefix.length());
        }

        String branchName = config.getBranches().get(branchCode);
        boolean requiresManualBranch = false;

        if (branchName == null) {
            log.warn("UNRECOGNIZED_BRANCH_CODE: Email [{}] contains unknown branch code [{}] (alpha block: [{}]). Table needs update.",
                    normEmail, branchCode, alphaBlock);
            requiresManualBranch = true;
        }

        // 4. Year-of-study calculation
        int currentCalendarYear = referenceDate.getYear();
        int currentMonth = referenceDate.getMonthValue();
        int academicStartMonth = config.getAcademicStartMonth();

        // Formula: yearOfStudy = (currentCalendarYear - admissionYear) + (currentMonth >= academicStartMonth ? 1 : 0)
        int monthAdjustment = (currentMonth >= academicStartMonth) ? 1 : 0;
        int computedYear = (currentCalendarYear - admissionYear) + monthAdjustment;

        log.info("YEAR_CALCULATION: email={}, admissionYear={}, currentYear={}, currentMonth={}, startMonth={}, math=({} - {}) + {} = {}",
                normEmail, admissionYear, currentCalendarYear, currentMonth, academicStartMonth,
                currentCalendarYear, admissionYear, monthAdjustment, computedYear);

        Integer yearOfStudy;
        String yearLabel;

        if (computedYear <= 0) {
            yearOfStudy = 1;
            yearLabel = "Incoming (1st Year)";
        } else if (computedYear == 1) {
            yearOfStudy = 1;
            yearLabel = "1st Year";
        } else if (computedYear == 2) {
            yearOfStudy = 2;
            yearLabel = "2nd Year";
        } else if (computedYear == 3) {
            yearOfStudy = 3;
            yearLabel = "3rd Year";
        } else if (computedYear == 4) {
            yearOfStudy = 4;
            yearLabel = "4th Year";
        } else {
            yearOfStudy = computedYear;
            yearLabel = "Alumni";
        }

        // 5. Auto-tag generation
        List<String> autoTags = new ArrayList<>();
        if (branchName != null) {
            autoTags.add(branchName);
        }
        autoTags.add(batchLabel);
        autoTags.add(yearLabel.equals("Alumni") ? "Alumni" : yearLabel);

        return new ParsedEmailDto(
                normEmail,
                true,
                admissionYear,
                batchLabel,
                collegePrefix,
                branchCode,
                branchName,
                yearOfStudy,
                yearLabel,
                rollNumber,
                autoTags,
                requiresManualBranch,
                requiresManualBranch ? "Branch code '" + branchCode + "' not recognized. Please select branch manually." : "Auto-detected details successfully."
        );
    }
}
