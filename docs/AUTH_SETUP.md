# Authentication & Data Sync – Setup Guide

Complete developer guide for configuring **Google Sign-In** (Firestore) and **GitHub Sign-In** (Gist Backup) across all NexScore platforms.

---

## Table of Contents

1. [Overview & Architecture](#1-overview--architecture)
2. [Firebase Project Setup (Google Console)](#2-firebase-project-setup-google-console)
3. [GitHub OAuth App Setup](#3-github-oauth-app-setup)
4. [Platform Configuration](#4-platform-configuration)
   - [4a. Web / PWA (GitHub Pages)](#4a-web--pwa-github-pages)
   - [4b. Docker (Nginx)](#4b-docker-nginx)
   - [4c. Android](#4c-android)
   - [4d. iOS / macOS](#4d-ios--macos)
5. [CI / CD – Release Workflow](#5-ci--cd--release-workflow)
6. [Local Development Quickstart](#6-local-development-quickstart)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Overview & Architecture

```
┌───────────────────────────────────────────┐
│            NexScore Flutter App           │
│                                           │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Google Login  │  │ GitHub Login │       │
│  │ (Firebase     │  │ (Firebase    │       │
│  │  GoogleAuth)  │  │  GithubAuth) │       │
│  └──────┬───────┘  └──────┬───────┘       │
│         │                 │               │
│         ▼                 ▼               │
│  ┌──────────────────────────────────┐     │
│  │     Firebase Authentication      │     │
│  │  (handles OAuth for both)        │     │
│  └──────────────────────────────────┘     │
│         │                 │               │
│         ▼                 ▼               │
│  Firestore Sync    GistSyncService        │
│  (future)          (REST API with token)  │
└───────────────────────────────────────────┘
```

**Key point:** Firebase Authentication is used as the identity layer for **both** providers. GitHub's OAuth token (with `gist` scope) is then used to call the GitHub Gist REST API directly.

---

## 2. Firebase Project Setup (Google Console)

### 2.1 Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click **"Add project"** → name it `nexscore` (or reuse existing)
3. Disable Google Analytics (optional, not needed for auth)
4. Click **Create Project**

### 2.2 Enable Authentication Providers

1. In the Firebase Console → **Authentication** → **Sign-in method**
2. Enable **Google**:
   - Set a project support email (e.g. your email)
   - Click **Save**
3. Enable **GitHub**:
   - You will be shown a **callback URL** like:
     ```
     https://nexscore-XXXXX.firebaseapp.com/__/auth/handler
     ```
   - **Copy this URL** – you'll need it in [Step 3](#3-github-oauth-app-setup)
   - Leave the Client ID / Secret fields empty for now
   - Click **Save** (you'll come back to fill them in)

### 2.3 Register Platform Apps

#### Web App
1. Firebase Console → Project Settings → **General** → **"Add app"** → Web (`</>`)
2. Choose a nickname (e.g. `nexscore-web`)
3. **Enable Firebase Hosting** – optional (we use GitHub Pages / Docker)
4. Firebase gives you a config object. **Copy the entire `firebaseConfig` object**:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "nexscore-XXXXX.firebaseapp.com",
  projectId: "nexscore-XXXXX",
  storageBucket: "nexscore-XXXXX.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef"
};
```

> [!IMPORTANT]
> You need the **`apiKey`**, **`authDomain`**, **`projectId`**, **`storageBucket`**, **`messagingSenderId`**, and **`appId`** values.

#### Android App
1. Firebase Console → Project Settings → **General** → **"Add app"** → Android
2. Package name: `de.fabiseitz.nex_score` (matches `build.gradle.kts`)
3. Download `google-services.json`
4. Place it at: `nexscore/android/app/google-services.json`
5. Add the Google Services plugin to `nexscore/android/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

And in `nexscore/android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← ADD THIS
}
```

#### iOS App
1. Firebase Console → Project Settings → **General** → **"Add app"** → Apple
2. Bundle ID: `de.fabiseitz.nexScore` (check your `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Place it at: `nexscore/ios/Runner/GoogleService-Info.plist`

### 2.4 Add Authorized Domains

Firebase Console → **Authentication** → **Settings** → **Authorized domains**

Add ALL domains where the app will be served:

| Domain | Purpose |
|--------|---------|
| `localhost` | Local development |
| `faserf.github.io` | GitHub Pages PWA |
| `your-docker-domain.com` | Docker deployment |
| `nexscore-XXXXX.firebaseapp.com` | Firebase default (auto-added) |
| `nexscore-XXXXX.web.app` | Firebase Hosting (auto-added) |

---

## 3. GitHub OAuth App Setup

1. Go to https://github.com/settings/developers
2. Click **"New OAuth App"**
3. Fill in:

| Field | Value |
|-------|-------|
| Application name | `NexScore` |
| Homepage URL | `https://faserf.github.io/NexScore/` |
| Authorization callback URL | `https://nexscore-XXXXX.firebaseapp.com/__/auth/handler` |

> [!CAUTION]
> The **callback URL** must be the one Firebase showed you in [Step 2.2](#22-enable-authentication-providers). If it doesn't match exactly, GitHub login will fail with a redirect error.

4. Click **Register application**
5. Copy the **Client ID**
6. Click **"Generate a new client secret"** → copy the **Client Secret**

### 3.1 Enter Credentials in Firebase

1. Go back to Firebase Console → **Authentication** → **Sign-in method** → **GitHub**
2. Enter the **Client ID** and **Client Secret** from GitHub
3. Click **Save**

---

## 4. Platform Configuration

### 4a. Web / PWA (GitHub Pages)

#### Step 1: Add Firebase SDK to `web/index.html`

Add the following lines **before** the `<script src="flutter_bootstrap.js">` tag:

```html
<!-- Firebase SDKs (load from CDN) -->
<script src="https://www.gstatic.com/firebasejs/11.0.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/11.0.0/firebase-auth-compat.js"></script>

<script>
  firebase.initializeApp({
    apiKey: "AIza...",
    authDomain: "nexscore-XXXXX.firebaseapp.com",
    projectId: "nexscore-XXXXX",
    storageBucket: "nexscore-XXXXX.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef"
  });
</script>
```

> [!WARNING]
> The `apiKey` is **not a secret** – it's a public identifier. However, the project should have proper Firebase Security Rules to prevent unauthorized access to data.

> [!NOTE]
> **GitHub & Google Login via Firebase**
> Notice that you do not need a separate SDK or script tag for GitHub on the web. The single Firebase initialization block handles OAuth flows for both Google and GitHub out of the box.

#### Step 2: Authorized JavaScript Origins

Firebase Console → **Authentication** → **Settings** → **Authorized domains** must include your GitHub Pages domain:
```
faserf.github.io
```

#### Alternative: Use `firebase_options.dart` (FlutterFire CLI)

Instead of editing `index.html`, you can use the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=nexscore-XXXXX
```

This generates `lib/firebase_options.dart` with all platform configs auto-detected. Then update `main.dart`:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

### 4b. Docker (Nginx)

The Docker build is just a web build served by Nginx. The Firebase config is baked into the build at **build time** via `web/index.html`.

#### Option A: Hardcode in `web/index.html` (simplest)

Just commit the Firebase config in `web/index.html` as shown in [4a](#4a-web--pwa-github-pages). The Docker build will pick it up automatically.

#### Option B: Inject at build time via `--dart-define`

If you don't want to hardcode the config, you can pass environment variables at build time.

1. Update `Dockerfile` to accept build args:

```dockerfile
ARG FIREBASE_API_KEY
ARG FIREBASE_AUTH_DOMAIN
ARG FIREBASE_PROJECT_ID
ARG FIREBASE_APP_ID

RUN flutter build web --wasm --release --base-href="/" \
  --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
  --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN \
  --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
  --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID
```

2. Read them in Dart:

```dart
const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
```

3. Build the Docker image:

```bash
docker build \
  --build-arg FIREBASE_API_KEY=AIza... \
  --build-arg FIREBASE_AUTH_DOMAIN=nexscore-XXXXX.firebaseapp.com \
  --build-arg FIREBASE_PROJECT_ID=nexscore-XXXXX \
  --build-arg FIREBASE_APP_ID=1:123...:web:abc... \
  -t nexscore-web .
```

> [!IMPORTANT]
> Remember to add the Docker host's domain to Firebase **Authorized Domains** (see [2.4](#24-add-authorized-domains)).

---

### 4c. Android

1. Place `google-services.json` at `nexscore/android/app/google-services.json`
2. Add the Google Services Gradle plugin (see [2.3 Android](#android-app))
3. Get your SHA-1 fingerprint for Firebase:

```bash
# Debug key (local development)
cd nexscore/android
./gradlew signingReport
```

4. Add the SHA-1 fingerprint to Firebase Console:
   **Project Settings** → **Your apps** → Android app → **Add fingerprint**

5. For GitHub login, no extra Android config is needed – Firebase handles the OAuth redirect via a Chrome Custom Tab automatically.

> [!NOTE]
> The `google-services.json` file is **git-ignored** by default in many templates. If your CI needs it, either add it to the repo (it's not a secret) or inject it as a Base64-encoded GitHub Secret (see [Step 5](#5-ci--cd--release-workflow)).

---

### 4d. iOS / macOS

1. Place `GoogleService-Info.plist` at `nexscore/ios/Runner/GoogleService-Info.plist`
2. Open `ios/Runner/Info.plist` and add a URL scheme for Google Sign-In:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Reversed client ID from GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

3. For GitHub login on iOS, Firebase uses an `ASWebAuthenticationSession` redirect. No extra URL scheme is needed.

---

## 5. CI / CD – Release Workflow

### 5.1 GitHub Repository Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

| Secret Name | Value | Used By |
|---|---|---|
| `GOOGLE_SERVICES_JSON` | Base64-encoded `google-services.json` | Android build |
| `GOOGLE_SERVICE_INFO_PLIST` | Base64-encoded `GoogleService-Info.plist` | iOS build |
| `FIREBASE_API_KEY` | `AIza...` | Web / Docker build (if using `--dart-define`) |
| `FIREBASE_AUTH_DOMAIN` | `nexscore-XXXXX.firebaseapp.com` | Web / Docker build |
| `FIREBASE_PROJECT_ID` | `nexscore-XXXXX` | Web / Docker build |
| `FIREBASE_APP_ID` | `1:123...:web:abc...` | Web / Docker build |

#### Encoding the JSON/plist files:

```bash
# On macOS / Linux:
base64 -w 0 nexscore/android/app/google-services.json
base64 -w 0 nexscore/ios/Runner/GoogleService-Info.plist
```

### 5.2 Using Secrets in Workflows

#### `build.yml` / `release_orchestrator.yml` – Android job:

Add a step **before** `flutter build apk`:

```yaml
- name: Decode google-services.json
  run: echo "${{ secrets.GOOGLE_SERVICES_JSON }}" | base64 -d > nexscore/android/app/google-services.json
```

#### `release_orchestrator.yml` – iOS job:

Add a step **before** `flutter build ipa`:

```yaml
- name: Decode GoogleService-Info.plist
  run: echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 -d > nexscore/ios/Runner/GoogleService-Info.plist
```

#### `deploy_pages.yml` – Web PWA job:

If using `--dart-define` instead of hardcoding in `index.html`:

```yaml
- name: Build Web App (PWA)
  run: |
    flutter pub get
    flutter build web --release --base-href "/NexScore/" \
      --dart-define=FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }} \
      --dart-define=FIREBASE_AUTH_DOMAIN=${{ secrets.FIREBASE_AUTH_DOMAIN }} \
      --dart-define=FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }} \
      --dart-define=FIREBASE_APP_ID=${{ secrets.FIREBASE_APP_ID }}
  working-directory: nexscore
```

#### Docker image build:

```yaml
- name: Build and push
  uses: docker/build-push-action@v6
  with:
    context: ./nexscore
    push: true
    build-args: |
      FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }}
      FIREBASE_AUTH_DOMAIN=${{ secrets.FIREBASE_AUTH_DOMAIN }}
      FIREBASE_PROJECT_ID=${{ secrets.FIREBASE_PROJECT_ID }}
      FIREBASE_APP_ID=${{ secrets.FIREBASE_APP_ID }}
```

### 5.3 Summary: What Goes Where

| Config Item | Where It Lives | How It Gets There |
|---|---|---|
| Firebase Web config | `web/index.html` **or** `--dart-define` | Committed to repo **or** injected via secrets |
| `google-services.json` | `android/app/` | Committed to repo **or** injected via secret |
| `GoogleService-Info.plist` | `ios/Runner/` | Committed to repo **or** injected via secret |
| GitHub OAuth Client ID | Firebase Console only | Set manually in Firebase Console |
| GitHub OAuth Client Secret | Firebase Console only | Set manually in Firebase Console |
| Docker ENV vars | Not needed at runtime | Firebase config baked in at build time |

> [!TIP]
> Firebase web config values (apiKey, authDomain, etc.) are **public identifiers**, not secrets. They can safely be committed to the repo. Security is enforced by Firebase Security Rules, not by hiding these values.

---

## 6. Local Development Quickstart

### Prerequisites
- Flutter SDK installed (stable channel)
- Firebase project created (Steps 2 + 3 above)
- Node.js (for FlutterFire CLI, optional)

### Quickstart

```bash
# 1. Install FlutterFire CLI (optional but recommended)
dart pub global activate flutterfire_cli

# 2. Configure Firebase for all platforms at once
cd nexscore
flutterfire configure --project=nexscore-XXXXX

# 3. This generates lib/firebase_options.dart
#    Update main.dart to use it:
#    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

# 4. Run the app
flutter run -d chrome    # Web
flutter run -d emulator  # Android
flutter run -d iphone    # iOS
```

### Testing Sign-In Locally

- **Google Sign-In (Web):** Works via popup – make sure `localhost` is in Firebase **Authorized Domains**
- **GitHub Sign-In (Web):** Works via popup – the Firebase callback URL handles the redirect
- **Google Sign-In (Android/iOS):** Requires the platform config files (`google-services.json` / `GoogleService-Info.plist`)

---

## 7. Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `FirebaseException: core/no-app` | Firebase not initialized | Ensure `Firebase.initializeApp()` is called in `main.dart` and config is present |
| `PlatformException(sign_in_failed)` | Missing SHA-1 on Android | Add debug/release SHA-1 to Firebase Console |
| GitHub login redirects to 404 | Wrong callback URL in GitHub OAuth App | Must match Firebase's `__/auth/handler` URL exactly |
| `popup-blocked` error on web | Browser blocking Firebase popup | User must allow popups for the domain |
| `auth/unauthorized-domain` | Domain not in Firebase whitelist | Add your domain to **Authorized Domains** |
| Gist backup returns 401 | OAuth token expired or missing `gist` scope | Re-sign-in with GitHub; check scope in `GithubAuthProvider` |
| Docker build has no auth | Firebase config not baked in | Use `--dart-define` or put config in `web/index.html` before build |

---

## File Reference

| File | Purpose |
|---|---|
| [`lib/features/auth/presentation/profile_screen.dart`](../nexscore/lib/features/auth/presentation/profile_screen.dart) | Auth UI, login buttons, provider detection |
| [`lib/core/sync/gist_sync_service.dart`](../nexscore/lib/core/sync/gist_sync_service.dart) | GitHub Gist backup/restore API |
| [`web/index.html`](../nexscore/web/index.html) | Firebase SDK + config for web |
| [`android/app/google-services.json`](../nexscore/android/app/) | Firebase config for Android (you create this) |
| [`ios/Runner/GoogleService-Info.plist`](../nexscore/ios/Runner/) | Firebase config for iOS (you create this) |
| [`Dockerfile`](../nexscore/Dockerfile) | Web build + serve |
| [`.github/workflows/release_orchestrator.yml`](../.github/workflows/release_orchestrator.yml) | Release workflow |
