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
            try {
                String userId = principal.getId().toString();
                String role = principal.getRole().name();

                // Set session variables for PostgreSQL RLS policies
                jdbcTemplate.execute("SET app.current_user_id = '" + userId + "'");
                jdbcTemplate.execute("SET app.current_user_role = '" + role + "'");
            } catch (Exception e) {
                // Ignore gracefully if datasource does not support SET (e.g. H2 in lightweight test modes)
                log.trace("RLS session variable initialization skipped: {}", e.getMessage());
            }
        }

        try {
            filterChain.doFilter(request, response);
        } finally {
            // Clean up session context after request
            try {
                jdbcTemplate.execute("RESET app.current_user_id");
                jdbcTemplate.execute("RESET app.current_user_role");
            } catch (Exception ignored) {
            }
        }
    }
}
