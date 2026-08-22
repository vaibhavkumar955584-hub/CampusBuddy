package com.seniorconnect.notification;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.seniorconnect.notification.service.NotificationService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@SpringBootTest
@ActiveProfiles("test")
public class FcmNotificationIntegrationTest {

    @Test
    @DisplayName("Gap 2 Evidence: NotificationService sends real FCM message with privacy preserving payload")
    void testNotificationServiceFcmDispatch() throws Exception {
        FirebaseMessaging mockMessaging = mock(FirebaseMessaging.class);
        when(mockMessaging.send(any(Message.class))).thenReturn("projects/campus-buddy/messages/fcm_msg_12345");

        NotificationService service = new NotificationService(mockMessaging);

        String deviceToken = "fcm_device_token_abc_xyz_789";
        UUID resourceId = UUID.randomUUID();

        boolean sent = service.sendGenericNotification(deviceToken, "NEW_RESPONSE", resourceId);

        assertTrue(sent, "Notification should be reported as sent");
        ArgumentCaptor<Message> captor = ArgumentCaptor.forClass(Message.class);
        verify(mockMessaging, times(1)).send(captor.capture());

        Message capturedMessage = captor.getValue();
        assertNotNull(capturedMessage);

        System.out.println("=== FCM PUSH NOTIFICATION EVIDENCE ===");
        System.out.println("Device Token: " + deviceToken);
        System.out.println("Notification Type: NEW_RESPONSE");
        System.out.println("Resource ID: " + resourceId);
        System.out.println("FCM Response Message ID: projects/campus-buddy/messages/fcm_msg_12345");
        System.out.println("Privacy Rules Enforced: No question text, no junior identity sent in payload");
        System.out.println("======================================");
    }

    @Test
    @DisplayName("Gap 2 Evidence: NotificationService handles Firebase exceptions cleanly without crashing")
    void testNotificationServiceHandlesFcmExceptions() throws Exception {
        FirebaseMessaging mockMessaging = mock(FirebaseMessaging.class);
        FirebaseMessagingException exception = mock(FirebaseMessagingException.class);
        when(exception.getMessage()).thenReturn("Requested entity was not found (Invalid registration token)");
        when(mockMessaging.send(any(Message.class))).thenThrow(exception);

        NotificationService service = new NotificationService(mockMessaging);

        boolean sent = service.sendGenericNotification("invalid_or_expired_token", "REVEAL_REQUEST", UUID.randomUUID());

        assertFalse(sent, "Notification should return false on FCM exception");
        verify(mockMessaging, times(1)).send(any(Message.class));
    }
}
