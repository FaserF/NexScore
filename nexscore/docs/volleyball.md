# Volleyball - Professional Score Tracker

A comprehensive tool for tracking volleyball matches, supporting both indoor and beach variants with advanced rule sets.

## 🌟 Features

- **Flexible Sets**: Play Best of 1, 3, or 5.
- **Indoor & Beach Rules**: Configurable points per set (25 or 21) and tie-break points (15).
- **Side Switching**: Automatic alerts for side switching (every 7 points for beach, every set for indoor).
- **Multiplayer Sync**: Real-time score updates across multiple devices.
- **SipDeck Integration**: Optional drinking game rules for casual sessions.
- **Undo Support**: Quick correction of scoring errors.

## 🎮 How to Play

1. **Configure Match**: Set the number of sets and points per set in the setup screen.
2. **Score Points**: Tap the score for Team A or Team B to increment.
3. **Track Sets**: The app automatically detects set wins and starts the next set until the match is decided.
4. **Switch Sides**: Follow the on-screen prompts when it's time to change sides.

## 🛠️ Technical Details

- **Models**:
    - `VolleyballRules`: Configuration for points and set counts.
    - `VolleyballSet`: Tracks individual set scores and winners.
    - `VolleyballGameState`: Overall match state (current set, sets won, etc.).
- **Logic**: Handled by `VolleyballStateNotifier` in `volleyball_provider.dart`.
- **Sync**: Implements `updateFromSync` for multiplayer alignment.
