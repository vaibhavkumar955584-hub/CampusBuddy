package com.seniorconnect.auth.security;

import com.seniorconnect.user.entity.User;
import com.seniorconnect.user.model.Role;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    private static final Logger log = LoggerFactory.getLogger(JwtService.class);

    private final RsaKeyProvider rsaKeyProvider;
    private final long accessTokenExpirationSeconds;
    private final String issuer;

    public JwtService(
            RsaKeyProvider rsaKeyProvider,
            @Value("${seniorconnect.security.jwt.access-token-expiration-seconds:900}") long accessTokenExpirationSeconds,
            @Value("${seniorconnect.security.jwt.issuer:seniorconnect-auth-server}") String issuer
    ) {
        this.rsaKeyProvider = rsaKeyProvider;
        this.accessTokenExpirationSeconds = accessTokenExpirationSeconds;
        this.issuer = issuer;
    }

    public String generateAccessToken(User user) {
        Instant now = Instant.now();
        Instant expiry = now.plusSeconds(accessTokenExpirationSeconds);

        return Jwts.builder()
                .header().type("JWT").and()
                .issuer(issuer)
                .subject(user.getId().toString())
                .claim("email", user.getEmail())
                .claim("role", user.getRole().name())
                .claim("name", user.getFullName())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(rsaKeyProvider.getPrivateKey(), Jwts.SIG.RS256)
                .compact();
    }

    public Claims parseAndValidateToken(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(rsaKeyProvider.getPublicKey())
                    .requireIssuer(issuer)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("JWT validation failed: {}", e.getMessage());
            throw e;
        }
    }

    public UUID extractUserId(Claims claims) {
        return UUID.fromString(claims.getSubject());
    }

    public String extractEmail(Claims claims) {
        return claims.get("email", String.class);
    }

    public Role extractRole(Claims claims) {
        String roleStr = claims.get("role", String.class);
        return Role.valueOf(roleStr);
    }
}
