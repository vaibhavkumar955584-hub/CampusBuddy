-- CampusBuddy V2 Mentorship Sessions and 1-on-1 Chat Migration
-- V9__mentorship_sessions_and_chat.sql

CREATE TABLE IF NOT EXISTS mentorship_sessions (
    id UUID PRIMARY KEY,
    junior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    senior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    query_id UUID REFERENCES queries(id) ON DELETE SET NULL,
    plan_id UUID REFERENCES mentorship_plans(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    privacy_level INTEGER NOT NULL DEFAULT 3,
    meeting_link VARCHAR(500),
    session_notes VARCHAR(1000),
    scheduled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_session_pair UNIQUE (junior_id, senior_id)
);

CREATE TABLE IF NOT EXISTS mentorship_session_messages (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES mentorship_sessions(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_content VARCHAR(4000) NOT NULL,
    is_encrypted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mentorship_sessions_junior ON mentorship_sessions(junior_id);
CREATE INDEX IF NOT EXISTS idx_mentorship_sessions_senior ON mentorship_sessions(senior_id);
CREATE INDEX IF NOT EXISTS idx_session_messages_session ON mentorship_session_messages(session_id);
