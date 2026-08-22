package com.seniorconnect.reveal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.seniorconnect.auth.dto.AuthResponse;
import com.seniorconnect.auth.dto.VerifyOtpRequest;
import com.seniorconnect.auth.service.OtpService;
import com.seniorconnect.query.dto.CreateQueryRequest;
import com.seniorconnect.query.dto.CreateResponseRequest;
import com.seniorconnect.query.dto.QueryResponseDto;
import com.seniorconnect.reveal.dto.RevealRequestDto;
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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class AnonymityAndRevealIntegrationTest {

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
    @DisplayName("Zero-trust Anonymity: Junior identity is masked to Seniors until explicit Junior approval")
    void testZeroTrustAnonymityAndRevealFlow() throws Exception {
        String juniorToken = loginUser("junior.anon@galgotiacollege.edu.in", "JUNIOR", "Junior Anonymous");
        String seniorToken = loginUser("senior.mentor@galgotiacollege.edu.in", "SENIOR", "Senior Mentor");
        String otherSeniorToken = loginUser("senior.other@galgotiacollege.edu.in", "SENIOR", "Other Senior");

        // 1. Junior posts an anonymous query
        CreateQueryRequest queryReq = new CreateQueryRequest(
                "How to prepare for DBMS end sem exam?",
                "Need suggestions on normalization and SQL indexing.",
                "dbms,exams",
                true // isAnonymousDisplay
        );

        MvcResult createQueryRes = mockMvc.perform(post("/queries")
                        .header("Authorization", "Bearer " + juniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(queryReq)))
                .andExpect(status().isCreated())
                .andReturn();

        QueryResponseDto createdQuery = objectMapper.readValue(createQueryRes.getResponse().getContentAsString(), QueryResponseDto.class);
        UUID queryId = createdQuery.id();

        // 2. Senior views query -> Identity MUST be masked
        MvcResult seniorViewRes = mockMvc.perform(get("/queries/" + queryId)
                        .header("Authorization", "Bearer " + seniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.juniorName").value("Anonymous Junior"))
                .andExpect(jsonPath("$.juniorId").doesNotExist())
                .andExpect(jsonPath("$.identityRevealedToViewer").value(false))
                .andReturn();

        // 3. Senior posts a mentorship response
        CreateResponseRequest answerReq = new CreateResponseRequest("Focus on BCNF and B+ Tree indexing practice.");
        mockMvc.perform(post("/queries/" + queryId + "/responses")
                        .header("Authorization", "Bearer " + seniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(answerReq)))
                .andExpect(status().isCreated());

        // 4. Senior requests identity reveal
        MvcResult revealReqRes = mockMvc.perform(post("/reveals/query/" + queryId + "/request")
                        .header("Authorization", "Bearer " + seniorToken))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andReturn();

        RevealRequestDto revealDto = objectMapper.readValue(revealReqRes.getResponse().getContentAsString(), RevealRequestDto.class);
        UUID revealRequestId = revealDto.id();

        // Query identity is STILL masked before Junior accepts
        mockMvc.perform(get("/queries/" + queryId)
                        .header("Authorization", "Bearer " + seniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.juniorName").value("Anonymous Junior"));

        // 5. Junior accepts the reveal request
        mockMvc.perform(post("/reveals/" + revealRequestId + "/respond")
                        .param("accept", "true")
                        .header("Authorization", "Bearer " + juniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACCEPTED"));

        // 6. Senior views query now -> Junior's real identity is revealed to THIS senior!
        mockMvc.perform(get("/queries/" + queryId)
                        .header("Authorization", "Bearer " + seniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.juniorName").value("Junior Anonymous"))
                .andExpect(jsonPath("$.identityRevealedToViewer").value(true));

        // 7. Another Senior C views query -> Identity is STILL masked for Senior C (isolated per-senior authorization)
        mockMvc.perform(get("/queries/" + queryId)
                        .header("Authorization", "Bearer " + otherSeniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.juniorName").value("Anonymous Junior"))
                .andExpect(jsonPath("$.identityRevealedToViewer").value(false));
    }
}
