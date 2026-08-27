# CampusBuddy V2 — Advanced Outcome-Driven Mentorship Architecture

## 1. Executive Summary & Vision

CampusBuddy V2 transforms the platform from a conventional **peer Q&A forum** into an **intelligent, outcome-driven mentorship system**. It combines zero-trust campus security with an AI Query Engine, 2-Stage Mentor Matching, Goal Roadmaps, and Verified Outcome Tracking.

```text
Junior submits Goal/Question
            ↓
  AI Query Intelligence (Intent, Skills, Company, Urgency, Timeline)
            ↓
  ┌─────────┼─────────────────────────┐
  ▼         ▼                         ▼
Similar   Knowledge Base         2-Stage Mentor
Questions (Instant Self-Serve)   Matching Engine
                                      ↓
                                 Personalized Guidance
                                      ↓
                                 Structured Mentorship Plan
                                 (90-Day Roadmap, Tasks, Sessions)
                                      ↓
                                 Verified Outcome
                                 (Offer / Internship / Skill)
                                      ↓
                                 Reputation Feedback Loop
```

---

## 2. High-Level System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                       │
│  Home │ Ask / AI Analyze │ Discover │ Mentorship │ Profile  │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS / JWT
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 SPRING BOOT 3.4.3 API GATEWAY               │
│  Authentication │ Authorization (RS256) │ RLS Session Filter│
└──────────────────────────────┬──────────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
      │ Query        │ │ 2-Stage      │ │ Mentorship   │
      │ Intelligence │ │ Matching     │ │ Service      │
      └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
             │                │                │
             ▼                ▼                ▼
      ┌────────────────────────────────────────────────┐
      │              APPLICATION SERVICES              │
      │ Knowledge │ Reputation │ Notification │ Admin │
      │ Analytics │ Moderation │ Verification  │ Audit │
      └───────────────────────┬────────────────────────┘
                              │
              ┌───────────────┼────────────────┐
              ▼               ▼                ▼
       PostgreSQL 16       Redis 7          AI Layer
       + RLS + GIN        Cache / Queue    Embeddings /
       + pgvector         Distributed Lock Classification
              │               │                │
              └───────────────┼────────────────┘
                              ▼
                     ┌─────────────────┐
                     │ Firebase FCM    │
                     │ Notifications   │
                     └─────────────────┘
```

---

## 3. Core Domain Modules

1. **`auth`**: Domain-restricted college email OTP & OAuth verification.
2. **`users`**: Academic user personas with semester, branch, and role segregation.
3. **`queries`**: Zero-trust anonymous and public queries.
4. **`query-intelligence`**: AI extraction of intent, skills, target companies, timelines, and urgency.
5. **`matching`**: 2-Stage hybrid matching (Stage 1 GIN Candidate Filter + Stage 2 Weighted Multi-Attribute Ranking).
6. **`mentorship`**: Structured goal plans (e.g. 90-Day SDE Prep), task tracking, and 1-on-1 sessions.
7. **`outcomes`**: Verified career outcomes (Internship, Placement, Skill Mastery) with administrative proof verification.
8. **`reputation`**: Outcome-weighted mentor trust scoring (Helpful rate + Sessions + Placements enabled).
9. **`privacy`**: 4-Tier granular privacy states (Level 0 Anonymous → Level 1 Limited → Level 2 Reveal → Level 3 Mentorship).
10. **`moderation`**: Abuse, harassment, and policy violation triage.
11. **`verification`**: Multi-modal OCR proof triage and admin credential approval.
12. **`audit`**: Immutable, append-only security logs.

---

## 4. 2-Stage Mentor Matching Algorithm

* **Stage 1 (Candidate Retrieval):** PostgreSQL GIN index array-overlap on tags/skills (`sp.tags && :queryTags`) narrows down candidates from thousands to manageable subset.
* **Stage 2 (Weighted Ranking):**
$$\text{Score} = 30\% \text{ Skill} + 20\% \text{ Company} + 15\% \text{ Experience} + 10\% \text{ Quality} + 10\% \text{ Helpful Rate} + 5\% \text{ Reputation} + 5\% \text{ Availability} + 5\% \text{ History}$$

---

## 5. Security & Isolation

* **PostgreSQL RLS**: Enforced on `queries`, `responses`, `reveal_requests`, and `mentorship_plans`.
* **RS256 Asymmetric JWT**: Token rotation with secure Redis invalidation.
* **Server-Side Authorization**: Complete zero-trust architecture where all client actions are validated against server-side user context.
