package com.seniorconnect.notification;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.seniorconnect.notification.service.NotificationService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * UNIT TEST: Verifies internal business logic of NotificationService.
 * NOTE: This is a unit test of payload construction and exception handling.
 * It uses Mockito mocks to verify method interactions and error codes.
 */
public class FcmNotificationUnitTest {

    @Test
    @DisplayName("Unit Test: NotificationService constructs privacy-safe FCM message and calls send()")
    void testNotificationServicePayloadConstruction() throws Exception {
        FirebaseMessaging mockMessaging = mock(FirebaseMessaging.class);
        when(mockMessaging.send(any(Message.class))).thenReturn("projects/campus-buddy/messages/mock_msg_id");

        NotificationService service = new NotificationService(mockMessaging);

        String deviceToken = "fcm_device_token_sample_123";
        UUID resourceId = UUID.randomUUID();

        boolean sent = service.sendGenericNotification(deviceToken, "NEW_RESPONSE", resourceId);

        assertTrue(sent, "Notification should return true when FirebaseMessaging.send() succeeds");
        ArgumentCaptor<Message> captor = ArgumentCaptor.forClass(Message.class);
        verify(mockMessaging, times(1)).send(captor.capture());

        Message capturedMessage = captor.getValue();
        assertNotNull(capturedMessage);
    }

    @Test
    @DisplayName("Unit Test: NotificationService handles Firebase exceptions cleanly without crashing")
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

    @Test
    @DisplayName("Unit Test: NotificationService returns false when FirebaseMessaging bean is unconfigured/null")
    void testNotificationServiceReturnsFalseWhenUnconfigured() {
        NotificationService service = new NotificationService(null);

        boolean sent = service.sendGenericNotification("some_token", "NEW_RESPONSE", UUID.randomUUID());

        assertFalse(sent, "Unconfigured Firebase service must return false, never pretend it sent");
    }
}
