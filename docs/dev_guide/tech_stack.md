# Technology Stack 💻

NexScore is built using a modern, robust, and scalable technology stack.

## Frontend Framework: Flutter 💙

We use [Flutter](https://flutter.dev) for its ability to deliver a high-performance, consistent UI across Web, Android, iOS, Windows, macOS, and Linux from a single codebase.

- **State Management**: [Riverpod](https://riverpod.dev) is used for its compile-safety and flexibility.
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) handles complex routing, including nested shell routes for persistent navigation.
- **Internationalization**: A custom `AppLocalizations` implementation using JSON-like maps for EN and DE support.

## Backend & Storage ☁️

- **Local Storage**: [sqflite](https://pub.dev/packages/sqflite) (and `sqflite_common_ffi` for desktop/web) provides a robust SQLite database.
- **Authentication**: [Firebase Auth](https://firebase.google.com/docs/auth) manages Google and GitHub sign-ins.
- **Cloud Sync**:
    - **Google Users**: Firebase Cloud Firestore sync.
    - **GitHub Users**: Custom integration with the [GitHub Gist API](https://docs.github.com/en/rest/gists) for user-owned private backups.

## Styling & Theme 🎨

The "NexScore Aesthetic" is a key part of the project.

- **Glassmorphism**: Custom `GlassContainer` widgets using `BackdropFilter`.
- **Animations**: Driven by both standard Flutter animations and custom `AnimatedScaleButton` wrappers.
- **Typography**: Uses the sleek **Inter** font family (via Google Fonts).

## CI/CD ⚙️

Our automation pipeline is powered by **GitHub Actions**:

1. **Analysis & Testing**: Every PR/Push triggers `flutter analyze` and `flutter test`.
2. **Automated Web Deployment**: Built with Flutter Web and deployed to GitHub Pages.
3. **MkDocs Documentation**: Documentation is automatically built and deployed alongside the app.
4. **Renovate**: Keeps our dependencies up-to-date automatically.
