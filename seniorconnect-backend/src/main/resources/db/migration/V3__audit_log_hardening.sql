-- SeniorConnect Audit Log Hardening Migration
-- V3__audit_log_hardening.sql

-- 1. Create a trigger function that strictly prevents any UPDATE or DELETE on audit_logs
CREATE OR REPLACE FUNCTION prevent_audit_logs_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'SECURITY VIOLATION: audit_logs table is strictly append-only. UPDATE and DELETE operations are forbidden at database level.';
END;
$$ LANGUAGE plpgsql;

-- 2. Bind the trigger to before UPDATE or DELETE on audit_logs
DROP TRIGGER IF EXISTS trg_prevent_audit_logs_mutation ON audit_logs;
CREATE TRIGGER trg_prevent_audit_logs_mutation
    BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION prevent_audit_logs_mutation();

-- 3. Revoke UPDATE and DELETE permissions from standard roles
REVOKE UPDATE, DELETE ON audit_logs FROM PUBLIC;
