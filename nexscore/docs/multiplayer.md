# Multiplayer System Documentation

## Overview

NexScore supports serverless multiplayer via **Firebase Firestore** using a Room Code system inspired by Jackbox Games. One device acts as the **Host** and generates a 5-character alphanumeric room code. Other devices enter this code to **Join** the session. This works identically across all platforms (PWA, iOS, Android) — no Bluetooth or WLAN permissions required.

## Architecture

```
┌─────────────┐          Firestore           ┌─────────────┐
│    Host      │ ───── /lobbies/{code} ─────▶ │   Client    │
│  (Controls)  │                              │ (Spectates) │
└─────────────┘          real-time            └─────────────┘
       │                  snapshots                  │
       ▼                                             ▼
  MultiplayerService                          lobbyUpdates stream
  syncGameState(state)                        gameStateStream
```

### Key Components

| Component | Path | Description |
|---|---|---|
| `MultiplayerService` | `lib/core/multiplayer/multiplayer_service.dart` | Abstract interface for lobby operations |
| `FirestoreMultiplayerImpl` | `lib/core/multiplayer/firestore_multiplayer_impl.dart` | Firestore-backed implementation |
| `SyncEngine` | `lib/core/multiplayer/sync_engine.dart` | Debounced host → client state broadcasting |
| `MultiplayerClientOverlay` | `lib/core/multiplayer/widgets/multiplayer_client_overlay.dart` | Read-only overlay for client screens |
| `Lobby` / `MultiplayerUser` | `lib/core/multiplayer/models/` | Data models for room state |

### Providers

| Provider | Type | Purpose |
|---|---|---|
| `multiplayerServiceProvider` | `Provider<MultiplayerService>` | Singleton service instance |
| `lobbyStreamProvider` | `StreamProvider<Lobby?>` | Real-time lobby updates |
| `currentLobbyProvider` | `Provider<Lobby?>` | Synchronous lobby state |
| `isHostProvider` | `Provider<bool>` | Whether current user is host |
| `syncEngineProvider` | `Provider<SyncEngine>` | State sync engine instance |
| `gameStateSyncProvider` | `StreamProvider<Map>` | Client game state stream |
| `lobbyPlayerSyncProvider` | `Provider<void>` | Auto-maps lobby users to active players |

## User Flow

1. **Host** taps the Multiplayer Hub button (🔗 icon in the games list)
2. Host selects "Host a Room" — a 5-character code is generated
3. **Clients** select "Join a Room", enter the code and their display name
4. Both Host and Clients see the Lobby Screen with connected players
5. Host selects a game — clients see a read-only spectating view
6. For digital games (Mystic Tricks), each player interacts on their own device

## Digital Card Game: Mystic Tricks

A Wizard-inspired trick-taking card game with copyright-safe assets.

### Card Types
- **4 Elemental Suits**: Flame 🔥, Frost ❄️, Earth 🌿, Wind 💨 (values 1-13 each)
- **Wizard** (4 cards): Always wins the trick
- **Jester** (4 cards): Never wins, can be played anytime

### Game Flow
1. **Setup**: 3-6 players required
2. **Dealing**: Round N deals N cards per player
3. **Trump**: One extra card is revealed as trump
4. **Bidding**: Each player bids how many tricks they'll win
5. **Playing**: Lead player plays first, others must follow suit if able
6. **Scoring**: Correct bid = 20 + 10×tricks. Wrong bid = -10×|difference|

### Engine Location
- `lib/features/games/wizard_digital/models/wizard_engine.dart`

## Live Broadcast Games

Games like SipDeck, BuzzTap, WayQuest, and Darts support a "Live Broadcast" mode where the Host controls the game and Clients see a synchronized read-only view with a "Spectating" banner.

The `MultiplayerClientOverlay` widget wraps each game's body and automatically:
- Detects if the user is a client via `isHostProvider`
- Disables all touch interactions with `IgnorePointer`
- Shows a yellow "Spectating — Host controls the game" banner
## Troubleshooting & Debugging

If users experience connectivity issues (404s, timeouts, or infinite loading), NexScore provides built-in diagnostic tools.

### 1. Diagnostic Dialog
When a multiplayer action fails or times out (15s default), a **Multiplayer Diagnostics** dialog appears automatically. This guides users through:
- Disabling AdBlockers or VPNs (which often block `firestore.googleapis.com`).
- Checking if the domain is authorized in Firebase.
- Verifying Anonymous Authentication is enabled.

### 2. Debug Mode & Log Export
For complex issues, users can enable **Debug Mode** in the settings:
1. Go to **Settings** → **Debug Mode**.
2. Toggle Debug Mode **ON**. This enables verbose system logging in the background.
3. Tap **Export Logs** to share a `.txt` file containing the last 5000 system events.

### 3. Developer Diagnostics
All logs are captured globally. Developers can access them in the browser console (if Debug Mode is ON) or via the exported file.
- **Log Source**: `lib/core/utils/app_logger.dart`
- **Global Interceptor**: `lib/main.dart` (intercepts `debugPrint`)
