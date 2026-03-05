# Account & Cloud Sync ☁️

NexScore is designed as an **offline-first** application, meaning it works flawlessly without an internet connection. However, to keep your data safe, synchronize across multiple devices, and participate in global leaderboards, NexScore offers flexible cloud integration options.

## Authentication Providers

We currently support two primary providers for authentication. You can access the sign-in options by navigating to the **Account/Profile** tab.

### 1. Google Sign-In (Recommended)
- **Best for**: The vast majority of users, seamless mobile experiences, and instant synchronization.
- **How it works**: NexScore uses Firebase Authentication to securely verify your Google account.
- **Storage**: Your game sessions, player data, and settings are securely synchronized to a private instance on Google Cloud Firestore in real-time. Changes made on your phone will instantly reflect on the Web App.

### 2. GitHub Sign-In (Power Users)
- **Best for**: Developers, privacy advocates, and users who demand complete ownership and visibility over where their data lives.
- **How it works**: NexScore uses Firebase Authentication combined with GitHub OAuth.
- **Storage**: Instead of automatic real-time sync, GitHub users have exclusive access to the **Gist Backup Engine**.

---

## The Gist Backup Engine 🛡️

NexScore provides a unique feature exclusively for users who sign in via GitHub: **User-Owned Private Backups**.

Rather than storing your data on our servers, NexScore can serialize your entire local database and save it as a private [Gist](https://gist.github.com) directly on your own GitHub account.

### How to use Gist Sync:
1. **Authorize**: Sign in with GitHub on the **Account** tab. NexScore will request the `gist` OAuth scope.
2. **Manual Backup**: Tap the **Upload/Backup** icon in the GitHub Gist tile. Your entire local SQLite database (all players, completed sessions, and app settings) is converted to a JSON file and uploaded as a private Gist named `nexscore_backup.json`.
3. **Manual Restore**: On a new device (or after clearing your browser data), sign in with the same GitHub account and tap the **Download/Restore** icon. Your data will be fetched from GitHub and restored instantly, overwriting the empty local database.

!!! important "Privacy & Security Guarantee"
    NexScore ONLY requests the `gist` scope. We cannot read your private repositories, see your organization data, or access your code. Furthermore, the backup Gist is explicitly created as **private**, meaning only you (and the NexScore app while you are logged in) can view the file on GitHub.com.

---

## Local-First Storage (No Account)

If you prefer not to create an account, that is completely fine! NexScore respects your privacy.

- **100% Offline**: All data is stored in a highly optimized, local SQLite database directly on your device.
- **No Feature Paywalls**: You still get full access to history, leaderboards, and all game types.
- **On-Demand Upgrade**: You can use the app offline for months, and if you ever decide to get a new phone, you can simply sign in to Google or GitHub at that moment. NexScore will safely upload your existing local data to the cloud so you can transition devices seamlessly.
