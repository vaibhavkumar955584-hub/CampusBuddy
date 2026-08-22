package com.seniorconnect.ratelimit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.seniorconnect.auth.dto.AuthResponse;
import com.seniorconnect.auth.dto.SendOtpRequest;
import com.seniorconnect.auth.dto.VerifyOtpRequest;
import com.seniorconnect.auth.service.OtpService;
import com.seniorconnect.query.dto.CreateQueryRequest;
import com.seniorconnect.user.entity.AllowedDomain;
import com.seniorconnect.user.model.Role;
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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class RateLimitingIntegrationTest {

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
    @DisplayName("Rate Limit: Query creation quota triggers HTTP 429 after 5 queries per day")
    void testQueryRateLimit() throws Exception {
        String token = loginUser("junior.ratelimit@galgotiacollege.edu.in", "JUNIOR", "Junior Rate Limit");

        // Submit 5 queries successfully
        for (int i = 1; i <= 5; i++) {
            CreateQueryRequest req = new CreateQueryRequest("Query #" + i, "Content #" + i, "general", false);
            mockMvc.perform(post("/queries")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(req)))
                    .andExpect(status().isCreated());
        }

        // 6th query MUST be rejected with HTTP 429
        CreateQueryRequest req6 = new CreateQueryRequest("Query #6", "Content #6", "general", false);
        mockMvc.perform(post("/queries")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req6)))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.errorCode").value("QUERY_RATE_LIMIT_EXCEEDED"));
    }
}
