package com.seniorconnect.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.seniorconnect.auth.dto.AuthResponse;
import com.seniorconnect.auth.dto.VerifyOtpRequest;
import com.seniorconnect.auth.service.OtpService;
import com.seniorconnect.query.dto.CreateQueryRequest;
import com.seniorconnect.query.dto.CreateResponseRequest;
import com.seniorconnect.query.dto.QueryResponseDto;
import com.seniorconnect.query.entity.QueryStatus;
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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class IdorAndAuthorizationIntegrationTest {

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
    @DisplayName("IDOR Defense: User B cannot modify or close User A's query")
    void testPreventIdorOnQueryUpdate() throws Exception {
        String juniorTokenA = loginUser("junior.a@galgotiacollege.edu.in", "JUNIOR", "Junior A");
        String juniorTokenB = loginUser("junior.b@galgotiacollege.edu.in", "JUNIOR", "Junior B");

        // Junior A creates a query
        CreateQueryRequest queryReq = new CreateQueryRequest("Query by A", "Body content", "test", false);
        MvcResult res = mockMvc.perform(post("/queries")
                        .header("Authorization", "Bearer " + juniorTokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(queryReq)))
                .andExpect(status().isCreated())
                .andReturn();

        QueryResponseDto queryDto = objectMapper.readValue(res.getResponse().getContentAsString(), QueryResponseDto.class);
        UUID queryId = queryDto.id();

        // Junior B attempts to close Junior A's query -> MUST return 403 FORBIDDEN
        mockMvc.perform(patch("/queries/" + queryId + "/status")
                        .param("status", "CLOSED")
                        .header("Authorization", "Bearer " + juniorTokenB))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errorCode").value("IDOR_FORBIDDEN"));
    }

    @Test
    @DisplayName("Role Defense: Junior cannot post mentorship responses")
    void testJuniorCannotPostResponses() throws Exception {
        String juniorToken = loginUser("junior.role.test@galgotiacollege.edu.in", "JUNIOR", "Junior Role Test");

        CreateQueryRequest queryReq = new CreateQueryRequest("Query to answer", "Body content", "test", false);
        MvcResult res = mockMvc.perform(post("/queries")
                        .header("Authorization", "Bearer " + juniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(queryReq)))
                .andExpect(status().isCreated())
                .andReturn();

        QueryResponseDto queryDto = objectMapper.readValue(res.getResponse().getContentAsString(), QueryResponseDto.class);

        // Junior attempts to post response -> MUST return 403 FORBIDDEN
        CreateResponseRequest respReq = new CreateResponseRequest("Attempting junior response");
        mockMvc.perform(post("/queries/" + queryDto.id() + "/responses")
                        .header("Authorization", "Bearer " + juniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(respReq)))
                .andExpect(status().isForbidden());
    }
}
