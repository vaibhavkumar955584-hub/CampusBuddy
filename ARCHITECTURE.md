# SeniorConnect — Final Production Architecture Design

## 1. Architecture Goal

SeniorConnect is a production-grade campus mentorship and document/OCR verification platform featuring:
* Secure authentication, token rotation, and identity masking
* Transactional, consent-gated identity reveals
* Multi-modal OCR proof processing for mentor tag verification
* PostgreSQL with Row-Level Security (RLS) and unprivileged application runtime role
* Containerized Alpine Linux runtime with native Tesseract OCR integration
* Auditable event logging and strict boundary separation
* Reproducible production container verification

---

## 2. High-Level Architecture

```text
                         ┌──────────────────────┐
                         │      Client Apps     │
                         │ Web / Mobile / Admin │
                         └──────────┬───────────┘
                                    │
                             HTTPS / JSON
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │   Reverse Proxy /    │
                         │   API Gateway / TLS  │
                         └──────────┬───────────┘
                                    │
                                    ▼
                    ┌────────────────────────────────┐
                    │       SeniorConnect API        │
                    │        Spring Boot 3.x         │
                    │                                │
                    │  ┌──────────────────────────┐  │
                    │  │ Security / Auth (RS256)  │  │
                    │  ├──────────────────────────┤  │
                    │  │ REST Controllers         │  │
                    │  ├──────────────────────────┤  │
                    │  │ Application Services     │  │
                    │  ├──────────────────────────┤  │
                    │  │ OCR Orchestration        │  │
                    │  ├──────────────────────────┤  │
                    │  │ Document / Proof Mgmt    │  │
                    │  └──────────────────────────┘  │
                    └───────────────┬────────────────┘
                                    │
                   ┌────────────────┼────────────────┐
                   │                │                │
                   ▼                ▼                ▼
             ┌───────────┐   ┌─────────────┐  ┌──────────────┐
             │ PostgreSQL│   │ File/Object │  │ OCR Engine   │
             │           │   │ Storage     │  │ Tesseract    │
             │ RLS       │   │             │  │ / Tess4J     │
             └───────────┘   └─────────────┘  └──────────────┘
                   │
                   ▼
             Audit / Metadata
```

---

## 3. Core Architectural Principles

### 3.1 API is the Primary Security Boundary
* Direct client access to Firestore or PostgreSQL is decommissioned/blocked (`firestore.rules` enforces `allow read, write: if false;`).
* All operations route through Spring Boot REST APIs (`ApiClient`), enforcing JWT cryptographic validation, rate-limiting, and IDOR protection.

### 3.2 PostgreSQL RLS as Defense in Depth
* Core tables (`queries`, `responses`, `reveal_requests`) enforce Row-Level Security (`FORCE ROW LEVEL SECURITY`).
* Dedicated, least-privileged runtime database user `seniorconnect_app` (`NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE`).
* Immutable audit logs (`audit_logs`) have `UPDATE` and `DELETE` strictly revoked.

---

## 4. OCR & Verification Architecture

```text
Senior Uploads Proof (PNG/JPG/PDF)
        ↓
Apache Tika Magic-Byte MIME Validation + EXIF Stripping
        ↓
Tesseract OCR Engine (Alpine container /usr/share/tessdata)
        ↓
Keyword Matching & Triage AI-Flagging
        ↓
Admin Review Queue (Fast-Track / Detailed Review)
        ↓
Admin Decision (isTagVerified = true/false)
        ↓
Badge Awarded + Audit Log Recorded
```

---

## 5. Secret Management & Credential Policy

* **No Hardcoded Passwords**: Plaintext credentials are removed from migration scripts and source code.
* **Environment-Injected Configuration**: Secrets (`POSTGRES_PASSWORD`, `SPRING_DATASOURCE_PASSWORD`, `JWT_PRIVATE_KEY`) are passed via environment variables, container secrets, or secret managers.
* **Tessdata Location**: Standardized to `/usr/share/tessdata` in production container images.

---

## 6. Container Runtime & Verification

The production Docker container (`eclipse-temurin:21-jre-alpine`) packages:
* Native `tesseract-ocr` and `tesseract-ocr-data-eng` packages
* Unprivileged `appuser` runtime context
* Startup-time diagnostic sanity check (`initSanityCheck`) in `ProofOcrService`
* Real image OCR execution verification from outside the container
