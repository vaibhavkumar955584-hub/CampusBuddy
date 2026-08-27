-- CampusBuddy V2 Mentorship Plans and Outcomes Migration
-- V8__mentorship_plans_and_outcomes.sql

CREATE TABLE IF NOT EXISTS mentorship_plans (
    id UUID PRIMARY KEY,
    junior_id UUID NOT NULL REFERENCES users(id),
    senior_id UUID REFERENCES users(id),
    goal_title VARCHAR(200) NOT NULL,
    target_company VARCHAR(100),
    target_role VARCHAR(100),
    duration_days INTEGER NOT NULL DEFAULT 90,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    progress_percentage INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS mentorship_plan_tasks (
    id UUID PRIMARY KEY,
    plan_id UUID NOT NULL REFERENCES mentorship_plans(id) ON DELETE CASCADE,
    week_number INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1000),
    is_completed BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS mentorship_outcomes (
    id UUID PRIMARY KEY,
    plan_id UUID REFERENCES mentorship_plans(id),
    junior_id UUID NOT NULL REFERENCES users(id),
    senior_id UUID REFERENCES users(id),
    outcome_type VARCHAR(50) NOT NULL,
    company VARCHAR(100),
    role VARCHAR(100),
    is_verified BOOLEAN NOT NULL DEFAULT false,
    proof_url VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mentorship_plans_junior ON mentorship_plans(junior_id);
CREATE INDEX IF NOT EXISTS idx_mentorship_plans_senior ON mentorship_plans(senior_id);
CREATE INDEX IF NOT EXISTS idx_mentorship_tasks_plan ON mentorship_plan_tasks(plan_id);
CREATE INDEX IF NOT EXISTS idx_mentorship_outcomes_junior ON mentorship_outcomes(junior_id);
CREATE INDEX IF NOT EXISTS idx_mentorship_outcomes_senior ON mentorship_outcomes(senior_id);
