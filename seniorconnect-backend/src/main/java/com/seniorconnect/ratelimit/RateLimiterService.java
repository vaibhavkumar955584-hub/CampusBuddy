package com.seniorconnect.ratelimit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;

@Service
public class RateLimiterService {

    private static final Logger log = LoggerFactory.getLogger(RateLimiterService.class);

    private final StringRedisTemplate redisTemplate;
    // In-memory fallback sliding window cache if Redis is not configured or in tests
    private final ConcurrentHashMap<String, ConcurrentLinkedDeque<Long>> localSlidingWindows = new ConcurrentHashMap<>();

    public RateLimiterService(@Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    /**
     * Checks and consumes a rate-limit allowance in a sliding window.
     *
     * @param key Unique key for the rate limit (e.g. "auth:otp:user@college.edu:127.0.0.1")
     * @param maxRequests Maximum requests allowed within window
     * @param windowSeconds Window duration in seconds
     * @return true if allowed, false if limit exceeded
     */
    public boolean tryAcquire(String key, int maxRequests, long windowSeconds) {
        if (redisTemplate != null) {
            try {
                long now = System.currentTimeMillis();
                long windowStart = now - (windowSeconds * 1000);

                // Redis sliding window using sorted sets
                String redisKey = "ratelimit:" + key;
                redisTemplate.opsForZSet().removeRangeByScore(redisKey, 0, windowStart);
                Long currentCount = redisTemplate.opsForZSet().zCard(redisKey);

                if (currentCount != null && currentCount >= maxRequests) {
                    log.warn("Rate limit exceeded for key: {} (count={}, limit={})", key, currentCount, maxRequests);
                    return false;
                }

                redisTemplate.opsForZSet().add(redisKey, String.valueOf(now) + ":" + Math.random(), now);
                redisTemplate.expire(redisKey, java.time.Duration.ofSeconds(windowSeconds * 2));
                return true;
            } catch (Exception e) {
                log.warn("Redis rate-limiter failed, falling back to in-memory sliding window: {}", e.getMessage());
            }
        }

        // Fallback: Local thread-safe sliding window
        long now = System.currentTimeMillis();
        long windowStart = now - (windowSeconds * 1000);

        ConcurrentLinkedDeque<Long> timestamps = localSlidingWindows.computeIfAbsent(key, k -> new ConcurrentLinkedDeque<>());
        synchronized (timestamps) {
            while (!timestamps.isEmpty() && timestamps.peekFirst() < windowStart) {
                timestamps.pollFirst();
            }
            if (timestamps.size() >= maxRequests) {
                log.warn("Rate limit exceeded (in-memory) for key: {} (count={}, limit={})", key, timestamps.size(), maxRequests);
                return false;
            }
            timestamps.addLast(now);
            return true;
        }
    }

    /**
     * Clears rate limit state for a key (e.g. on successful auth).
     */
    public void reset(String key) {
        if (redisTemplate != null) {
            try {
                redisTemplate.delete("ratelimit:" + key);
            } catch (Exception ignored) {
            }
        }
        localSlidingWindows.remove(key);
    }
}
