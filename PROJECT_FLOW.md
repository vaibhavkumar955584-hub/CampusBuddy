# SeniorConnect (CampusBuddy) — Complete Project Flow & Architecture Guide

SeniorConnect (CampusBuddy) ek peer-to-peer college mentorship platform hai jo **Juniors** (asking questions anonymously) aur **Seniors/Alumni** (verified mentors providing career/academic guidance) ko securely connect karta hai.

---

## 🏗️ 1. High-Level System Architecture

```mermaid
graph TD
    A[Flutter Mobile App<br/>Android / iOS] -->|HTTPS REST API| B[Spring Boot 3.4.3 Backend]
    B -->|RS256 JWT Auth / RBAC| C[Security & RLS Filter]
    B -->|Smart Tag Matching<br/>GIN Index & Arrays| D[(PostgreSQL 16 DB<br/>RLS Protected)]
    B -->|Rate Limiting & OTP Cache| E[(Redis 7 Cluster)]
    B -->|Push Notifications| F[Firebase Cloud Messaging FCM]
```

---

## 👥 2. User Roles & Personas

| Role | Access & Capabilities |
|---|---|
| **Junior (Student)** | - Domain-restricted college email OTP / Google login.<br/>- Anonymously queries post karna without revealing real name/branch.<br/>- Seniors ke responses dekhna aur optional **Identity Reveal** request accept/reject karna. |
| **Senior / Mentor** | - College verified domain account (Semester 5+ / Alumni).<br/>- Feed me open questions dekhna aur match feed me targeted questions receive karna.<br/>- Placement credentials verify karwa kar **Verified Mentor** & milestone badges earn karna.<br/>- Mutual reveal request initiate karna. |
| **Admin** | - Platform moderation, offensive query reports review karna, aur Senior placement verification approve/reject karna.<br/>- Append-only audit logs access karna. |

---

## 🔄 3. End-to-End Core Flows

### 📌 Flow 1: Domain-Gated Authentication & Token Rotation Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Junior / Senior
    participant App as Flutter Mobile App
    participant Backend as Spring Boot Auth Service
    participant Redis as Redis Cache
    participant DB as PostgreSQL DB

    User->>App: College Email Enter Karta Hai (@galgotiacollege.edu.in)
    App->>Backend: POST /api/v1/auth/otp/request
    Backend->>Backend: Domain Whitelist Check & Email Prefix Parse (Branch, Year)
    Backend->>Redis: 6-Digit Secure OTP Store (TTL: 5 mins)
    Backend-->>App: OTP Sent Successfully (Dev Log / Mail)
    User->>App: OTP Submit Karta Hai
    App->>Backend: POST /api/v1/auth/otp/verify
    Backend->>Redis: Verify OTP & Invalidate
    Backend->>DB: User Fetch or Auto-Register
    Backend->>Backend: RS256 Asymmetric JWT Access Token + Refresh Token Generate
    Backend-->>App: Return { accessToken, refreshToken, userDetails }
```

---

### 📌 Flow 2: Zero-Trust Anonymous Query Creation & Feed Flow

```mermaid
sequenceDiagram
    autonumber
    actor Junior as Junior Student
    participant App as Mobile App
    participant Filter as RlsSessionFilter
    participant QuerySvc as Query Service
    participant DB as PostgreSQL (RLS Enforced)

    Junior->>App: Query Create: Title, Description, Tags ["DSA", "Amazon", "Interview"]
    App->>QuerySvc: POST /api/v1/queries (Bearer JWT)
    QuerySvc->>QuerySvc: XSS Input Sanitization (Jsoup)
    QuerySvc->>Filter: Set app.current_user_id = Junior.UUID
    QuerySvc->>DB: INSERT INTO queries (is_anonymous=true, tags=TEXT[])
    DB-->>QuerySvc: Saved Query Row
    QuerySvc-->>App: Query Created (Author ID stripped)
```

---

### 📌 Flow 3: Smart Tag Matching & FCM Notification Flow

```mermaid
sequenceDiagram
    autonumber
    participant Backend as Matching Service
    participant DB as PostgreSQL (GIN Index)
    participant FCM as Notification Service (FCM)
    actor Senior as Senior Mentor (Device)

    Backend->>DB: Query: senior_profiles.tags && queries.tags (Array Overlap)
    Note over DB: Postgres executes Bitmap Index Scan on idx_senior_profiles_tags
    DB-->>Backend: Matching Verified Seniors List
    Backend->>FCM: Send Targeted Push Notification: "New DSA Query Matched!"
    FCM-->>Senior: Push Notification Arrives on Mobile
    Senior->>Backend: GET /api/v1/matching/feed (Targeted Queries List)
```

---

### 📌 Flow 4: Senior Response & Mutual Consent Reveal Flow

```mermaid
sequenceDiagram
    autonumber
    actor Senior as Senior Mentor
    actor Junior as Junior Student
    participant App as Mobile App
    participant Backend as Response & Reveal Service
    participant DB as PostgreSQL

    Senior->>App: Writes Answer to Junior's Question
    App->>Backend: POST /api/v1/queries/{id}/responses
    Backend->>DB: Save Response & Award +1 Mentor Point to Senior
    Junior->>App: Junior views Answer (Helpful!)
    Senior->>App: Requests Mutual Identity Reveal (1-on-1 Mentorship)
    App->>Backend: POST /api/v1/reveals/request
    Backend->>DB: INSERT reveal_requests (status='PENDING')
    Junior->>App: Receives Reveal Request Notification
    Junior->>App: Clicks "Accept Reveal"
    App->>Backend: POST /api/v1/reveals/{id}/accept
    Backend->>DB: UPDATE reveal_requests SET status='ACCEPTED'
    Backend-->>App: Junior & Senior Identity Details Revealed to Each Other
```

---

### 📌 Flow 5: Gamification Badges & Milestone Evaluation Flow

```mermaid
stateDiagram-v2
    [*] --> ZeroPoints: Profile Created (0 pts)
    ZeroPoints --> FirstResponse: 1st Response Given (+1 pt) -> Badge: 'First Response'
    FirstResponse --> Mentor10: 10 Queries Answered (+10 pts) -> Badge: '10 Helped'
    Mentor10 --> VerifiedMentor: Placement Credential Approved by Admin -> Badge: 'Verified Mentor'
    VerifiedMentor --> TopContributor: 50+ Points Accumulated -> Badge: 'Top Contributor'
```

---

## 🗄️ 4. Database Schema & Security Isolation

```mermaid
erDiagram
    USERS ||--o{ QUERIES : "creates (author)"
    USERS ||--o{ RESPONSES : "writes (mentor)"
    USERS ||--o| SENIOR_PROFILES : "has"
    QUERIES ||--o{ RESPONSES : "contains"
    QUERIES ||--o{ REVEAL_REQUESTS : "associated with"
    USERS ||--o{ REVEAL_REQUESTS : "participates in"
    AUDIT_LOGS }|--|| USERS : "tracks"
    REPORTS }|--|| USERS : "reported by"

    USERS {
        uuid id PK
        varchar email UK
        varchar full_name
        varchar role "JUNIOR | SENIOR | ADMIN"
        varchar branch
        int semester
        boolean is_suspended
    }

    QUERIES {
        uuid id PK
        uuid junior_id FK
        varchar title
        text content
        text_array tags "GIN Indexed"
        boolean is_anonymous
        varchar status "OPEN | RESOLVED | DELETED"
    }

    RESPONSES {
        uuid id PK
        uuid query_id FK
        uuid senior_id FK
        text content
        boolean is_solution
    }

    SENIOR_PROFILES {
        uuid id PK
        uuid user_id FK,UK
        text_array tags "GIN Indexed"
        varchar placement_tag
        boolean is_tag_verified
        int points
        text_array badges "First Response, 10 Helped, etc."
    }

    AUDIT_LOGS {
        uuid id PK
        varchar event_type
        uuid actor_id
        varchar ip_address
        text details
        timestamp created_at "Append-Only (No UPDATE/DELETE)"
    }
```

---

## 🚀 5. How to Run Locally

### 1. Backend (Spring Boot)
```powershell
# Navigate to backend directory
cd d:\projects\capmusbuddy\seniorconnect-backend

# Run with Maven
mvn spring-boot:run
```
*API runs at: `http://localhost:8080/api/v1`*

### 2. Full Stack with Docker
```powershell
cd d:\projects\capmusbuddy
docker-compose up -d
```

### 3. Mobile App (Flutter)
```powershell
cd d:\projects\capmusbuddy\seniorconnect-mobile
flutter pub get
flutter run
```

---

## 🧪 6. Test Suite & Verification

All 25 backend integration tests & mobile widget tests can be run via:

```powershell
# Backend (25/25 Integration & Unit Tests)
cd d:\projects\capmusbuddy\seniorconnect-backend
mvn -B clean test

# Mobile (Widget Tests & Analyzer)
cd d:\projects\capmusbuddy\seniorconnect-mobile
flutter test
flutter analyze
```
