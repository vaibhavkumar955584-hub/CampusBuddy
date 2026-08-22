package com.seniorconnect.notification.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${seniorconnect.firebase.credentials-path:}")
    private String credentialsPath;

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        FirebaseApp app = getOrInitFirebaseApp();
        if (app != null) {
            return FirebaseMessaging.getInstance(app);
        }
        return null;
    }

    private synchronized FirebaseApp getOrInitFirebaseApp() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.getInstance();
        }

        String path = credentialsPath;
        if (path == null || path.isBlank()) {
            path = System.getenv("FIREBASE_CREDENTIALS_PATH");
        }
        if (path == null || path.isBlank()) {
            path = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
        }

        if (path != null && !path.isBlank()) {
            File credFile = new File(path);
            if (credFile.exists() && credFile.isFile()) {
                try (InputStream serviceAccount = new FileInputStream(credFile)) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();
                    FirebaseApp app = FirebaseApp.initializeApp(options);
                    log.info("FirebaseApp successfully initialized with credentials from: {}", path);
                    return app;
                } catch (IOException e) {
                    log.error("Failed to initialize FirebaseApp with credentials at {}: {}", path, e.getMessage());
                }
            } else {
                log.warn("Firebase credentials file specified at '{}' was not found.", path);
            }
        } else {
            log.info("No Firebase credentials path configured (seniorconnect.firebase.credentials-path / FIREBASE_CREDENTIALS_PATH). FCM push notifications will run in fallback mode.");
        }

        return null;
    }
}
