# CampusBuddy V2 — Complete Project Flow & Lifecycle Guide

CampusBuddy V2 ek intelligent, outcome-driven mentorship platform hai jo **Juniors** (asking questions & pursuing career goals) aur **Verified Mentors** (seniors & alumni) ko connect karke measurable career outcomes (Interviews, Internships, Job Offers) achieve karwata hai.

---

## 🏗️ 1. CampusBuddy V2 System Architecture

```mermaid
graph TD
    A[Flutter Mobile App<br/>Home / Ask / Mentorship] -->|HTTPS REST API| B[Spring Boot 3.4.3 Backend]
    B -->|RS256 JWT Auth / RBAC| C[Security & RLS Filter]
    B -->|AI Query Intelligence<br/>Intent & Skill Extraction| D[AI & Semantic Engine]
    B -->|2-Stage Matching<br/>GIN Filter + Weighted Ranking| E[(PostgreSQL 16 DB<br/>RLS Protected)]
    B -->|Rate Limiting & OTP Cache| F[(Redis 7 Cluster)]
    B -->|Context-Rich Notifications| G[Firebase Cloud Messaging FCM]
```

---

## 👥 2. User Roles & Personas

| Role | Access & Capabilities |
|---|---|
| **Junior (Student)** | - Domain-restricted college email / OAuth login.<br/>- Goal formulation with AI Query Analysis.<br/>- Anonymous & public questions post karna.<br/>- Mentorship roadmap subscribe karna & weekly tasks complete karna.<br/>- 4-Tier Privacy control (Level 0 Anonymous → Level 3 Direct Mentorship). |
| **Senior (Mentor)** | - Verified domain account with achievement credentials (Offer letters verified via multi-modal OCR).<br/>- 2-Stage targeted matching feed with match percentage.<br/>- Goal roadmap guidance, 1-on-1 sessions & feedback provide karna.<br/>- Outcome-driven reputation badges (Placements Enabled, Top Contributor). |
| **Admin** | - Platform moderation, verification triage, outcome validation, and append-only audit logs access. |

---

## 🔄 3. End-to-End V2 Core Flows

### 📌 Flow 1: AI Query Intelligence & Similar Questions Discovery Flow

```mermaid
sequenceDiagram
    autonumber
    actor Junior as Junior Student
    participant App as Mobile App
    participant AI as AI Query Engine
    participant DB as PostgreSQL + Vector DB
    participant QuerySvc as Query Service

    Junior->>App: Submits Goal: "3 months for Amazon SDE placement"
    App->>AI: POST /api/v1/queries/analyze
    AI->>AI: Extract: Intent=PLACEMENT_PREPARATION, Company=Amazon, Skills=[DSA, Problem Solving], Timeline=90d
    AI->>DB: Semantic Search for Similar Answered Roadmaps
    AI-->>App: Return { structuredAnalysis, similarRoadmaps, topMatchedMentors }
    alt Junior views instant answer
        Junior->>App: Views Existing Verified Roadmap (Instant Self-Serve)
    else Junior asks community
        Junior->>QuerySvc: POST /api/v1/queries (Publish with Structured Metadata)
    end
```

---

### 📌 Flow 2: 2-Stage Intelligent Mentor Matching Flow

```mermaid
sequenceDiagram
    autonumber
    participant MatchingSvc as 2-Stage Matching Service
    participant DB as PostgreSQL (GIN Index)
    participant FCM as Notification Service (FCM)
    actor Senior as Verified Senior Mentor

    MatchingSvc->>DB: Stage 1: Candidate Retrieval via GIN array overlap (sp.tags && query.skills)
    DB-->>MatchingSvc: 40 Candidate Mentors List
    MatchingSvc->>MatchingSvc: Stage 2: Weighted Ranking Score (Skills 30% + Company 20% + Exp 15% + Quality 10% + Helpful 10% + Rep 5% + Avail 5%)
    MatchingSvc->>FCM: Send High-Context Notification: "🎯 98% Match: Amazon SDE Query"
    FCM-->>Senior: Push Alert on Mobile
    Senior->>MatchingSvc: GET /api/v1/matching/feed (Targeted Queries Ranked by Match %)
```

---

### 📌 Flow 3: Mentorship Roadmap, Sessions & Outcome Verification Flow

```mermaid
stateDiagram-v2
    [*] --> GoalDefined: Junior Starts 90-Day Roadmap
    GoalDefined --> WeeklyMilestones: Weekly DSA & System Design Tasks
    WeeklyMilestones --> MockInterviewSession: 1-on-1 Senior Mentorship Session
    MockInterviewSession --> OutcomeSubmitted: Junior Clears Placement/Internship
    OutcomeSubmitted --> AdminVerification: Offer Letter Proof Uploaded
    AdminVerification --> ReputationUpdated: +50 Reputation & 'Placements Enabled' Badge to Mentor
    ReputationUpdated --> [*]
```
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
