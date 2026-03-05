# Developer Setup & CI/CD 🚀

This guide will help you set up NexScore for local development and explain our automated pipeline.

## Local Environment Setup

### Prerequisites
- **Flutter SDK**: Stable channel (latest version recommended).
- **Python**: Required for MkDocs (documentation).
- **Firebase CLI**: If you plan to modify authentication or cloud sync.

### Initializing the Project

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/FaserF/NexScore.git
   cd NexScore
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   # For Web
   flutter run -d chrome

   # For Desktop (e.g., Windows)
   flutter run -d windows
   ```

## CI/CD Pipeline ⚙️

We use GitHub Actions to ensure quality and automate deployments.

### Workflows

- **`ci.yml`**: Runs on every push and PR.
    - Lints the code (`flutter analyze`).
    - Runs all unit and widget tests (`flutter test`).
- **`deploy_pages.yml`**:
    - Builds the Flutter Web PWA.
    - Builds the MkDocs documentation site.
    - Deploys both to the `gh-pages` branch.
    - The marketing site is served at `/` and the app is served at `/app`.

### Environment Variables

We use `--dart-define` to inject configuration at build time:
- `APP_VERSION`: The semantic version string.
- `IS_BETA`: Boolean flag to enable/disable the Beta banner and features.

## Documentation Development

To preview the documentation locally:

1. **Install MkDocs**:
   ```bash
   pip install mkdocs-material
   ```

2. **Serve Locally**:
   ```bash
   mkdocs serve
   ```
   The docs will be available at `http://127.0.0.1:8000`.
 Riverside.
