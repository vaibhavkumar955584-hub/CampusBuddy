-- SeniorConnect Row-Level Security Migration
-- V2__row_level_security.sql

-- Enable RLS on core tables
ALTER TABLE queries ENABLE ROW LEVEL SECURITY;
ALTER TABLE responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE reveal_requests ENABLE ROW LEVEL SECURITY;

--------------------------------------------------------------------------------
-- 1. QUERIES POLICIES
--------------------------------------------------------------------------------

-- Anyone authenticated can view open/resolved queries in the campus feed, or the author can view their own
CREATE POLICY queries_select_policy ON queries
    FOR SELECT
    USING (
        status != 'DELETED'
        OR junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only the owning junior can create queries under their junior_id
CREATE POLICY queries_insert_policy ON queries
    FOR INSERT
    WITH CHECK (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only the owning junior or an ADMIN can update queries
CREATE POLICY queries_update_policy ON queries
    FOR UPDATE
    USING (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    )
    WITH CHECK (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only the owning junior or an ADMIN can delete queries
CREATE POLICY queries_delete_policy ON queries
    FOR DELETE
    USING (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

--------------------------------------------------------------------------------
-- 2. RESPONSES POLICIES
--------------------------------------------------------------------------------

-- Public read for responses on active queries
CREATE POLICY responses_select_policy ON responses
    FOR SELECT
    USING (
        senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
        OR EXISTS (
            SELECT 1 FROM queries q
            WHERE q.id = responses.query_id
            AND q.status != 'DELETED'
        )
    );

-- Only the verified senior can insert a response under their senior_id
CREATE POLICY responses_insert_policy ON responses
    FOR INSERT
    WITH CHECK (
        senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only the senior author or ADMIN can update a response
CREATE POLICY responses_update_policy ON responses
    FOR UPDATE
    USING (
        senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    )
    WITH CHECK (
        senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only the senior author or ADMIN can delete a response
CREATE POLICY responses_delete_policy ON responses
    FOR DELETE
    USING (
        senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

--------------------------------------------------------------------------------
-- 3. REVEAL REQUESTS POLICIES (IDOR-Guarded)
--------------------------------------------------------------------------------

-- Reveal requests can ONLY be viewed by the involved junior, senior, or an ADMIN
CREATE POLICY reveal_requests_select_policy ON reveal_requests
    FOR SELECT
    USING (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only the requesting senior or an ADMIN can create a reveal request
CREATE POLICY reveal_requests_insert_policy ON reveal_requests
    FOR INSERT
    WITH CHECK (
        senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only the involved junior (to accept/reject) or senior (to cancel) or ADMIN can update
CREATE POLICY reveal_requests_update_policy ON reveal_requests
    FOR UPDATE
    USING (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    )
    WITH CHECK (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );

-- Only involved parties or ADMIN can delete a reveal request
CREATE POLICY reveal_requests_delete_policy ON reveal_requests
    FOR DELETE
    USING (
        junior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR senior_id = NULLIF(current_setting('app.current_user_id', true), '')::uuid
        OR current_setting('app.current_user_role', true) = 'ADMIN'
    );
