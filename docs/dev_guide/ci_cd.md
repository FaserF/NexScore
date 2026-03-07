# NexScore CI/CD Architecture Guide

This document explains the automated build, test, and deployment pipeline for NexScore.

## 🏗️ Pipeline Overview

NexScore uses a **Modular Orchestrator** pattern for GitHub Actions. This ensures that code changes, documentation updates, and official releases are handled efficiently with maximum resource reuse.

### 1. NEX CI Orchestrator (`ci_orchestrator.yml`)
The primary workflow triggered on every push to `main` and all Pull Requests.

- **Phase 1: Detect Changes**: Uses `paths-filter` to determine if code, docs, or workflows changed.
- **Phase 2: Validate & Build**:
    - Consolidates Analysis (`flutter analyze`), Testing (`flutter test`), and Build steps into a single runner.
    - **Caching**: Uses `actions/cache` for the `pub` cache to speed up dependency resolution.
    - **Web Artifact**: Builds the Web PWA once and uploads it as a secure GitHub artifact.
- **Phase 3: Deploy**: Triggers the Deployment workflow using the pre-built Web artifact.

### 2. Release Orchestrator (`release_orchestrator.yml`)
Triggered manually (`workflow_dispatch`) for official version bumps and app store releases.

- **Version Calculation**: Automatically determines the next version based on the release type (stable/beta/dev).
- **Parallel Builds**: Builds Android APK, iOS IPA, and the Web PWA in parallel.
- **Unified Web Build**: The Web target is built on the GitHub host and then shared with both the Docker image build and the GitHub Pages deployment to ensure identical assets.
- **Release Assets**: Automatically uploads binaries to the GitHub Release page with generated changelogs.

### 3. Deployment Engine (`deploy_pages.yml`)
A reusable component for publishing to GitHub Pages.

- **Smart Skip**: Detects if a `web_artifact_name` is provided. If so, it downloads the artifact and **skips** the entire Flutter setup and build process, reducing deployment time by over 10 minutes.
- **MkDocs Integration**: Simultaneously builds and deploys the developer documentation.

## ⚡ Performance Optimizations

To keep NexScore development fast, we implement several "Monolithic Efficiency" strategies:

1.  **Strict Caching**: Dependencies are installed once per job. All subsequent `flutter build` commands must use the `--no-pub` flag.
2.  **Shared Runners**: By combining Analysis and Builds, we share the same Docker containers and Flutter SDK setups, eliminating redundant overhead.
3.  **Artifact Handover**: Building a Flutter Web app is computationally expensive. We build it **exactly once** and pass it between jobs using GitHub Artifacts.

## 🛠️ Troubleshooting

### Common Warning: "5 packages have newer versions..."
This is usually caused by transitive dependency constraints in the Flutter ecosystem. If these warnings become loud or block builds:
1.  Run `flutter pub outdated`.
2.  Add `dependency_overrides` to `nexscore/pubspec.yaml` to force the latest stable versions of the analyzer-related packages.

### PWA Deployment Failures
If the Web app doesn't update on GitHub Pages:
1.  Check the `Deploy Docs & PWA` step in the CI Orchestrator logs.
2.  Ensure the `web_artifact_name` matches the name used in the `Upload Web Artifact` step.
3.  Verify that the `firebase_options_web.dart` contains valid credentials or that the appropriate GitHub Secrets are set.
### Android Build Stability (AGP 9+ Issues)
Flutter plugins often lag behind the "bleeding edge" versions of the Android Gradle Plugin (AGP). To ensure stable builds:
1.  **Gradle**: Standardized on version `8.10.2` in `gradle-wrapper.properties`. Avoid `9.x` until Flutter plugin compatibility is confirmed.
2.  **AGP**: Standardized on version `8.7.3` in `settings.gradle.kts`.
3.  **Kotlin**: Explicitly apply `org.jetbrains.kotlin.android` version `2.1.10` in both `settings.gradle.kts` and `app/build.gradle.kts` to satisfy newer AGP requirements while maintaining compatibility.
4.  **Java/JVM**: The pipeline is configured for **Java 17** (`jvmToolchain(17)`).

---
*Last updated: 2026-03-08*
