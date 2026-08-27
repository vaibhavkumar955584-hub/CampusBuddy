package com.seniorconnect.auth.controller;

import com.seniorconnect.auth.dto.*;
import com.seniorconnect.auth.security.UserPrincipal;
import com.seniorconnect.auth.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    private final com.seniorconnect.auth.service.EmailParserService emailParserService;

    public AuthController(AuthService authService, com.seniorconnect.auth.service.EmailParserService emailParserService) {
        this.authService = authService;
        this.emailParserService = emailParserService;
    }

    @PostMapping("/parse-email")
    public ResponseEntity<ParsedEmailDto> parseEmail(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        ParsedEmailDto parsed = emailParserService.parseCollegeEmail(email);
        return ResponseEntity.ok(parsed);
    }

    @GetMapping("/parse-email")
    public ResponseEntity<ParsedEmailDto> parseEmailQuery(@RequestParam String email) {
        ParsedEmailDto parsed = emailParserService.parseCollegeEmail(email);
        return ResponseEntity.ok(parsed);
    }

    @PostMapping("/send-otp")
    public ResponseEntity<Map<String, String>> sendOtp(
            @Valid @RequestBody SendOtpRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        authService.sendOtp(request, clientIp);
        return ResponseEntity.ok(Map.of("message", "OTP sent successfully to " + request.email()));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<AuthResponse> verifyOtp(
            @Valid @RequestBody VerifyOtpRequest request,
            @RequestParam(required = false) com.seniorconnect.user.model.Role role,
            @RequestParam(required = false) String fullName,
            @RequestParam(required = false) String branch,
            @RequestParam(required = false) Integer semester,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        AuthResponse response = authService.verifyOtpAndLogin(request, role, fullName, branch, semester, clientIp);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/direct-login")
    public ResponseEntity<AuthResponse> directLogin(
            @Valid @RequestBody DirectLoginRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        AuthResponse response = authService.directLogin(request, clientIp);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refreshToken(
            @Valid @RequestBody RefreshTokenRequest request,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        AuthResponse response = authService.refreshToken(request, clientIp);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        String clientIp = extractClientIp(httpRequest);
        authService.logout(principal, clientIp);
        return ResponseEntity.ok(Map.of("message", "Logged out successfully"));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwarded = request.getHeader("X-Forwarded-For");
        if (xForwarded != null && !xForwarded.isBlank()) {
            return xForwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
