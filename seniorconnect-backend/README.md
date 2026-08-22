# SeniorConnect Backend

SeniorConnect Backend is a production-grade Spring Boot 3 mentorship service providing zero-trust identity gating, asymmetric RS256 JWT security, real-time matchmaking, and row-level database security.

---

## 1. Security Architecture & Keys Setup (Gap 1)

### Generating RSA Key Pair
SeniorConnect uses asymmetric **RS256** (RSA 2048-bit) for JWT signing and verification. In production environments, persistent keys must be generated once and configured via environment variables.

#### Quick Generation:
```bash
# Linux / macOS:
./scripts/generate-rsa-keys.sh ./keys

# Windows PowerShell:
powershell -ExecutionPolicy Bypass -File .\scripts\generate-rsa-keys.ps1 -KeysDir ./keys
```

#### Manual OpenSSL:
```bash
openssl genpkey -algorithm RSA -out ./keys/private.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in ./keys/private.pem -out ./keys/public.pem
```

#### Environment Variables:
```env
JWT_PRIVATE_KEY_PATH=./keys/private.pem
JWT_PUBLIC_KEY_PATH=./keys/public.pem
```
> **Note**: In `test` and `dev` profiles, if keys are omitted, an ephemeral in-memory key pair is automatically generated for local development convenience. In `prod`, missing keys immediately halts startup with a security exception.

---

## 2. Row-Level Security (RLS) (Gap 2)

PostgreSQL Row-Level Security is strictly enforced on:
- `queries`: Protected so only the owning junior can mutate, while feed queries are viewable.
- `responses`: Protected so only the authoring senior can mutate.
- `reveal_requests`: IDOR-guarded so rows are strictly visible and editable only by the involved `junior_id`, `senior_id`, or `ADMIN` role.

The application automatically passes session variables per-request via `RlsSessionFilter`:
```sql
SET app.current_user_id = '<user-uuid>';
SET app.current_user_role = '<ROLE>';
```

---

## 3. Append-Only Audit Logging (Gap 3)

The `audit_logs` table provides a tamper-evident audit trail:
- Enforced at the database level via `trg_prevent_audit_logs_mutation` trigger.
- Any direct or indirect `UPDATE` or `DELETE` query on `audit_logs` is rejected with a database exception.
- `REVOKE UPDATE, DELETE ON audit_logs FROM PUBLIC;`

---

## 4. Continuous Integration (CI) (Gap 4)

GitHub Actions workflow at `.github/workflows/backend-ci.yml`:
- Runs on every push and PR touching `seniorconnect-backend/**`.
- Provisions real PostgreSQL 16 and Redis 7 service containers.
- Executes `mvn -B clean verify -Dspring.profiles.active=test`.
- Archives Surefire test execution reports.
