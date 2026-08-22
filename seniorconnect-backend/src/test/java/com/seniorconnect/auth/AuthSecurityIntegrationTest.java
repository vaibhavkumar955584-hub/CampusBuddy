package com.seniorconnect.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.seniorconnect.auth.dto.*;
import com.seniorconnect.auth.service.OtpService;
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

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class AuthSecurityIntegrationTest {

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

    @Test
    @DisplayName("Should reject email registration from non-whitelisted domain")
    void testRejectNonWhitelistedDomain() throws Exception {
        SendOtpRequest request = new SendOtpRequest(
                "attacker@gmail.com",
                Role.JUNIOR,
                "Attacker User",
                "CSE",
                3
        );

        mockMvc.perform(post("/auth/send-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("DOMAIN_NOT_ALLOWED"));
    }

    @Test
    @DisplayName("Should send OTP successfully for whitelisted college domain")
    void testSendOtpSuccess() throws Exception {
        SendOtpRequest request = new SendOtpRequest(
                "student1@galgotiacollege.edu.in",
                Role.JUNIOR,
                "Student One",
                "CSE",
                3
        );

        mockMvc.perform(post("/auth/send-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value(containsString("OTP sent successfully")));
    }

    @Test
    @DisplayName("Should successfully login with valid OTP and rotate refresh tokens")
    void testLoginAndRefreshTokenRotation() throws Exception {
        String email = "junior.verify@galgotiacollege.edu.in";
        String rawOtp = otpService.generateAndSaveOtp(email, "127.0.0.1");

        VerifyOtpRequest verifyRequest = new VerifyOtpRequest(email, rawOtp, "device-fp-123");

        MvcResult result = mockMvc.perform(post("/auth/verify-otp")
                        .param("role", "JUNIOR")
                        .param("fullName", "Verified Junior")
                        .param("branch", "CSE")
                        .param("semester", "4")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(verifyRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andExpect(jsonPath("$.user.email").value(email))
                .andReturn();

        AuthResponse authResponse = objectMapper.readValue(result.getResponse().getContentAsString(), AuthResponse.class);
        String initialRefreshToken = authResponse.refreshToken();
        assertNotNull(initialRefreshToken);

        // Perform Refresh Token Rotation
        RefreshTokenRequest refreshReq = new RefreshTokenRequest(initialRefreshToken, "device-fp-123");
        MvcResult refreshResult = mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andReturn();

        AuthResponse rotatedResponse = objectMapper.readValue(refreshResult.getResponse().getContentAsString(), AuthResponse.class);
        String rotatedRefreshToken = rotatedResponse.refreshToken();

        // Stolen Token / Replay Detection: Attempting to reuse the old refresh token MUST trigger revocation!
        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode").value("SESSION_REVOKED"));
    }
}
