package com.seniorconnect.security;

import com.seniorconnect.common.security.RlsSessionFilter;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCallback;

import java.sql.PreparedStatement;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

public class RlsSessionFilterMaliciousInputTest {

    @Test
    @DisplayName("Gap 4 Evidence: Malicious inputs containing SQL injection payloads and single quotes are safely rejected")
    void testMaliciousSqlInjectionPayloadsAreNeutralized() {
        JdbcTemplate mockJdbc = mock(JdbcTemplate.class);
        RlsSessionFilter filter = new RlsSessionFilter(mockJdbc);

        // 1. Attempt malicious SQL payloads with single quotes
        String sqlInjectionUserId = "12345678-1234-1234-1234-123456789012' OR '1'='1";
        String maliciousRole = "ADMIN'; DROP TABLE audit_logs; --";

        filter.setSessionVariablesSafe(sqlInjectionUserId, "JUNIOR");
        filter.setSessionVariablesSafe(UUID.randomUUID().toString(), maliciousRole);

        // Verify that NO SQL statement was executed for malicious inputs
        verify(mockJdbc, never()).execute(anyString(), any(PreparedStatementCallback.class));
        verify(mockJdbc, never()).execute(anyString());

        System.out.println("=== GAP 4 EVIDENCE: SQL INJECTION INPUTS REJECTED ===");
        System.out.println("Payload: \"" + sqlInjectionUserId + "\" -> Blocked by strict UUID validator, no SQL executed");
        System.out.println("Payload: \"" + maliciousRole + "\" -> Blocked by strict Role validator, no SQL executed");

        // 2. Test valid UUID and Role uses prepared statement parameter binding
        String validUserId = UUID.randomUUID().toString();
        String validRole = "SENIOR";

        filter.setSessionVariablesSafe(validUserId, validRole);

        // Verify parameter-bound queries are executed
        verify(mockJdbc, times(1)).execute(eq("SELECT set_config('app.current_user_id', ?, false)"), any(PreparedStatementCallback.class));
        verify(mockJdbc, times(1)).execute(eq("SELECT set_config('app.current_user_role', ?, false)"), any(PreparedStatementCallback.class));

        System.out.println("Valid Input: \"" + validUserId + "\", \"" + validRole + "\" -> Executed via prepared statement set_config(?, ?, false)");
    }
}
