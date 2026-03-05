# Technology Stack 💻

NexScore is built using a modern, robust, and scalable technology stack. This document outlines the core technologies, libraries, and tools used to build and maintain the application, along with the rationale behind these choices.

## Frontend Framework: Flutter 💙

[Flutter](https://flutter.dev) is the core framework used for NexScore. It was chosen for its unparalleled ability to deliver a high-performance, consistent UI across Web, Android, iOS, Windows, macOS, and Linux from a single codebase.

- **SDK Version**: `^3.11.0` (Stable Channel)
- **Dart Version**: `^3.6.0`

### Why Flutter?
- **Animations & Glassmorphism**: Flutter's rendering engine (Impeller/Skia) makes it trivial to create the complex blur effects and fluid animations required for NexScore's "premium" aesthetic.
- **True Cross-Platform**: A single codebase serves the PWA, Android APKs, and future iOS releases, ensuring feature parity across all devices.

## Core Libraries

### State Management & Dependency Injection
- **[flutter_riverpod](https://pub.dev/packages/flutter_riverpod) (^3.2.1)**: Riverpod is used exclusively for state management. It provides compile-time safety, prevents `ProviderNotFoundException` errors, and makes testing significantly easier by allowing providers to be mocked directly.
- **[riverpod_annotation](https://pub.dev/packages/riverpod_annotation) & [riverpod_generator](https://pub.dev/packages/riverpod_generator)**: Used for code generation to create robust providers with minimal boilerplate.

### Routing & Navigation
- **[go_router](https://pub.dev/packages/go_router) (^17.1.0)**: The official declarative routing package. It powers NexScore's nested `StatefulShellRoute`, which enables the persistent bottom navigation bar while maintaining independent navigation stacks for each tab (e.g., preserving scroll position on the Leaderboard while viewing a Game setup).

### Storage & Persistence
- **[sqflite](https://pub.dev/packages/sqflite) (^2.4.2)**: For robust, structured local relational data storage on mobile devices.
- **[sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) (^1.1.1)**: Crucial for the Progressive Web App (PWA). It provides a persistent SQLite database in the browser using IndexedDB, ensuring users don't lose data when refreshing the webpage.
- **[shared_preferences](https://pub.dev/packages/shared_preferences) (^2.5.4)**: Used sparingly for simple, non-relational user preferences (like theme overrides or last-used language).

### Backend & Cloud Sync
- **[firebase_core](https://pub.dev/packages/firebase_core) & [firebase_auth](https://pub.dev/packages/firebase_auth)**: Powers the Google Sign-In and GitHub Sign-In flows.
- **[cloud_firestore](https://pub.dev/packages/cloud_firestore)**: Provides real-time NoSQL cloud synchronization for users logged in via Google.
- **[http](https://pub.dev/packages/http)**: Used to interact directly with the GitHub REST API to manage private Gist backups for users logged in via GitHub.

### UI & Styling
- **[flex_color_scheme](https://pub.dev/packages/flex_color_scheme) (^8.4.0)**: Used to generate highly polished, accessible, and mathematically precise color palettes across both Light and Dark modes. It ensures the app maintains perfect contrast ratios regardless of the user's system preferences.
- **[cupertino_icons](https://pub.dev/packages/cupertino_icons)**: Supplementary icon pack alongside Material icons.

### Utilities
- **[uuid](https://pub.dev/packages/uuid) (^4.5.3)**: Generates universally unique identifiers for players and sessions, essential for ensuring data consistency during cloud synchronization.
- **[intl](https://pub.dev/packages/intl) (^0.20.2)**: Handles date formatting and number localization.
- **Custom `AppLocalizations`**: A lightweight, JSON-map based localization system that allows for rapid translation testing without relying on complex generation tools.

## CI/CD Pipeline ⚙️

Our automation pipeline is powered entirely by **GitHub Actions** to ensure code quality and automate deployments with zero manual intervention.

1. **Analysis & Testing (`ci.yml`)**: Every Pull Request and push to `main` triggers `flutter analyze` (to enforce strict linting rules) and `flutter test` (to verify all unit and widget tests pass).
2. **Automated Deployment (`deploy_pages.yml`)**:
   - Compiles the Flutter app as a highly optimized Web release (`flutter build web --release`).
   - Injects the `APP_VERSION` and `IS_BETA` flags via `--dart-define` at compile time.
   - Builds the MkDocs documentation site.
   - Merges both into a single cohesive artifact, deploying the documentation to the root URL and the PWA to `/app/`.
3. **Dependency Management**: [Renovate Bot](https://github.com/renovatebot/renovate) continuously monitors `pubspec.yaml` and automatically creates PRs for dependency updates, ensuring the app never falls behind on security patches or performance improvements.
