# Developer Setup & CI/CD 🚀

This guide provides comprehensive instructions for setting up the NexScore development environment, running the application locally, understanding the project structure, and interacting with the CI/CD pipeline.

## 1. Local Environment Setup

### Prerequisites

Before cloning the repository, ensure you have the following installed on your system:

- **[Flutter SDK](https://docs.flutter.dev/get-started/install)**: The latest stable version.
- **Git**: For version control.
- **[Python 3.x](https://www.python.org/downloads/)**: Required only if you intend to build or preview the MkDocs documentation.
- **IDE**: We recommend [Visual Studio Code](https://code.visualstudio.com/) with the Flutter and Dart extensions, or [Android Studio](https://developer.android.com/studio).

### Initializing the Project

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/FaserF/NexScore.git
   cd NexScore
   ```

2. **Install Flutter Dependencies**:
   Navigate into the Flutter project root and fetch packages:
   ```bash
   cd nexscore
   flutter pub get
   ```

3. **Code Generation (Crucial Step)**:
   NexScore relies heavily on `riverpod_generator`. Any time you modify a `@riverpod` annotated class, or when first cloning the repo, you *must* run the build runner.
   ```bash
   # Run once:
   dart run build_runner build -d

   # Or, let it watch for changes continually while you develop:
   dart run build_runner watch -d
   ```

### Running the App Locally

NexScore is designed to be fully functional even without a Firebase backend (it defaults to offline-first SQLite).

**Running the Web App (PWA Mode):**
```bash
flutter run -d chrome
```

**Running the Desktop App (e.g., Windows):**
```bash
flutter run -d windows
```

### Environment Variables

The app relies on two primary build-time variables injected via `--dart-define`.

- `APP_VERSION`: The semantic version displayed in the Settings and Help screens.
- `IS_BETA`: A boolean (`true`/`false`). If `true`, a warning banner is displayed across the app indicating pre-release software.

Example local execution with flags:
```bash
flutter run -d chrome --dart-define=APP_VERSION=1.0.0-dev --dart-define=IS_BETA=true
```

## 2. Documentation Development (MkDocs)

NexScore's documentation is hosted on GitHub Pages and generated using MkDocs with the Material theme.

1. **Install Python Dependencies**:
   From the repository root (not the `nexscore` folder):
   ```bash
   pip install mkdocs-material mkdocs-material-extensions pymdown-extensions
   ```

2. **Serve Documentation Locally**:
   ```bash
   mkdocs serve
   ```
   Open your browser to `http://127.0.0.1:8000`. Changes to `.md` files in the `docs/` folder will hot-reload automatically.

## 3. The CI/CD Pipeline ⚙️

We use GitHub Actions to automate testing and deployment. Merging code into `main` should be a completely hands-off process regarding deployment.

### `ci.yml` (Continuous Integration)
**Triggers:** Push to any branch, or creation of a Pull Request.
**Actions:**
1. Sets up the Flutter environment.
2. Runs `flutter analyze` to enforce code style. *The build will fail if there are any analyzer warnings.*
3. Runs `flutter test` to execute all widget and unit tests.

### `deploy_pages.yml` (Continuous Deployment)
**Triggers:** Push to `main` modifying `docs/**`, or manual `workflow_dispatch`.
**Actions:**
1. Compiles the Flutter Web app in `--release` mode, setting the basehref to `/NexScore/`.
2. Builds the MkDocs static HTML site.
3. Merges the two directories: The Flutter PWA lives at the root `/`, and the static MkDocs site is copied into a `/docs/` subfolder.
4. Uploads the combined artifact to GitHub Pages.

**Note on Manual Deployments**: You can manually trigger this workflow from the GitHub Actions tab. It accepts inputs for `deploy_pwa` (boolean, forces the Flutter app to rebuild), `version_name` (string), and `is_beta` (boolean).

## 4. Platform Configurations & Architecture

NexScore utilizes specialized abstractions to ensure compiling across both native applications and PWAs runs smoothly.

### Local JSON Backup & Restore
*   **Implementation**: `LocalBackupService` manages exporting and importing full database backups.
*   **Native vs. Web Storage Handlers**:
    *   **Native**: Uses `file_picker` to prompt the system file explorer to save and read the backup `.json` file.
    *   **Web (PWA)**: Uses conditional platform imports (`local_backup_stub.dart` if compile targets native, or `local_backup_web.dart` on the Web) to construct blob payloads and trigger direct browser downloads.

### PWA Engine & Update Prompts
*   **Platform Abstractions**: Files like `pwa_prompt_stub.dart` and `pwa_prompt_web.dart` separate native logic from web logic.
*   **Update Notification Service**: `pwa_update_service_web.dart` registers a callback to detect service worker updates. When a new version is detected, it triggers a custom visual banner asking the user to update and reloads the browser to apply changes.

### Notification System & Permissions
*   **Local Notifications**: `NotificationService` wraps `flutter_local_notifications` for cross-platform local alerts.
*   **Use Cases**: Alerts users for turn changes in multiplayer lobbies, server discovery events, and background match starters.
*   **Permission Screen**: A dedicated screen (`NotificationPermissionScreen`) guides users through requesting system permissions on startup.

---

## 5. Developer Tools & Scripts

The repository includes utility scripts located in `/scripts` to automate development tasks.

### Codebase Manifest Generator (`generate_manifest.py`)
This script scans the entire `/lib` codebase and updates `project_manifest.json`.
*   **Usage**:
    ```bash
    python scripts/generate_manifest.py
    ```
*   **Mechanics**:
    *   Maps the directory structure recursively.
    *   Identifies Riverpod providers, UI widgets, services, and models.
    *   Registers connections between modules for quick reference.

### Release & Version Manager (`version_manager.py`)
A python script designed to automate release management and deployment pipelines.
*   **Usage**:
    ```bash
    python scripts/version_manager.py --release-type [stable|beta|dev] --bump-type [major|minor|patch|none]
    ```
*   **Key Functions**:
    *   **Tag Parsing**: Resolves version formats (e.g. `v1.2.3b1` or `v1.2.3-dev4`).
    *   **Automated Bumps**: Increments semver properties based on project tags.
    *   **Pipeline Synchronization**: Feeds updated tags into GitHub actions for compilation and Docker tag deployments.
