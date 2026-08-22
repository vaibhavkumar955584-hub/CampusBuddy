# SeniorConnect Mobile (Flutter)

Campus mentorship platform mobile application with role-based routing, JWT RS256 token lifecycle, Google Sign-In, query/response feed, reveals, and moderation.

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (>= 3.3.0)
- Java 21 JDK (for Android builds)
- Android Studio / Android SDK

### 2. Firebase & Google Sign-In Configuration
1. Copy `android/app/google-services.json.template` to `android/app/google-services.json`:
   ```bash
   cp android/app/google-services.json.template android/app/google-services.json
   ```
2. In your Firebase Console:
   - Create an Android App with package name `com.seniorconnect.seniorconnect_mobile`.
   - Add your debug SHA-1 signing certificate fingerprint.
   - Download the generated `google-services.json` and replace the placeholder fields in `android/app/google-services.json`.
3. Enable **Google Sign-In** and **Anonymous/Phone/Email** providers under Firebase Authentication.

### 3. Running the App
```bash
flutter pub get
flutter run
```
