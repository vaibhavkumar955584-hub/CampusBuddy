-- CampusBuddy V2 Mentorship Reviews and Feedback Migration
-- V10__mentorship_reviews.sql

CREATE TABLE IF NOT EXISTS mentorship_reviews (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES mentorship_sessions(id) ON DELETE CASCADE,
    junior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    senior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_comment VARCHAR(1000),
    is_public BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_session_review UNIQUE (session_id)
);

CREATE INDEX IF NOT EXISTS idx_mentorship_reviews_senior ON mentorship_reviews(senior_id);
CREATE INDEX IF NOT EXISTS idx_mentorship_reviews_junior ON mentorship_reviews(junior_id);
