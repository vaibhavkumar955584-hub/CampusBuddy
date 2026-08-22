package com.seniorconnect.common.util;

import org.jsoup.Jsoup;
import org.jsoup.safety.Safelist;

public final class SanitizerUtil {

    private SanitizerUtil() {}

    /**
     * Strips all HTML tags and dangerous characters to prevent Stored XSS.
     */
    public static String sanitizeText(String input) {
        if (input == null) {
            return null;
        }
        // Safelist.none() strips all HTML tags leaving clean plain text
        return Jsoup.clean(input.trim(), Safelist.none());
    }

    /**
     * Sanitizes comma-separated tags
     */
    public static String sanitizeTags(String tags) {
        if (tags == null) {
            return null;
        }
        return Jsoup.clean(tags.trim(), Safelist.none());
    }
}
