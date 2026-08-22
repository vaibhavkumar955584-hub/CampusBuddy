package com.seniorconnect.notification.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final FirebaseMessaging firebaseMessaging;

    public NotificationService(@Autowired(required = false) FirebaseMessaging firebaseMessaging) {
        this.firebaseMessaging = firebaseMessaging;
    }

    /**
     * Builds and sends a privacy-preserving push notification payload.
     * CRITICAL SECURITY RULE: No sensitive content (no query titles, no question bodies,
     * no anonymous identities) are sent in push payloads. Full content must be fetched in-app after authentication.
     */
    public boolean sendGenericNotification(String deviceToken, String notificationType, UUID resourceId) {
        if (deviceToken == null || deviceToken.isBlank()) {
            log.warn("Cannot send push notification: Device token is empty");
            return false;
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
        payload.put("type", notificationType != null ? notificationType : "GENERIC");
        payload.put("resourceId", resourceId != null ? resourceId.toString() : "");

        Notification fcmNotification = Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build();

        Message message = Message.builder()
                .setToken(deviceToken)
                .setNotification(fcmNotification)
                .putAllData(payload)
                .build();

        if (firebaseMessaging != null) {
            try {
                String messageId = firebaseMessaging.send(message);
                log.info("FCM PUSH SENT SUCCESS [messageId={}, token={}, title='{}', type={}]",
                        messageId, deviceToken, title, notificationType);
                return true;
            } catch (FirebaseMessagingException e) {
                log.error("FCM PUSH FAILED [errorCode={}, message={}, token={}]",
                        e.getMessagingErrorCode(), e.getMessage(), deviceToken);
                return false;
            } catch (Exception e) {
                log.error("Unexpected error sending FCM notification to token {}: {}", deviceToken, e.getMessage(), e);
                return false;
            }
        } else {
            log.warn("FCM push notification NOT sent: FirebaseMessaging is not initialized/configured. [token={}, title='{}', type={}]",
                    deviceToken, title, notificationType);
            return false;
        }
    }
}
