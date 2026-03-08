# NexScore Documentation Hub 📚

Welcome to the technical and functional documentation for NexScore.

## 🗂 Project Structure

```text
lib/
├── core/               # Routing, i18n, common UI, storage
├── features/
│   ├── auth/           # Google Sign-In & Profile
│   ├── games/          # Individual game modules & setup
│   ├── history/        # Match logs & session management
│   ├── leaderboards/   # Player statistics
│   ├── players/        # Local & synced player management
│   └── settings/       # Theme, Language, Data management
└── main.dart           # App entry point & initialization
```

## 🎮 Game Rules & Modules

### 1. Wizard
Tracks bids and actual tricks. Supports Standard (+20/-10), Lenient (+10/-10), and Extreme (+10/-10 with bid-based multipliers).

### 2. Schafkopf
Enforces Bavarian scoring rules. Supports Sauspiel, Solo, and Wenz. Tracks "Laufende" (enforced if ≥3), Schneider/Schwarz bonuses, and doubling.

### 3. Phase 10
Variants: Original, Masters (pick play), and Duel. Includes a phase legend and automated penalty point calculation.

### 4. Darts X01
Supports starting scores from 301 to 1001. Features bust detection and a specialized keyboard-driven scoring interface for web usability.

### 5. Arschloch / President
Tracks ranks (President, Arschloch, etc.) across rounds. Automated card exchange logic based on player count (President gives Arschloch, etc.).

## 🚢 Deployment & CI/CD

### 📘 User Guide
- [General Game Setup & Rules](./README.md)
- [Multiplayer & Cloud Sync](./multiplayer.md)
- [📸 Sharing & Social-To-Story](./sharing.md)
- [🔊 Audio, SFX & Text-To-Speech](./sfx_tts.md)

### Docker Usage
The project includes a production-ready `Dockerfile` serving the app via Nginx:
```bash
docker build -t nexscore .
docker run -p 8080:80 nexscore
```

### GitHub Actions
- `release_orchestrator.yml`: Consolidates multi-platform builds (APK, IPA, Web) and publishes to GitHub Releases with SHA256 checksums.
- `renovate.json`: Automated dependency updates for Dart, Docker, and GitHub Actions.

## ⚖️ Legal & Privacy
NexScore tracks game data locally. Optional Firebase sync transmits encrypted data to Firestore only if signed in. No third-party tracking or AI disclosure requirements are applicable to the final binary.

---
*Document Version: 0.1.0*
