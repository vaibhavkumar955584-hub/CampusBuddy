package com.seniorconnect.ratelimit;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@SpringBootTest
@ActiveProfiles("test")
public class RateLimiterDegradationIntegrationTest {

    @Test
    @DisplayName("Gap 3 Evidence: Rate limiter engages fallback on Redis failure, enforces limit, and cleans up memory")
    void testRedisDegradationAndMemoryCleanup() throws Exception {
        // 1. Setup mock RedisTemplate that fails with RedisConnectionFailureException
        StringRedisTemplate mockRedis = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ZSetOperations<String, String> mockZSet = mock(ZSetOperations.class);
        when(mockRedis.opsForZSet()).thenReturn(mockZSet);
        when(mockZSet.removeRangeByScore(anyString(), anyDouble(), anyDouble()))
                .thenThrow(new RedisConnectionFailureException("Simulated Redis connection timeout mid-flight"));

        RateLimiterService rateLimiter = new RateLimiterService(mockRedis);

        String testKey = "auth:otp:degrade_test@college.edu";
        int limit = 3;
        long windowSeconds = 2;

        // 2. Consume allowed limit (3 requests)
        assertTrue(rateLimiter.tryAcquire(testKey, limit, windowSeconds), "1st request should be allowed under fallback");
        assertTrue(rateLimiter.tryAcquire(testKey, limit, windowSeconds), "2nd request should be allowed under fallback");
        assertTrue(rateLimiter.tryAcquire(testKey, limit, windowSeconds), "3rd request should be allowed under fallback");

        // 3. 4th request must be rate-limited by the in-memory fallback
        assertFalse(rateLimiter.tryAcquire(testKey, limit, windowSeconds), "4th request must be blocked by in-memory rate limit");
        System.out.println("=== GAP 3 EVIDENCE: REDIS OUTAGE DEGRADATION ENFORCED ===");
        System.out.println("Key: " + testKey + " -> Allowed 3 requests, successfully blocked 4th request");

        // 4. Test Unbounded Map Growth Prevention: Populate 50 distinct keys
        for (int i = 0; i < 50; i++) {
            rateLimiter.tryAcquire("user_session_" + i, 5, 1);
        }
        assertTrue(rateLimiter.getLocalSlidingWindowsCount() >= 50, "Map should contain entries for active keys");

        // Trigger cleanup with maxAge 0ms (simulating expired windows)
        Thread.sleep(20);
        rateLimiter.cleanupExpiredWindows(0L);

        // Verify map is pruned and does not leak memory
        assertEquals(0, rateLimiter.getLocalSlidingWindowsCount(), "All expired windows must be pruned from map");
        System.out.println("=== GAP 3 EVIDENCE: PERIODIC MAP CLEANUP SUCCESSFUL ===");
        System.out.println("Map size after cleanup of expired keys: " + rateLimiter.getLocalSlidingWindowsCount() + " entries");
    }
}
