-- SeniorConnect Migration V4: Native TEXT[] tags, GIN indexes, and gamification badges
-- V4__native_tags_and_badges.sql

-- 1. Convert queries.tags from VARCHAR(500) to native TEXT[] array
ALTER TABLE queries 
ALTER COLUMN tags TYPE TEXT[] 
USING CASE 
    WHEN tags IS NULL OR TRIM(tags) = '' THEN ARRAY[]::TEXT[] 
    ELSE string_to_array(tags, ',') 
END;

-- 2. Add native tags TEXT[] column to senior_profiles and migrate placement_tag data
ALTER TABLE senior_profiles 
ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';

UPDATE senior_profiles 
SET tags = ARRAY[placement_tag]::TEXT[] 
WHERE placement_tag IS NOT NULL AND TRIM(placement_tag) != '' AND tags = '{}';

-- 3. Add badges TEXT[] column to senior_profiles for gamification system
ALTER TABLE senior_profiles 
ADD COLUMN IF NOT EXISTS badges TEXT[] NOT NULL DEFAULT '{}';

-- 4. Create GIN Indexes for high-performance array containment and overlap queries
CREATE INDEX IF NOT EXISTS idx_queries_tags ON queries USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_senior_profiles_tags ON senior_profiles USING GIN (tags);
