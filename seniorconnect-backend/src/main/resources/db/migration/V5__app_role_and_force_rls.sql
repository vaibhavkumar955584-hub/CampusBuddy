-- SeniorConnect App Role & Force RLS Migration
-- V5__app_role_and_force_rls.sql

-- 1. Explicitly force Row-Level Security on core tables to close non-owner elevation bypasses
ALTER TABLE queries FORCE ROW LEVEL SECURITY;
ALTER TABLE responses FORCE ROW LEVEL SECURITY;
ALTER TABLE reveal_requests FORCE ROW LEVEL SECURITY;

-- 2. Create dedicated, least-privileged runtime application role
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'seniorconnect_app') THEN
        CREATE ROLE seniorconnect_app LOGIN PASSWORD 'seniorconnect_app_secret' NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE;
    END IF;
END
$$;

-- 3. Grant schema and table access to the runtime role dynamically on current database
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO seniorconnect_app', current_database());
END
$$;

GRANT USAGE ON SCHEMA public TO seniorconnect_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO seniorconnect_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO seniorconnect_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO seniorconnect_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO seniorconnect_app;

-- 4. Strictly revoke UPDATE and DELETE permissions on audit_logs from seniorconnect_app
REVOKE UPDATE, DELETE ON audit_logs FROM seniorconnect_app;
