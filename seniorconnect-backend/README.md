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

## 4. Continuous Integration (CI)

GitHub Actions workflow at `.github/workflows/backend-ci.yml`:
- Runs on every push and PR touching `seniorconnect-backend/**`.
- Provisions real PostgreSQL 16 and Redis 7 service containers.
- Executes `mvn -B clean test`.
- Archives Surefire test execution reports.

---

## 5. Known Limitations & Operational Trade-offs

### Rate Limiting Fallback During Redis Outages
- **Global vs. Per-Instance Limits**: Under normal operations, rate limiting is coordinated centrally across all backend instances using Redis sliding windows (`ZSET`).
- **Degradation Trade-off**: If Redis becomes unavailable, `RateLimiterService` emits an `ERROR`-level alert and degrades gracefully to an in-memory sliding window on each JVM instance. In multi-instance deployments, the effective system-wide capacity during a Redis outage is `N * limit` across `N` instances. This trade-off ensures the application remains available rather than failing open or closed completely.
- **Memory Management**: In-memory sliding windows are periodically pruned (`@Scheduled cleanupExpiredWindows`) to purge inactive/empty keys and prevent memory growth under high user cardinality.

### Least-Privileged Database Role (`seniorconnect_app`)
- The running application connects using the dedicated `seniorconnect_app` role (`NOSUPERUSER NOBYPASSRLS`).
- Schema migrations run under `postgres` (or a dedicated migration runner role).
- `FORCE ROW LEVEL SECURITY` is enabled on core tables to prevent any privilege bypass.

