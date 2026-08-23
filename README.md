# SeniorConnect (CampusBuddy)

> Production-Grade Peer-to-Peer College Mentorship & Anonymous Query Platform.

---

## 📖 Complete Documentation & Flow Guide

👉 **[Click here to view the Full Project Flow & Architecture Guide](file:///d:/projects/capmusbuddy/PROJECT_FLOW.md)**

---

## 🌟 Key Highlights

- **Domain-Gated Authentication**: Restricted to verified college domains with RS256 asymmetric JWT security.
- **Zero-Trust Anonymous Query Engine**: Juniors post queries with complete identity concealment until mutual consent.
- **High-Performance Smart Matching**: PostgreSQL native `TEXT[]` array overlap operator (`&&`) powered by **GIN Indexes** (`idx_senior_profiles_tags`).
- **Gamification & Badges**: Automatic milestone evaluation (`First Response`, `10 Helped`, `Verified Mentor`, `Top Contributor`).
- **Hardened Database Security**: Dedicated runtime least-privileged role `seniorconnect_app`, `FORCE ROW LEVEL SECURITY`, and append-only immutable audit logs.
- **OCR-Assisted Proof Verification**: Tesseract OCR pipeline extracting text from offer letters and certificates for AI-assisted triage ("likely valid" vs "needs closer look"), with strict human-in-the-loop admin verification.
- **Cross-Platform Mobile App**: Modern Flutter UI with dedicated feeds, response threads, moderation reports, and gamification dashboards.

---

## 🔍 Native Dependencies (Tesseract OCR)

The proof verification pipeline uses `Tess4J` (native Tesseract wrapper) for extracting keywords from student achievement proofs.

### Installation:
- **Ubuntu/Debian (CI/Production)**:
  ```bash
  sudo apt-get update && sudo apt-get install -y tesseract-ocr tesseract-ocr-eng libtesseract-dev
  ```
- **macOS**:
  ```bash
  brew install tesseract tesseract-lang
  ```
- **Windows (Development)**:
  Download and install [UB-Mannheim Tesseract](https://github.com/UB-Mannheim/tesseract/wiki) and set `TESSDATA_PREFIX` to `C:\Program Files\Tesseract-OCR\tessdata`.

*Note*: If native Tesseract is not installed in the local environment, the OCR service falls back gracefully without throwing exceptions, routing requests to the standard human admin review queue.

---

## 🚀 Quick Start

### Backend (Spring Boot 3.4.3 + Java 21)
```powershell
cd seniorconnect-backend
mvn spring-boot:run
```

### Full Infrastructure (Postgres 16 + Redis 7 + Backend)
```powershell
docker-compose up -d
```

### Mobile App (Flutter)
```powershell
cd seniorconnect-mobile
flutter pub get
flutter run
```

### Run Tests
```powershell
# Backend (32/32 Integration, Security & OCR Tests)
cd seniorconnect-backend
mvn -B clean test

# Mobile (Widget Tests & Analyzer)
cd seniorconnect-mobile
flutter test
```
