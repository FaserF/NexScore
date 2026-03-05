# NexScore

<p align="center">
  <strong>A cross-platform score tracker for your favourite card and board games.</strong><br>
  Available on <strong>Android</strong> · <strong>iOS</strong> · <strong><a href="https://faserf.github.io/NexScore/">Web (PWA)</a></strong>
</p>

<p align="center">
  <a href="https://github.com/FaserF/NexScore/actions/workflows/test.yml"><img alt="Tests" src="https://github.com/FaserF/NexScore/actions/workflows/test.yml/badge.svg"></a>
  <a href="https://github.com/FaserF/NexScore/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/FaserF/NexScore"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-blue.svg"></a>
</p>

---

### 🚀 Version 0.1.0 (Beta)
NexScore is now in its official Beta phase.

## Features

- **9 Games Supported:** Wizard · Qwixx · Schafkopf · Kniffel · Phase 10 · Darts X01 · Rommé · **SipDeck** (18+) · **Arschloch**
- **Settings & Customization:** Dynamic Theme (Light/Dark/System), Language (DE/EN), and Database Management.
- **Environment Banners:** Automatic "DEV" and "BETA" indicators to clarify build state.
- **Universal Support:** Full compatibility with Web (WASM), Android (APK), and iOS (IPA).
- **Offline First:** Track scores fully offline without an account
- **Optional Sync:** Sign in with Google to backup and sync match history via Firestore
- **Leaderboards:** Automatically calculated global leaderboards by win rate
- **Match History:** Browse and share previous game sessions
- **Help Screen:** In-app links to documentation, bug reports and feature requests

## Supported Games

| Game | Players | Notable Features |
|------|---------|-----------------|
| Wizard® | 2–6 | Standard / Lenient / Extreme scoring, Amigo 2-player warning |
| Qwixx® | 2–5 | Coloured rows, lock logic, full scoresheet |
| Schafkopf | 4 | Sauspiel, Solo, Wenz, Laufende, Schneider, Schwarz payout |
| Kniffel® (Yahtzee) | 2–8 | Full scoresheet with upper-section bonus |
| Phase 10® | 2–6 | Original / Masters / Duel variants, phase legend |
| Darts X01 | 2–8 | 301/501/701/1001, bust detection, keypad input |
| Rommé | 2–6 | Multi-round penalty tracking, live totals |
| Arschloch / President | 3–8 | Rank tracking, card exchange instructions, point mode |
| SipDeck | 3+ | 50+ challenge cards, 5 categories, virus rules (18+) |

## Quick Start

```bash
git clone https://github.com/FaserF/NexScore.git
cd NexScore/nexscore
flutter pub get
flutter run
```

## Web (Docker)

```bash
# Build the Docker image
docker build -t nexscore-web:local .

# Run locally – open http://localhost:8080 in your browser
docker run -p 8080:80 nexscore-web:local
```

## Build APK (Android)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## CI/CD

| Workflow | Runner | Output |
|----------|--------|--------|
| `test.yml` | ubuntu-latest | `flutter test` (50+ tests) |
| `build_apk.yml` | ubuntu-latest | Release `.apk` → GitHub Release |
| `build_ipa.yml` | macos-latest | Unsigned `.ipa` → GitHub Release |
| `build_web.yml` | ubuntu-latest | Docker image pushed to `ghcr.io` |

**Renovate Bot** auto-merges minor/patch updates for Dart packages, GitHub Actions, and Docker weekly.

## Contributing

- 🐛 [Report a Bug](https://github.com/FaserF/NexScore/issues/new?template=bug_report.yml)
- 💡 [Request a Feature](https://github.com/FaserF/NexScore/issues/new?template=feature_request.yml)
- 📖 [Documentation](https://faserf.github.io/NexScore/docs/)
- 💬 [Discussions](https://github.com/FaserF/NexScore/discussions)

## Legal

**Attribution:** Created by [Fabian Seitz (FaserF)](https://fabiseitz.de) — [github.com/FaserF/NexScore](https://github.com/FaserF/NexScore)

**Trademark Notice:** NexScore holds no copyright or trademark over any referenced physical games. Wizard® (Amigo), Qwixx® (Nürnberger Spielkarten), Kniffel® (MB Spiele), Phase 10® (Mattel), and others are property of their respective owners. SipDeck is an original concept. Arschloch / President is a traditional public-domain folk card game.

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.
