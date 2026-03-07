# Application Features 🌟

NexScore is designed to be a complete companion for your game nights. This guide overviews the core sections of the application beyond just the individual game scoreboards.

## ⭐ Game Favorites

With an ever-growing list of games, you can keep your most-played ones at the top.

- **One-Tap Favorites**: Use the star icon on any game card in the library to mark it as a favorite.
- **Top of List**: Favorite games are automatically moved to the top of the Home screen for quick access.

## 👥 Players Management

The foundation of tracking scores is managing your crew. The **Players** tab allows you to:

- **Create Profiles**: Add new players by providing a name and selecting a distinct avatar color.
- **Visual Identity**: The chosen color helps instantly identify that player across all scoreboards, leaderboards, and history logs.
- **Edit & Delete**: Players can be renamed or softly deleted if they are no longer participating in game nights.

## 🏆 Global Leaderboards

The **Leaderboard** tab is where rivalries are settled. NexScore automatically aggregates data from all completed sessions.

- **Overall Stats**: View the total number of games played, total wins, and an absolute point sum across all game types.
- **Win Percentages**: See at a glance who is statistically the strongest player in your group.
- **Game-Specific Filtering**: *(Coming Soon)* Drill down to see who is specifically the grandmaster of Wizard or the luckiest at Kniffel.

## 📜 Session History

Every game you finish is archived forever. The **History** tab acts as your digital gaming diary.

- **Chronological Log**: View a reverse-chronological list of every game played, including the date, game type, duration, and the winner.
- **Detailed Match Results**: Tap any session to view the exact final scores for all participants.
- **Proof of Victory**: Settle disputes about "who won that game last month" instantly.

## ⚙️ Settings & Customization

The Settings profile (accessible from the top right of the Home screen or within the Help screen) lets you tailor the app.

- **Theme Control**: Override system settings to force Light Mode, Dark Mode, or stick to System Default.
- **Language**: Switch between supported languages (currently English and German).
- **Beta Features**: Manage experimental features if you are on a pre-release build.

## 🍺 Automated Sip Tracking (18+)

For our party games (SipDeck & BuzzTap), we've integrated a smart sip counting system.

- **No Manual Counting**: The app calculates who needs to drink based on the card or prompt.
- **Drink Button**: Confirm you've taken your sips to automatically increment your total in the session.
- **Skip Button**: Allows players to opt-out of a challenge without affecting their score.
- **Real-time Counter**: Current sip tallies for all players are shown directly at the bottom of the game screen.
- **Granular Task Filters (SipDeck)**:
    - You can disable specific "flavors" of tasks before you start. Use the **Help** button next to the filter title for detailed explanations.
    - Hate being the center of attention? Disable **Social Interaction**.
    - Don't want to text your ex? Disable **Messaging**.
    - Feeling lazy? Disable **Physical**.
- **Hydration Cards (SipDeck)**:
    - To ensure safety and fun, SipDeck includes optional **Hydration Cards**.
    - These cards occasionally interrupt the game to remind everyone to drink water.
    - Frequency adjusts automatically based on your chosen **Drink Intensity**.
- **Smart 2-Player Optimization**:
    - Many drinking games are built for groups. NexScore includes a toggle to hide "Group-only" cards when only 2 players are active.

## 🌐 Multiplayer & Remote Play

NexScore isn't just for local games. You can play with friends across the room or across the globe.

- **Host & Join**: One player hosts a session, and others join using a unique 6-digit game code.
- **Real-time Sync**: Scores and game states are synced instantly across all connected devices.
- **Remote Play**: Perfect for playing over Discord, Zoom, or just when sitting far apart.
- **Cross-Platform**: Join from Android, iOS, or Web seamlessly.

*(For detailed setup, see the [Multiplayer Guide](multiplayer.md))*

## ☁️ Account & Backup

*(For detailed info, see the [Account & Sync Guide](account.md))*

- **Google Sign-In**: Enables automatic, invisible syncing to Firebase Cloud Firestore.
- **GitHub Sign-In**: Enables manual, user-controlled JSON backups to private GitHub Gists.
- **Local SQLite**: If you never sign in, your data remains 100% local, safe, and offline-first.
