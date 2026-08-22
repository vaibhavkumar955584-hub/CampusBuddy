package com.seniorconnect.auth.security;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;

@Component
public class RsaKeyProvider {

    private static final Logger log = LoggerFactory.getLogger(RsaKeyProvider.class);

    @Value("${seniorconnect.security.jwt.private-key-path:}")
    private String privateKeyPath;

    @Value("${seniorconnect.security.jwt.public-key-path:}")
    private String publicKeyPath;

    private final Environment environment;
    private KeyPair keyPair;

    public RsaKeyProvider(Environment environment) {
        this.environment = environment;
    }

    @PostConstruct
    public void init() {
        if (StringUtils.hasText(privateKeyPath) && StringUtils.hasText(publicKeyPath)) {
            try {
                RSAPrivateKey privateKey = loadPrivateKey(privateKeyPath);
                RSAPublicKey publicKey = loadPublicKey(publicKeyPath);
                this.keyPair = new KeyPair(publicKey, privateKey);
                log.info("Loaded persistent RSA key pair from configured PEM paths: private='{}', public='{}'",
                        privateKeyPath, publicKeyPath);
                return;
            } catch (Exception e) {
                log.error("Failed to load RSA key pair from configured paths: {}", e.getMessage(), e);
                if (isProductionEnvironment()) {
                    throw new IllegalStateException("Failed to load configured RSA keys in production: " + e.getMessage(), e);
                }
                log.warn("Falling back to ephemeral key generation due to load failure in non-prod environment.");
            }
        }

        // Only allow fallback to ephemeral keys in test, dev, local, or default environments
        if (isProductionEnvironment()) {
            throw new IllegalStateException(
                    "JWT_PRIVATE_KEY_PATH and JWT_PUBLIC_KEY_PATH must be configured in production environments."
            );
        }

        generateEphemeralKeyPair();
    }

    private boolean isProductionEnvironment() {
        List<String> activeProfiles = Arrays.asList(environment.getActiveProfiles());
        if (activeProfiles.isEmpty()) {
            // Default profile without active profiles is treated as local/dev
            return false;
        }
        for (String profile : activeProfiles) {
            String p = profile.toLowerCase();
            if (p.contains("prod") || p.contains("staging")) {
                return true;
            }
        }
        return false;
    }

    private void generateEphemeralKeyPair() {
        try {
            KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
            keyGen.initialize(2048);
            this.keyPair = keyGen.generateKeyPair();
            log.warn("Initialized ephemeral 2048-bit RSA Key Pair for development/test environment. Do not use in production.");
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("RSA algorithm not supported on this platform", e);
        }
    }

    private RSAPrivateKey loadPrivateKey(String path) throws Exception {
        String pem = readKeyContent(path);
        String cleaned = pem
                .replaceAll("-----BEGIN (RSA )?PRIVATE KEY-----", "")
                .replaceAll("-----END (RSA )?PRIVATE KEY-----", "")
                .replaceAll("\\s+", "");
        byte[] decoded = Base64.getDecoder().decode(cleaned);
        PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(decoded);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return (RSAPrivateKey) kf.generatePrivate(spec);
    }

    private RSAPublicKey loadPublicKey(String path) throws Exception {
        String pem = readKeyContent(path);
        String cleaned = pem
                .replaceAll("-----BEGIN (RSA )?PUBLIC KEY-----", "")
                .replaceAll("-----END (RSA )?PUBLIC KEY-----", "")
                .replaceAll("\\s+", "");
        byte[] decoded = Base64.getDecoder().decode(cleaned);
        X509EncodedKeySpec spec = new X509EncodedKeySpec(decoded);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return (RSAPublicKey) kf.generatePublic(spec);
    }

    private String readKeyContent(String path) throws IOException {
        File file = new File(path);
        if (file.exists()) {
            return Files.readString(file.toPath(), StandardCharsets.UTF_8);
        }
        // Check classpath resource
        try (var is = getClass().getClassLoader().getResourceAsStream(path)) {
            if (is != null) {
                return new String(is.readAllBytes(), StandardCharsets.UTF_8);
            }
        }
        throw new IOException("Key file not found at path: " + path);
    }

    public RSAPublicKey getPublicKey() {
        return (RSAPublicKey) keyPair.getPublic();
    }

    public RSAPrivateKey getPrivateKey() {
        return (RSAPrivateKey) keyPair.getPrivate();
    }
}
