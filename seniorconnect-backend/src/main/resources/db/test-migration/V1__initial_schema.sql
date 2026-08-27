-- SeniorConnect Initial Schema (Test In-Memory Database)
-- V1__initial_schema.sql

CREATE TABLE allowed_domains (
    id UUID PRIMARY KEY,
    domain VARCHAR(255) NOT NULL UNIQUE,
    college_name VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(32) NOT NULL,
    branch VARCHAR(100),
    semester INT,
    current_year_of_study INT,
    mentor_eligible BOOLEAN NOT NULL DEFAULT FALSE,
    mentor_mode_active BOOLEAN NOT NULL DEFAULT FALSE,
    admission_year INT,
    is_suspended BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY,
    family_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    device_fingerprint VARCHAR(255),
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_family ON refresh_tokens(family_id);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);

CREATE TABLE queries (
    id UUID PRIMARY KEY,
    junior_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(300) NOT NULL,
    content VARCHAR(5000) NOT NULL,
    tags TEXT ARRAY,
    is_anonymous_display BOOLEAN NOT NULL DEFAULT TRUE,
    status VARCHAR(32) NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_queries_junior ON queries(junior_id);
CREATE INDEX idx_queries_created ON queries(created_at DESC);
CREATE INDEX idx_queries_status ON queries(status);

CREATE TABLE responses (
    id UUID PRIMARY KEY,
    query_id UUID NOT NULL REFERENCES queries(id) ON DELETE CASCADE,
    senior_id UUID NOT NULL REFERENCES users(id),
    content VARCHAR(5000) NOT NULL,
    is_accepted_answer BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_responses_query ON responses(query_id);
CREATE INDEX idx_responses_senior ON responses(senior_id);

CREATE TABLE reveal_requests (
    id UUID PRIMARY KEY,
    query_id UUID NOT NULL REFERENCES queries(id) ON DELETE CASCADE,
    junior_id UUID NOT NULL REFERENCES users(id),
    senior_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_query_senior UNIQUE(query_id, senior_id)
);

CREATE INDEX idx_reveal_query ON reveal_requests(query_id);
CREATE INDEX idx_reveal_senior ON reveal_requests(senior_id);
CREATE INDEX idx_reveal_junior ON reveal_requests(junior_id);

CREATE TABLE reports (
    id UUID PRIMARY KEY,
    reporter_id UUID NOT NULL REFERENCES users(id),
    reported_user_id UUID NOT NULL REFERENCES users(id),
    target_type VARCHAR(32) NOT NULL,
    target_id UUID NOT NULL,
    reason VARCHAR(1000) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reports_reported_user ON reports(reported_user_id);
CREATE INDEX idx_reports_created ON reports(created_at DESC);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    event_type VARCHAR(64) NOT NULL,
    actor_id UUID,
    ip_address VARCHAR(128),
    details VARCHAR(2000),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_actor ON audit_logs(actor_id);
CREATE INDEX idx_audit_event ON audit_logs(event_type);

CREATE TABLE senior_profiles (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    points INT NOT NULL DEFAULT 0,
    placement_tag VARCHAR(255),
    tags TEXT ARRAY,
    badges TEXT ARRAY,
    is_tag_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE verification_requests (
    id UUID PRIMARY KEY,
    senior_id UUID NOT NULL REFERENCES users(id),
    claimed_tag TEXT NOT NULL,
    proof_file_url TEXT NOT NULL,
    ocr_extracted_text TEXT,
    ocr_keyword_match BOOLEAN,
    ocr_confidence_score DOUBLE PRECISION,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_verification_requests_status ON verification_requests(status);
CREATE INDEX idx_verification_requests_senior ON verification_requests(senior_id);

CREATE TABLE mentorship_plans (
    id UUID PRIMARY KEY,
    junior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    senior_id UUID REFERENCES users(id) ON DELETE SET NULL,
    goal_title VARCHAR(200) NOT NULL,
    target_company VARCHAR(100),
    target_role VARCHAR(100),
    duration_days INT NOT NULL DEFAULT 90,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    progress_percentage INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mentorship_plan_tasks (
    id UUID PRIMARY KEY,
    plan_id UUID NOT NULL REFERENCES mentorship_plans(id) ON DELETE CASCADE,
    week_number INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1000),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE mentorship_outcomes (
    id UUID PRIMARY KEY,
    plan_id UUID REFERENCES mentorship_plans(id) ON DELETE SET NULL,
    junior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    senior_id UUID REFERENCES users(id) ON DELETE SET NULL,
    outcome_type VARCHAR(50) NOT NULL,
    company VARCHAR(100),
    role VARCHAR(100),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    proof_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mentorship_plans_junior ON mentorship_plans(junior_id);
CREATE INDEX idx_mentorship_plans_senior ON mentorship_plans(senior_id);
CREATE INDEX idx_mentorship_tasks_plan ON mentorship_plan_tasks(plan_id);
CREATE INDEX idx_mentorship_outcomes_junior ON mentorship_outcomes(junior_id);
CREATE INDEX idx_mentorship_outcomes_senior ON mentorship_outcomes(senior_id);

CREATE TABLE mentorship_sessions (
    id UUID PRIMARY KEY,
    junior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    senior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    query_id UUID REFERENCES queries(id) ON DELETE SET NULL,
    plan_id UUID REFERENCES mentorship_plans(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    privacy_level INT NOT NULL DEFAULT 3,
    meeting_link VARCHAR(500),
    session_notes VARCHAR(1000),
    scheduled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_session_pair UNIQUE (junior_id, senior_id)
);

CREATE TABLE mentorship_session_messages (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES mentorship_sessions(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_content VARCHAR(4000) NOT NULL,
    is_encrypted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mentorship_sessions_junior ON mentorship_sessions(junior_id);
CREATE INDEX idx_mentorship_sessions_senior ON mentorship_sessions(senior_id);
CREATE INDEX idx_session_messages_session ON mentorship_session_messages(session_id);

CREATE TABLE mentorship_reviews (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES mentorship_sessions(id) ON DELETE CASCADE,
    junior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    senior_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_comment VARCHAR(1000),
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_session_review UNIQUE (session_id)
);

CREATE INDEX idx_mentorship_reviews_senior ON mentorship_reviews(senior_id);
CREATE INDEX idx_mentorship_reviews_junior ON mentorship_reviews(junior_id);

INSERT INTO allowed_domains (id, domain, college_name, is_active, created_at)
VALUES ('00000000-0000-0000-0000-000000000001', 'galgotiacollege.edu.in', 'Galgotias College of Engineering and Technology', TRUE, CURRENT_TIMESTAMP);
INSERT INTO allowed_domains (id, domain, college_name, is_active, created_at)
VALUES ('00000000-0000-0000-0000-000000000002', 'galgotiacollege.edu', 'Galgotias College of Engineering and Technology', TRUE, CURRENT_TIMESTAMP);
INSERT INTO allowed_domains (id, domain, college_name, is_active, created_at)
VALUES ('00000000-0000-0000-0000-000000000003', 'campus.edu', 'Test Campus Institution', TRUE, CURRENT_TIMESTAMP);
