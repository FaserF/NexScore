<p align="center">
  <img src="../assets/logo.png" width="80" alt="NexScore Logo">
</p>

# NexScore Technical Documentation

Welcome to the official developer documentation for NexScore. This guide covers the system architecture, core backend patterns, game logic modules, and the automated CI/CD pipeline.

---

## 🏗️ Architecture Overview

NexScore follows a **Feature-First Architecture** combined with a **Decoupled Business Logic Layer**. We prioritize clear separation of concerns to ensure the app remains scalable, testable, and robust.

### Core Philosophy: "Backend Profi"
Our infrastructure is built on four pillars:
1. **Efficiency**: Use of asynchronous processing and optimized DB queries.
2. **Clarity**: Single-responsibility services and standardized response formats.
3. **Robustness**: Explicit error handling and structured logging.
4. **Standardization**: Unified patterns for state management and API interactions.

---

## 🛠️ Backend Infrastructure

### 1. Standardized Error Handling (`Result<T>`)
We avoid throwing exceptions for expected failures. Instead, we use a functional `Result` pattern located in `lib/core/error/result.dart`.
- **`Success<T>`**: Contains the successful data.
- **`Failure`**: Base class for structured errors:
    - `DatabaseFailure`: SQL or persistence errors.
    - `ValidationFailure`: User input or business rule violations.
    - `AuthFailure`: Authentication and permission issues.
    - `SyncFailure`: Cloud sync and backup errors (e.g. Gist API failures).
    - `UnexpectedFailure`: Catch-all for unknown errors.

### 2. Structured Logging (`AppLogger`)
Located in `lib/core/utils/logger.dart`, the `AppLogger` provides a unified interface for tracing:
- **Trace**: Fine-grained debugging.
- **Info**: General operation tracking.
- **Warning**: Potential issues that don't halt execution.
- **Error**: Critical failures (automatically includes stack traces).

### 3. High-Performance Persistence
The `DatabaseService` (`lib/core/storage/database_service.dart`) handles the local SQLite state.
- **Optimized Queries**: All heavy reads use database indexes for $O(1)$ or $O(\log n)$ performance.
- **Async Threading**: Database operations are strictly asynchronous to keep the UI at 60+ FPS.

### 4. Data Sync & Backup
NexScore supports two cloud backup methods via Firebase Authentication:
- **Google Sign-In** → Cloud Firestore sync (planned).
- **GitHub Sign-In** → Private **GitHub Gist** backup/restore via `GistSyncService` (`lib/core/sync/gist_sync_service.dart`).

> For detailed setup instructions, see [AUTH_SETUP.md](AUTH_SETUP.md).

---

## 🎮 Game Logic & State Management

Each game in NexScore is encapsulated within its own feature module using the **Notifier Pattern**.

### Pattern Structure
- **Screen**: Stateless or ConsumerWidget handling the UI.
- **Provider**: A `NotifierProvider` (from `riverpod_annotation`) that holds the game state.
- **Logic**: The Notifier contains the business rules (e.g., scoring, trick validation).

### Highlight: Wizard Scoring Engine
The Wizard module (`lib/features/games/wizard/`) supports three distinct scoring variants, managed through a strategy-based logic selection:
- **Standard**: +20 per correct bid, +10 per trick.
- **Lenient**: Fixed reward with offset-based deductions.
- **Extreme**: +30 per correct bid, high-stakes penalty multipliers.

---

## 🤖 CI/CD & Versioning

NexScore features one of the most advanced CI/CD pipelines for a Flutter project, orchestrating multi-platform releases with automated semver logic.

### 1. Version Management (`version_manager.py`)
Our custom Python script handles the complex transition between Stable, Beta, and Dev releases.
- **Stable**: Formatted as `X.Y.Z`.
- **Beta**: Formatted as `X.Y.ZbN` (e.g., `1.2.0b3`).
- **Dev**: Formatted as `X.Y.Z-devN-sha` (e.g., `1.2.1-dev4-a7b2c9d`).

### 2. Release Orchestrator
The workflow in `.github/workflows/release_orchestrator.yml` manages the entire deployment lifecycle:
1. **Calculate**: Determines the next version name and Docker-safe tags.
2. **Build**: Concurrent parallel builds for Android (APK), iOS (Unsigned IPA), and Docker.
3. **Deploy**: Triggers a PWA deployment to GitHub Pages.
4. **Release**: Creates a GitHub Release, attaches artifacts, and generates a **commit-based changelog**.

### 3. Docker Optimization
Docker images are automatically tagged with sanitized, lowercase tags and pushed to the GitHub Container Registry (GHCR).

---

## 🌐 Web & PWA Deployment

NexScore is served as a PWA on GitHub Pages.
- **SPA Support**: A custom `404.html` handles client-side routing redirects for GoRouter.
- **Performance**: Built with `--release` flags and WebGL/CanvasKit support for smooth animations.
- **Favicons**: Custom NexScore branding is integrated via the `web/index.html` and the deployment workflow.

---

## 📈 Development Standards

### Commit Messages
We follow a strict English-only commit policy with descriptive headers (e.g., `feat:`, `fix:`, `refactor:`, `docs:`).

### Linting & Testing
- **Analysis**: `flutter analyze` must pass with zero issues.
- **Tests**: `flutter test` covers core utility classes and i18n parity.
- **Parity Check**: The `i18n_parity_test.dart` ensures all strings are translated in both English and German.

---

## ⚖️ Legal & Licensing

Created by **Fabian Seitz**.
Distributed under the **MIT License**.

Referenced trademarks (Wizard, Qwixx, etc.) belong to their respective publishers. NexScore is a non-commercial utility project.
