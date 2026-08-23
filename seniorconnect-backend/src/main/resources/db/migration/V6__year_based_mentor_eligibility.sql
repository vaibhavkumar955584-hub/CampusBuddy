-- SeniorConnect Year-Based Mentor Eligibility Migration
-- V6__year_based_mentor_eligibility.sql

ALTER TABLE users ADD COLUMN IF NOT EXISTS current_year_of_study INT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS mentor_eligible BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS mentor_mode_active BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS admission_year INT;
