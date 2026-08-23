package com.seniorconnect.verification.service;

import net.sourceforge.tess4j.ITesseract;
import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.util.concurrent.*;

@Service
public class ProofOcrService {

    private static final Logger log = LoggerFactory.getLogger(ProofOcrService.class);
    private final ExecutorService ocrExecutor = Executors.newFixedThreadPool(2);

    @Value("${seniorconnect.ocr.tessdata-path:}")
    private String configuredTessdataPath;

    @Value("${seniorconnect.ocr.timeout-seconds:15}")
    private int timeoutSeconds;

    public record OcrResult(String text, Double confidenceScore, boolean success) {
        public static OcrResult empty() {
            return new OcrResult(null, null, false);
        }

        public static OcrResult of(String text, Double confidence) {
            return new OcrResult(text, confidence, true);
        }
    }

    /**
     * Extracts text and confidence score from image bytes via Tesseract OCR.
     * Wrapped in a timeout. Fails gracefully if Tesseract is unconfigured or image is invalid.
     */
    public OcrResult extractText(byte[] imageBytes) {
        if (imageBytes == null || imageBytes.length == 0) {
            return OcrResult.empty();
        }

        Future<OcrResult> future = ocrExecutor.submit(() -> doExtract(imageBytes));
        try {
            return future.get(timeoutSeconds, TimeUnit.SECONDS);
        } catch (TimeoutException te) {
            log.warn("OCR processing timed out after {} seconds. Proceeding with null OCR context.", timeoutSeconds);
            future.cancel(true);
            return OcrResult.empty();
        } catch (Exception e) {
            log.warn("OCR execution failed gracefully: {}. Proceeding without OCR text.", e.getMessage());
            return OcrResult.empty();
        }
    }

    private OcrResult doExtract(byte[] imageBytes) {
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (image == null) {
                log.info("ImageIO could not decode image bytes (possibly corrupted or non-image format).");
                return OcrResult.empty();
            }

            ITesseract tesseract = new Tesseract();
            if (configuredTessdataPath != null && !configuredTessdataPath.isBlank()) {
                tesseract.setDatapath(configuredTessdataPath);
            }
            tesseract.setLanguage("eng");

            String rawText = tesseract.doOCR(image);
            if (rawText == null || rawText.isBlank()) {
                return new OcrResult("", 0.0, true);
            }

            String cleanedText = rawText.trim();
            // Estimate confidence baseline (Tess4J returns cleaned text)
            double confidence = Math.min(100.0, Math.max(50.0, cleanedText.length() * 2.0));

            log.info("OCR Extraction completed successfully. Extracted {} characters.", cleanedText.length());
            return OcrResult.of(cleanedText, confidence);
        } catch (TesseractException te) {
            log.warn("Tesseract native OCR engine failed: {}", te.getMessage());
            return OcrResult.empty();
        } catch (Throwable t) {
            log.warn("Unexpected OCR failure (e.g. missing native tesseract library): {}", t.getMessage());
            return OcrResult.empty();
        }
    }
}
