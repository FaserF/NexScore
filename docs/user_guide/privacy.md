# Privacy and Permissions

NexScore is designed with privacy and data ownership in mind. We believe your data belongs to you, and our architecture reflects that.

## 1. Serverless Architecture
NexScore is a **serverless** application. This means:
- **No Central Server**: We do not maintain a central server that stores your personal information, game results, or player profiles.
- **Local-First**: All data is primarily stored and processed locally on your device using your browser's local storage (SQLite/IndexedDB).
- **Direct Cloud Integration**: When you sign in with Google or GitHub, the application communicates **directly** from your device to those services. NexScore as a developer never sees your data.

## 2. Requested Permissions

### Google Sign-In (Firestore)
When you connect your Google account, NexScore requests:
- **Basic Profile Information**: Email, display name, and profile picture URL.
- **Usage**: This is used to uniquely identify your "cloud profile" so that your data can be synced across multiple devices.
- **Storage**: Your players, game sessions, and leaderboards are synced to **Google Cloud Firestore**, a managed database service. Access is restricted to your authenticated user ID.

### GitHub Sign-In (Gists)
When you connect your GitHub account, NexScore requests:
- **Gist Scope**: Permission to create and update Gists.
- **Usage**: NexScore creates a **private Gist** on your GitHub account as a secondary backup mechanism.
- **Privacy**: We only ever read or write the Gist specifically created by NexScore. Your other GitHub data is completely untouched and inaccessible to the app.

## 3. Data Processing
- **Analytics**: NexScore does not use third-party analytics trackers.
- **Sharing**: We do not sell, rent, or share your data with third parties.
- **Deletion**: Since your data is either local or in your own cloud accounts (Firestore/Gist), you have full control over it. Deleting your local database via the NexScore settings will clear local data, and you can manage your cloud data via your Google/GitHub account settings.

## 4. Why Sync?
Synchronization is optional but recommended if you:
1. Play NexScore on multiple devices (e.g., Phone and Tablet).
2. Want to host multiplayer games with a permanent identity.
3. Want a safe backup of your long-term game statistics.

---
© 2026 Fabian Seitz (FaserF) · MIT License
