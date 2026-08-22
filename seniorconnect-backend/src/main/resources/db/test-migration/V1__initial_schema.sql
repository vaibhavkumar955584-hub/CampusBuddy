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
    tags VARCHAR(500),
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
    is_tag_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO allowed_domains (id, domain, college_name, is_active, created_at)
VALUES ('00000000-0000-0000-0000-000000000001', 'galgotiacollege.edu.in', 'Galgotias College of Engineering and Technology', TRUE, CURRENT_TIMESTAMP);
INSERT INTO allowed_domains (id, domain, college_name, is_active, created_at)
VALUES ('00000000-0000-0000-0000-000000000002', 'galgotiacollege.edu', 'Galgotias College of Engineering and Technology', TRUE, CURRENT_TIMESTAMP);
INSERT INTO allowed_domains (id, domain, college_name, is_active, created_at)
VALUES ('00000000-0000-0000-0000-000000000003', 'campus.edu', 'Test Campus Institution', TRUE, CURRENT_TIMESTAMP);
