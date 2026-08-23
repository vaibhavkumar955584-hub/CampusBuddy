package com.seniorconnect.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class CorsSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("Gap 1 Evidence: Preflight request from allowlisted origin succeeds with credential headers")
    void testAllowlistedOriginSucceeds() throws Exception {
        mockMvc.perform(options("/auth/otp/request")
                        .header(HttpHeaders.ORIGIN, "http://localhost:3000")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "Content-Type"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:3000"))
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS, "true"));

        System.out.println("=== GAP 1 EVIDENCE: ALLOWLISTED ORIGIN ACCEPTED ===");
        System.out.println("Origin: http://localhost:3000 -> Access-Control-Allow-Origin: http://localhost:3000, Credentials: true");
    }

    @Test
    @DisplayName("Gap 1 Evidence: Preflight request from unauthorized/malicious origin is rejected (no CORS allow headers)")
    void testNonAllowlistedOriginIsBlocked() throws Exception {
        mockMvc.perform(options("/auth/otp/request")
                        .header(HttpHeaders.ORIGIN, "https://malicious-attacker-website.com")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "Content-Type"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN));

        System.out.println("=== GAP 1 EVIDENCE: NON-ALLOWLISTED ORIGIN BLOCKED ===");
        System.out.println("Origin: https://malicious-attacker-website.com -> HTTP 403 Forbidden, No Access-Control-Allow-Origin Header");
    }
}
