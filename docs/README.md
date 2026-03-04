# NexScore Documentation

> Full docs for the NexScore app — game rules, architecture, deployment, and contribution guide.
> 🌐 **Live app:** [nexscore.fabiseitz.de](https://nexscore.fabiseitz.de) · 💻 **Source:** [github.com/FaserF/NexScore](https://github.com/FaserF/NexScore)

---

## Contents

1. [Getting Started](#getting-started)
2. [Game Rules & Module Guide](#game-rules--module-guide)
3. [Architecture](#architecture)
4. [Internationalization](#internationalization)
5. [CI/CD](#cicd)
6. [Deployment (Docker)](#deployment-docker)
7. [Contributing](#contributing)
8. [Legal](#legal)

---

## Getting Started

### Prerequisites

| Tool | Required version |
|------|-----------------|
| Flutter | stable channel, ≥ 3.29 |
| Dart | ^3.11.1 |
| Firebase CLI | optional (for Firestore / Auth) |

### Local Setup

```bash
git clone https://github.com/FaserF/NexScore.git
cd NexScore/nexscore
flutter pub get
flutter run              # runs on connected device or emulator
```

### Running Tests

```bash
flutter test             # 50+ unit tests
flutter analyze          # static analysis (zero issues enforced)
```

---

## Game Rules & Module Guide

### Wizard

**Players:** 2–6 (note: Amigo official minimum is 3)
**Path:** `/games/wizard`

Each round, players bid the number of tricks they will win. The round count equals the number of cards dealt (round 1 = 1 card, round 2 = 2 cards, ...).

| Scoring Variant | Correct Bid | Wrong Bid |
|----------------|-------------|-----------|
| Standard | +20 + tricks × 10 | −10 × |bid−tricks| |
| Lenient | +10 + tricks offset | proportional deduction |
| Extreme | +30 + tricks × 10 | −2 × |bid−tricks| × 10 |

Special cards: **Wizard** (always wins), **Jester** (always loses). Trump suit rotates each round.

---

### Qwixx

**Players:** 2–5 | **Path:** `/games/qwixx`

Players cross out numbers left-to-right in four coloured rows (red/yellow ascending, blue/green descending). A row locks when 5+ crosses are made and the row's rightmost number is crossed. Locked rows are removed from play for all players. Fewest penalty points (−5 each for unused columns) + most crossed numbers wins.

---

### Schafkopf

**Players:** 4 (fixed) | **Path:** `/games/schafkopf`

Bavarian trick-taking game with bidding. Supported game types and payout multipliers:

| Type | Base | Schneider | Schwarz |
|------|------|----------|---------|
| Sauspiel | 1× | +1× | +1× |
| Solo | 3× | +1× | +1× |
| Wenz | 3× | +1× | +1× |
| Tout | 4× | — | — |

**Laufende** (running trumps) add +1× each. Base value configurable in session setup.

---

### Kniffel (Yahtzee)

**Players:** 2–8 | **Path:** `/games/kniffel`

Roll 5 dice up to 3 times. Fill each scoresheet category once. Upper section: sum of matching numbers (bonus of +35 if upper total ≥ 63). Lower section includes 3-of-a-kind, 4-of-a-kind, Full House (25), Small Straight (30), Large Straight (40), Yahtzee/Kniffel (50), and Chance.

---

### Phase 10

**Players:** 2–6 | **Path:** `/games/phase10`

Complete all 10 phases in order (Original) or in any order (Masters). First player to complete all phases wins; ties broken by lowest penalty score.

**Phase descriptions:**
1. 2 sets of 3 · 2. Set of 3 + run of 4 · 3. Set of 4 + run of 4 · 4. Run of 7
5. Run of 8 · 6. Run of 9 · 7. 2 sets of 4 · 8. 7 cards of one colour
9. Set of 5 + set of 2 · 10. Set of 5 + set of 3

**Penalty cards:** Number cards = face value; Skip = 15; Wild = 25.

**Variants:**
- **Original** – Complete phases 1–10 in fixed order
- **Masters** – Choose any phase each round (free choice, can't repeat completed phases)
- **Duel** – 2-player head-to-head with tactical phase selection

---

### Darts X01

**Players:** 2–8 | **Path:** `/games/darts`

Supported starting scores: 301, 501, 701, 1001. Players subtract their dart score each turn. Must finish on a **double** (double-out). A turn that would reduce the score below 0 or exactly to 1 is a **bust** (score reverts). Checkout table is built into the screen.

---

### Rommé

**Players:** 2–6 | **Path:** `/games/romme`

Multi-round points tracker. Each round, the player who goes out first scores 0; others score the sum of their remaining hand cards. Player with the fewest total penalty points after the agreed number of rounds wins.

---

### Arschloch / President

**Players:** 3–8 | **Path:** `/games/arschloch`

Traditional folk card game (also known as *President* or *Asshole*). Players try to shed all cards. Card values ascending: 3 < 4 < … < K < A < **2** (highest). Special rules:

- **2** beats any single card or combination
- **Bomb** (4 of a kind) can be played out of turn and beats everything except another Bomb
- Players may **pass** if they cannot beat the current play
- Trick winner leads next

**Ranks** (determined by finish order):

| Position | German | English | Points |
|----------|--------|---------|--------|
| 1st | Präsident | President | +2 |
| 2nd | Vizepräsident | Vice President | +1 |
| Middle | Bürger | Citizen | 0 |
| 2nd-last | Vize-Arschloch | Vice Asshole | −1 |
| Last | Arschloch | Asshole | −2 |

**Card exchange (next round):** Arschloch gives 2 best cards to President. President gives 2 arbitrary cards back. (With 5+ players: Vize-Arschloch gives 1 best card to Vizepräsident.)

---

### SipDeck

**Players:** 3+ | **Path:** `/games/sipdeck` | 🔞 18+ only

Party drinking card game with 50+ challenge cards across 5 categories:

| Category | Description |
|----------|-------------|
| Warm Up | Easy icebreaker challenges |
| Wild Cards | Dares and rule-setting challenges |
| Flirty* | Playful, flirty challenges (18+) |
| Bar Night | Bar-appropriate public challenges |
| Laughs | Silly, absurd things to do or say |

**Virus rules** are ongoing challenges that persist until a cure card is drawn. Card text uses `{0}` and `{1}` for dynamic player name injection.

*All players must be 18+ for Flirty category.*

---

## Architecture

### Tech Stack

| Layer | Technology |
|-------|-----------|
| UI / Mobile | Flutter 3.x (Dart) |
| State | Riverpod 3.x (Notifier / AsyncNotifier) |
| Navigation | GoRouter 17.x (StatefulShellRoute) |
| Local storage | sqflite (offline-first) |
| Cloud sync | Firebase Firestore (optional, behind Google Sign-In) |
| Auth | Firebase Auth (Google Sign-In) |
| Theming | FlexColorScheme 8.x (Material 3, Light/Dark) |
| URL handling | url_launcher 6.x |

### Folder Structure

```
nexscore/lib/
├── core/
│   ├── i18n/          # AppLocalizations (75+ keys, EN + DE)
│   ├── models/        # Session, Player models
│   ├── presentation/  # ScaffoldWithNavBar
│   └── router/        # GoRouter config
└── features/
    ├── auth/          # Google Sign-In, ProfileScreen
    ├── games/
    │   ├── arschloch/ # Arschloch / President
    │   ├── extras/    # Phase 10, Darts, Rommé
    │   ├── kniffel/   # Kniffel / Yahtzee
    │   ├── qwixx/     # Qwixx
    │   ├── schafkopf/ # Schafkopf
    │   ├── sipdeck/   # SipDeck (drinking game)
    │   └── wizard/    # Wizard
    ├── help/          # HelpScreen (links to docs + GitHub)
    ├── history/       # Session history
    ├── leaderboards/  # Rankings
    └── players/       # Player management
```

---

## Internationalization

NexScore ships with full **English** and **German** translations (75+ keys). The app auto-detects the system locale. Fallback is always English.

The CI suite includes an **i18n parity test** (`test/core/i18n/i18n_parity_test.dart`) that:
- Verifies both `en` and `de` locale maps have identical key sets
- Fails the build if any translation is empty or missing
- Verifies all 9 game name and description keys

---

### CI/CD

Four GitHub Actions workflows run automatically on every push to `main`:

```
.github/workflows/
├── test.yml       → flutter test + flutter analyze
├── build_apk.yml  → flutter build apk --release → GitHub Release
├── build_ipa.yml  → flutter build ipa (unsigned) → GitHub Release
└── build_web.yml  → docker build + push to ghcr.io
```

**Renovate Bot** is configured in `/renovate.json` to auto-merge minor/patch updates.

### Manual Releases & Pre-releases
The workflows support `workflow_dispatch` (manual trigger).
- **Is Pre-release?**: Trigger a "Beta" release.
- **IS_BETA Flag**: Passes `--dart-define=IS_BETA=true`, activating the **BETA banner** in-app.

---

## Settings & Customization

NexScore features a dedicated Settings view.

| Feature | implementation | Persistence |
|---------|----------------|-------------|
| **Theme** | Light/Dark/System | `shared_preferences` |
| **Language** | Manual EN/DE or System | `shared_preferences` |
| **Data Reset** | Full wipe of storage | `DatabaseService` |

---

## Deployment (Docker)

The web app is built into a Docker image using a multi-stage Flutter web build:

```bash
# Build
docker build -t nexscore-web:local .

# Run – open http://localhost:8080
docker run -p 8080:80 nexscore-web:local

# Production (via GitHub Actions)
# Image is pushed to: ghcr.io/faserf/nexscore:latest
# Served at: https://nexscore.fabiseitz.de
```

---

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (all commit messages in **English**)
4. Run `flutter test` and `flutter analyze` (must pass with 0 issues)
5. Open a Pull Request

**Issue templates** (GitHub UI variant):
- 🐛 [Bug Report](.github/ISSUE_TEMPLATE/bug_report.yml)
- 💡 [Feature Request](.github/ISSUE_TEMPLATE/feature_request.yml)

---

## Legal

**Attribution:** Created by [Fabian Seitz (FaserF)](https://fabiseitz.de)

**Trademark Notice:** Wizard® is a trademark of Amigo. Qwixx® is a trademark of Nürnberger Spielkarten. Kniffel® is a trademark of MB Spiele (Hasbro). Phase 10® is a trademark of Mattel. NexScore is not affiliated with any of these companies. SipDeck is an original game concept by the author. Arschloch / President is a traditional public-domain folk card game.

MIT License — see [LICENSE](../LICENSE).
