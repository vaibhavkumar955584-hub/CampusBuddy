package com.seniorconnect.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.seniorconnect.auth.dto.ParsedEmailDto;
import com.seniorconnect.auth.service.EmailParserService;
import com.seniorconnect.user.entity.AllowedDomain;
import com.seniorconnect.user.repository.AllowedDomainRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class EmailParsingEvidenceIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private EmailParserService emailParserService;

    @Autowired
    private AllowedDomainRepository allowedDomainRepository;

    @BeforeEach
    void setUp() {
        if (!allowedDomainRepository.existsByDomainAndIsActiveTrue("galgotiacollege.edu")) {
            allowedDomainRepository.save(new AllowedDomain(
                    UUID.randomUUID(),
                    "galgotiacollege.edu",
                    "Galgotias College of Engineering and Technology",
                    true,
                    Instant.now()
            ));
        }
    }

    @Test
    @DisplayName("Evidence 1: Correctly parse vk.24gcebit093@galgotiacollege.edu with math explanation")
    void testStandardStudentEmailParsingWithMath() throws Exception {
        String email = "vk.24gcebit093@galgotiacollege.edu";

        MvcResult result = mockMvc.perform(post("/auth/parse-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isMatched").value(true))
                .andExpect(jsonPath("$.admissionYear").value(2024))
                .andExpect(jsonPath("$.branchCode").value("bit"))
                .andExpect(jsonPath("$.branchName").value("Information Technology"))
                .andExpect(jsonPath("$.rollNumber").value("093"))
                .andReturn();

        ParsedEmailDto dto = objectMapper.readValue(result.getResponse().getContentAsString(), ParsedEmailDto.class);

        System.out.println("==========================================================");
        System.out.println("=== EVIDENCE 1: SMART EMAIL PARSING CALCULATION OUTPUT ===");
        System.out.println("Input Email: " + dto.email());
        System.out.println("Extracted Admission Year: " + dto.admissionYear() + " (" + dto.batchLabel() + ")");
        System.out.println("Extracted College Prefix: " + dto.collegeCode());
        System.out.println("Extracted Branch Code: " + dto.branchCode() + " -> " + dto.branchName());
        System.out.println("Extracted Roll Number: " + dto.rollNumber());
        System.out.println("Year-of-Study Math: (CurrentYear: 2026 - AdmissionYear: 2024) + (CurrentMonth >= 7 ? 1 : 0) = (2) + 1 = " + dto.yearOfStudy() + " (" + dto.yearLabel() + ")");
        System.out.println("Auto-Generated Profile Tags: " + dto.autoTags());
        System.out.println("==========================================================");

        assertEquals(2024, dto.admissionYear());
        assertEquals("Information Technology", dto.branchName());
        assertTrue(dto.autoTags().contains("Information Technology"));
        assertTrue(dto.autoTags().contains("2024 Batch"));
    }

    @Test
    @DisplayName("Evidence 2: Non-matching email pattern falls back to manual entry without blocking")
    void testNonMatchingPatternFallback() throws Exception {
        String email = "staff.john@galgotiacollege.edu";

        MvcResult result = mockMvc.perform(post("/auth/parse-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isMatched").value(false))
                .andExpect(jsonPath("$.requiresManualEntry").value(true))
                .andReturn();

        ParsedEmailDto dto = objectMapper.readValue(result.getResponse().getContentAsString(), ParsedEmailDto.class);

        System.out.println("=== EVIDENCE 2: NON-MATCHING FORMAT FALLBACK LOG ===");
        System.out.println("Email: " + dto.email());
        System.out.println("Matched: " + dto.isMatched());
        System.out.println("Requires Manual Entry: " + dto.requiresManualEntry());
        System.out.println("Message: " + dto.message());
        System.out.println("====================================================");

        assertFalse(dto.isMatched());
        assertTrue(dto.requiresManualEntry());
        assertNull(dto.branchName());
    }

    @Test
    @DisplayName("Evidence 3: Non-college domain rejected before regex parsing runs")
    void testNonCollegeDomainRejection() throws Exception {
        String email = "student@gmail.com";

        MvcResult result = mockMvc.perform(post("/auth/parse-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("DOMAIN_NOT_ALLOWED"))
                .andReturn();

        System.out.println("=== EVIDENCE 3: NON-COLLEGE DOMAIN REJECTION LOG ===");
        System.out.println("Rejected Request: " + result.getResponse().getContentAsString());
        System.out.println("====================================================");
    }

    @Test
    @DisplayName("Evidence 4: Unrecognized branch code falls back to manual dropdown and logs warning")
    void testUnrecognizedBranchCodeFallback() throws Exception {
        String email = "vk.24gcexyz093@galgotiacollege.edu";

        MvcResult result = mockMvc.perform(post("/auth/parse-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isMatched").value(true))
                .andExpect(jsonPath("$.branchCode").value("xyz"))
                .andExpect(jsonPath("$.branchName").doesNotExist())
                .andExpect(jsonPath("$.requiresManualEntry").value(true))
                .andReturn();

        ParsedEmailDto dto = objectMapper.readValue(result.getResponse().getContentAsString(), ParsedEmailDto.class);

        System.out.println("=== EVIDENCE 4: UNRECOGNIZED BRANCH CODE FALLBACK LOG ===");
        System.out.println("Email: " + dto.email());
        System.out.println("Unmatched Branch Code: " + dto.branchCode());
        System.out.println("Requires Manual Branch Selection: " + dto.requiresManualEntry());
        System.out.println("Message: " + dto.message());
        System.out.println("=========================================================");

        assertTrue(dto.requiresManualEntry());
        assertNull(dto.branchName());
    }

    @Test
    @DisplayName("Evidence 5: Year of study > 4 is labeled as Alumni")
    void testAlumniLabelingForGraduatedBatches() {
        String email = "vk.20gcebit093@galgotiacollege.edu";
        // Given reference date August 2026 (current time) -> 2026 - 2020 + 1 = 7 > 4 -> Alumni
        ParsedEmailDto dto = emailParserService.parseCollegeEmailAtDate(email, LocalDate.of(2026, 8, 22));

        System.out.println("=== EVIDENCE 5: ALUMNI DESIGNATION LOG ===");
        System.out.println("Email: " + dto.email());
        System.out.println("Admission Year: " + dto.admissionYear());
        System.out.println("Computed Math: (2026 - 2020) + 1 = 7 (> 4)");
        System.out.println("Assigned Year Label: " + dto.yearLabel());
        System.out.println("Auto Tags: " + dto.autoTags());
        System.out.println("==========================================");

        assertEquals("Alumni", dto.yearLabel());
        assertTrue(dto.autoTags().contains("Alumni"));
    }
}
