package com.seniorconnect.verification.service;

import com.seniorconnect.common.exception.AppException;
import org.apache.tika.Tika;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ProofStorageService {

    private static final Logger log = LoggerFactory.getLogger(ProofStorageService.class);
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
    private static final Set<String> ALLOWED_MIME_TYPES = Set.of("image/jpeg", "image/png", "application/pdf");

    private final Tika tika = new Tika();
    private final Path storageDir;

    // In-memory token-to-filepath map for short-lived signed access URLs (TTL 15 mins)
    private final Map<String, SignedUrlEntry> signedUrlTokens = new ConcurrentHashMap<>();

    private record SignedUrlEntry(String filePath, long expiresAtMillis) {}

    public ProofStorageService(@Value("${seniorconnect.storage.proof-dir:uploads/proofs}") String uploadDir) {
        this.storageDir = Paths.get(uploadDir).toAbsolutePath();
        try {
            Files.createDirectories(this.storageDir);
        } catch (IOException e) {
            log.warn("Could not create proof storage directory: {}", e.getMessage());
        }
    }

    /**
     * Inspects magic-byte MIME type, strips EXIF metadata for images, and persists securely.
     * Returns the relative file storage key.
     */
    public String storeProofFile(byte[] rawBytes, String originalFilename) {
        if (rawBytes == null || rawBytes.length == 0) {
            throw AppException.badRequest("Uploaded proof file cannot be empty", "EMPTY_FILE");
        }
        if (rawBytes.length > MAX_FILE_SIZE) {
            throw AppException.badRequest("Proof file exceeds maximum size of 5MB", "FILE_TOO_LARGE");
        }

        // 1. Content-based MIME inspection (magic bytes via Apache Tika)
        String detectedMimeType = tika.detect(rawBytes);
        if (!ALLOWED_MIME_TYPES.contains(detectedMimeType)) {
            log.warn("MIME inspection rejected uploaded file. Detected MIME: {}", detectedMimeType);
            throw AppException.badRequest("Invalid file format. Allowed types: JPEG, PNG, PDF. Detected: " + detectedMimeType, "INVALID_FILE_TYPE");
        }

        // 2. EXIF metadata stripping for JPEG/PNG images
        byte[] sanitizedBytes = rawBytes;
        String extension = "pdf";
        if (detectedMimeType.equals("image/jpeg") || detectedMimeType.equals("image/png")) {
            extension = detectedMimeType.equals("image/png") ? "png" : "jpg";
            try {
                BufferedImage image = ImageIO.read(new ByteArrayInputStream(rawBytes));
                if (image != null) {
                    ByteArrayOutputStream os = new ByteArrayOutputStream();
                    ImageIO.write(image, extension, os);
                    sanitizedBytes = os.toByteArray();
                    log.debug("EXIF metadata stripped successfully via ImageIO re-encoding.");
                }
            } catch (Exception e) {
                log.warn("Could not re-encode image for EXIF stripping: {}. Using raw bytes.", e.getMessage());
            }
        }

        // 3. Write to storage with randomized UUID filename
        String storageKey = UUID.randomUUID() + "." + extension;
        Path targetPath = storageDir.resolve(storageKey);
        try {
            Files.write(targetPath, sanitizedBytes, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            return storageKey;
        } catch (IOException e) {
            log.error("Failed to store proof file on disk: {}", e.getMessage(), e);
            throw AppException.internalError("Failed to store uploaded proof file");
        }
    }

    /**
     * Generates a short-lived signed URL for admin viewing (TTL 15 minutes).
     */
    public String generateSignedUrl(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            return null;
        }
        String token = UUID.randomUUID().toString().replace("-", "");
        long expiresAt = System.currentTimeMillis() + (15 * 60 * 1000); // 15 mins
        signedUrlTokens.put(token, new SignedUrlEntry(storageKey, expiresAt));

        return "/api/v1/admin/verification-requests/proof-view/" + storageKey + "?token=" + token;
    }

    /**
     * Resolves and verifies short-lived token for file retrieval.
     */
    public byte[] loadProofFile(String storageKey, String token) {
        SignedUrlEntry entry = signedUrlTokens.get(token);
        if (entry == null || entry.expiresAtMillis < System.currentTimeMillis() || !entry.filePath.equals(storageKey)) {
            throw AppException.forbidden("Signed URL has expired or is invalid", "INVALID_SIGNED_URL");
        }

        Path filePath = storageDir.resolve(storageKey).normalize();
        if (!filePath.startsWith(storageDir)) {
            throw AppException.forbidden("Invalid file path", "SECURITY_VIOLATION");
        }

        try {
            if (!Files.exists(filePath)) {
                throw AppException.notFound("Proof file not found", "FILE_NOT_FOUND");
            }
            return Files.readAllBytes(filePath);
        } catch (IOException e) {
            throw AppException.internalError("Could not read proof file");
        }
    }
}
