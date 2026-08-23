package com.seniorconnect.common.security;

import com.seniorconnect.auth.security.UserPrincipal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class RlsSessionFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RlsSessionFilter.class);
    private static final java.util.regex.Pattern STRICT_UUID_PATTERN = java.util.regex.Pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");
    private static final java.util.regex.Pattern STRICT_ROLE_PATTERN = java.util.regex.Pattern.compile("^(JUNIOR|SENIOR|ADMIN)$");

    private final JdbcTemplate jdbcTemplate;

    public RlsSessionFilter(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if (auth != null && auth.getPrincipal() instanceof UserPrincipal principal) {
            String rawUserId = principal.getId() != null ? principal.getId().toString() : null;
            String rawRole = principal.getRole() != null ? principal.getRole().name() : null;

            setSessionVariablesSafe(rawUserId, rawRole);
        }

        try {
            filterChain.doFilter(request, response);
        } finally {
            // Clean up session context after request
            resetSessionVariablesSafe();
        }
    }

    public void setSessionVariablesSafe(String userId, String role) {
        if (userId == null || !STRICT_UUID_PATTERN.matcher(userId).matches()) {
            log.warn("Rejected invalid or potentially malicious user ID in RLS session filter: {}", userId);
            return;
        }
        if (role == null || !STRICT_ROLE_PATTERN.matcher(role).matches()) {
            log.warn("Rejected invalid or potentially malicious role in RLS session filter: {}", role);
            return;
        }

        try {
            // Use prepared statement with parameter binding via PostgreSQL set_config() function
            jdbcTemplate.execute("SELECT set_config('app.current_user_id', ?, false)",
                    (java.sql.PreparedStatement ps) -> {
                        ps.setString(1, userId);
                        ps.execute();
                        return null;
                    });

            jdbcTemplate.execute("SELECT set_config('app.current_user_role', ?, false)",
                    (java.sql.PreparedStatement ps) -> {
                        ps.setString(1, role);
                        ps.execute();
                        return null;
                    });
        } catch (Exception e) {
            // Gracefully handle in-memory databases (e.g. H2 in lightweight test modes)
            log.trace("RLS session variable initialization skipped: {}", e.getMessage());
        }
    }

    public void resetSessionVariablesSafe() {
        try {
            jdbcTemplate.execute("SELECT set_config('app.current_user_id', '', false)");
            jdbcTemplate.execute("SELECT set_config('app.current_user_role', '', false)");
        } catch (Exception ignored) {
        }
    }
}
