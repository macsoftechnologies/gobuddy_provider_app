# GOBUDDY Provider App (`gobuddy`)

Service provider and technician mobile application for **GOBUDDY** — Onboarding, job requests, schedule management, earnings, job execution, and subscription plans.

---

## 📋 Technical Stack & Environment Versions

Ensure your development environment matches these versions to prevent build errors or dependency conflicts:

| Component | Required / Configured Version | Location / Source |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.35.4-stable` (or `^3.35.x`) | `android/local.properties` |
| **Dart SDK** | `^3.8.1` | `pubspec.yaml` |
| **Java / JDK** | **JDK 17** (`JavaVersion.VERSION_17`, `jvmTarget = 17`) | `android/app/build.gradle.kts` |
| **Android Gradle Plugin (AGP)** | `8.11.1` | `android/settings.gradle.kts` |
| **Gradle Wrapper** | `8.14` (`gradle-8.14-all.zip`) | `android/gradle/wrapper/gradle-wrapper.properties` |
| **Kotlin** | `2.2.20` | `android/settings.gradle.kts` |
| **Target SDK / Compile SDK** | `36` | `android/app/build.gradle.kts` |
| **Firebase BoM** | `34.6.0` | `android/app/build.gradle.kts` |
| **Application ID** | `com.gobuddy.provider` | `android/app/build.gradle.kts` |
| **App Name** | `GBProvider` | `android/app/src/main/AndroidManifest.xml` |
| **App Version** | `1.0.0+1` (Version: `1.0.0`, Build: `1`) | `pubspec.yaml` |

---

## 🔑 Integrated Services & Keys

1. **Firebase Cloud Messaging & Analytics**:
   - Configuration file: `android/app/google-services.json`
   - Uses Firebase BoM `34.6.0`, `firebase_core: ^4.3.0`, `firebase_messaging: ^16.1.0`.
2. **SMS OTP Auto-Retriever**:
   - `sms_autofill: ^2.3.0`
   - Android Manifest contains `com.google.android.gms.auth.api.phone.SMS_RETRIEVER`.
   - Requires Google App SMS Hash in DLT SMS templates for automated OTP retrieval without user tap.
3. **Razorpay & Payments**:
   - `razorpay_flutter: ^1.4.0`
4. **Media & Device Hardware**:
   - Camera (`camera: ^0.11.2`) & Image Picker (`image_picker: ^1.2.0`) for job verification photos.
   - Audio (`audioplayers: ^5.2.0`) for real-time incoming job ringers/alerts (`assets/sounds/ring.mp3`).
   - Location (`geolocator: ^14.0.2`, `geocoding: ^4.0.0`) for provider proximity tracking.

---

## 📂 Project Structure Overview

```
lib/
├── components/          # Reusable UI cards, buttons, custom app bars
├── data/                # Local data storage, SharedPreferences (Preferences class)
├── models/              # Provider models (orders, earnings, skills, profile, etc.)
├── pages/
│   ├── auth/            # Provider login, registration, OTP verification, skill selection
│   ├── dashboard/       # Main technician dashboard, active jobs, online/offline toggle
│   ├── bookings/        # Assigned jobs, job history, job progress, completion photos
│   ├── wallet/          # Earnings, withdrawal history, payment gateway
│   ├── profile/         # Provider profile, documents, services, KYC verification
│   └── ...
├── services/            # API endpoints & HTTP/Dio repository layers
└── utils/               # App theme colors, config constants, session manager
```

---

## 🚀 Setup & Local Running

1. **Clone the repository / open project directory**:
   ```bash
   cd GB-Provider-main
   ```

2. **Verify Flutter Environment**:
   ```bash
   flutter doctor
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run on Connected Device / Emulator**:
   ```bash
   flutter run
   ```

---

## 📦 Building for Release & Google Play Store

### 1. Release Keystore Setup
Ensure `android/key.properties` (or `android/app/key.properties`) exists with the signing details:
```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=<path-to-your-keystore-file>
```

### 2. Build Release App Bundle (.aab) - **For Google Play Store**
Google Play requires `.aab` format for all store uploads:
```bash
flutter build appbundle --release --android-skip-build-dependency-validation
```
The output file will be generated at:
```
build/app/outputs/bundle/release/app-release.aab
```

### 3. Build Release APK (.apk) - **For Direct Testing / Sideloading**
```bash
flutter build apk --release --android-skip-build-dependency-validation
```
The output file will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

> **Note on `--android-skip-build-dependency-validation`**:
> When using Gradle 8.14 with Flutter 3.35+, Flutter displays a deprecation validation warning. Passing the `--android-skip-build-dependency-validation` flag ensures smooth, uninterrupted builds without breaking Gradle dependencies.

---

## 🛠️ Version Bump Guide (Before Play Store Updates)

Before uploading a new release to Google Play Console:
1. Open `pubspec.yaml`
2. Update the `version:` field:
   ```yaml
   # version: <versionName>+<versionCode>
   version: 1.0.1+2
   ```
   - `1.0.1` is the user-facing version name (`versionName`).
   - `2` is the strictly incrementing integer build number (`versionCode`) required by Google Play Console.
3. Run `flutter pub get` and build a new bundle.
