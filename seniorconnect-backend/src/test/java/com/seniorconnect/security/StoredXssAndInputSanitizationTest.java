package com.seniorconnect.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.seniorconnect.auth.dto.AuthResponse;
import com.seniorconnect.auth.dto.VerifyOtpRequest;
import com.seniorconnect.auth.service.OtpService;
import com.seniorconnect.query.dto.CreateQueryRequest;
import com.seniorconnect.query.dto.QueryResponseDto;
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
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class StoredXssAndInputSanitizationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private AllowedDomainRepository allowedDomainRepository;

    @Autowired
    private OtpService otpService;

    @BeforeEach
    void setUp() {
        if (!allowedDomainRepository.existsByDomainAndIsActiveTrue("galgotiacollege.edu.in")) {
            allowedDomainRepository.save(new AllowedDomain(
                    UUID.randomUUID(),
                    "galgotiacollege.edu.in",
                    "Galgotias College",
                    true,
                    Instant.now()
            ));
        }
    }

    private String loginUser(String email, String role, String name) throws Exception {
        String otp = otpService.generateAndSaveOtp(email, "127.0.0.1");
        VerifyOtpRequest req = new VerifyOtpRequest(email, otp, "test-device");
        MvcResult res = mockMvc.perform(post("/auth/verify-otp")
                        .param("role", role)
                        .param("fullName", name)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();
        AuthResponse auth = objectMapper.readValue(res.getResponse().getContentAsString(), AuthResponse.class);
        return auth.accessToken();
    }

    @Test
    @DisplayName("Stored XSS Defense: Malicious script tags and event handlers must be stripped on write")
    void testInputSanitizationStripsXss() throws Exception {
        String juniorToken = loginUser("junior.xss@galgotiacollege.edu.in", "JUNIOR", "Junior XSS Test");

        String maliciousTitle = "Normal Title <script>alert('xss')</script>";
        String maliciousContent = "Body with <img src=x onerror=alert(document.cookie)> and <a href='javascript:void(0)'>Click me</a>";
        String maliciousTags = "<b>math</b>, <script>evil()</script>";

        CreateQueryRequest request = new CreateQueryRequest(
                maliciousTitle,
                maliciousContent,
                maliciousTags,
                false
        );

        MvcResult res = mockMvc.perform(post("/queries")
                        .header("Authorization", "Bearer " + juniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andReturn();

        QueryResponseDto created = objectMapper.readValue(res.getResponse().getContentAsString(), QueryResponseDto.class);

        assertFalse(created.title().contains("<script>"), "Title must not contain script tags");
        assertFalse(created.content().contains("<img"), "Content must not contain image payload");
        assertFalse(created.content().contains("onerror"), "Content must not contain onerror handler");
        assertFalse(created.tags().contains("<script>"), "Tags must not contain script tags");
    }
}
