# FactQuest - Trivia & Road Trip Game

FactQuest is a premium trivia game designed for long car rides, featuring a curated database of fascinating real-world facts and "Dumb Ways to Die" stories.

## 🌟 Features

- **250+ Hand-Curated Cards**: No AI hallucinations. Every fact is verified and includes a source link.
- **Two Unique Categories**:
    - **Random Facts**: Mind-blowing information from science, history, and nature.
    - **Dumb Ways to Die**: Bizarre but true stories of unusual deaths throughout history.
- **Multiplayer Support**: Real-time synchronization allows everyone in the car to follow along on their own devices.
- **Undo Support**: Accidentally tapped? Use the undo button to go back to the previous card.
- **Safe & Educational**: Includes clickable URLs for further reading on reputable sites like NASA, National Geographic, and Britannica.

## 🎮 How to Play

1. **Select Categories**: Choose which types of facts you want to see.
2. **Start Game**: Tap the "Start" button to draw the first card.
3. **Explore & Verify**: Read the headline and the detailed explanation. Tap the "Source" button to verify the fact online.
4. **Continue**: Tap anywhere on the screen to draw the next random card.

## 🛠️ Technical Details

- **State Management**: Uses `FactQuestStateNotifier` (Riverpod) for reactive UI.
- **Sync Architecture**: Integrated with `SyncEngine` for seamless host-client multiplayer.
- **Persistence**: Game state is automatically saved via `GameSaveManager`.
- **Database**: Cards are structured in `factquest_database.dart` with unique IDs for localization compatibility.
