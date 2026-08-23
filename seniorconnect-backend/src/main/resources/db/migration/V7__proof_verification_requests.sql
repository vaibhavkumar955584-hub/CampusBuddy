-- SeniorConnect Proof Verification Requests Migration
-- V7__proof_verification_requests.sql

CREATE TABLE IF NOT EXISTS verification_requests (
    id UUID PRIMARY KEY,
    senior_id UUID NOT NULL REFERENCES users(id),
    claimed_tag TEXT NOT NULL,
    proof_file_url TEXT NOT NULL,
    ocr_extracted_text TEXT,
    ocr_keyword_match BOOLEAN,
    ocr_confidence_score DOUBLE PRECISION,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON verification_requests(status);
CREATE INDEX IF NOT EXISTS idx_verification_requests_senior ON verification_requests(senior_id);
