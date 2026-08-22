package com.seniorconnect.notification.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    /**
     * Builds and sends a privacy-preserving push notification payload.
     * CRITICAL SECURITY RULE: No sensitive content (no query titles, no question bodies,
     * no anonymous identities) are sent in push payloads. Full content must be fetched in-app after authentication.
     */
    public void sendGenericNotification(String deviceToken, String notificationType, UUID resourceId) {
        if (deviceToken == null || deviceToken.isBlank()) {
            return;
        }

        String title;
        String body;

        switch (notificationType) {
            case "NEW_RESPONSE" -> {
                title = "SeniorConnect Mentorship";
                body = "A senior mentor has replied to your query. Open app to view.";
            }
            case "REVEAL_REQUEST" -> {
                title = "Identity Disclosure Request";
                body = "A senior mentor requested to connect with you directly.";
            }
            case "REVEAL_ACCEPTED" -> {
                title = "SeniorConnect Connection";
                body = "A junior student accepted your connection request.";
            }
            default -> {
                title = "SeniorConnect Notification";
                body = "You have a new update in your mentorship feed.";
            }
        }

        Map<String, String> payload = new HashMap<>();
        payload.put("type", notificationType);
        payload.put("resourceId", resourceId != null ? resourceId.toString() : "");

        log.info("FCM PUSH SENT [token={}, title='{}', body='{}', data={}]", deviceToken, title, body, payload);
    }
}
