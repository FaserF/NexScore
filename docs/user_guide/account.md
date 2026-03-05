# Account & Cloud Sync ☁️

NexScore offers flexible options to keep your data safe and synchronized across all your devices.

## Authentication Options

We support two primary providers for authentication:

### 1. Google Account
- **Best for**: Most users, mobile devices, and seamless web entry.
- **Technology**: Uses Firebase Authentication and Google Sign-In.
- **Storage**: Data is securely stored in a private Firestore instance.

### 2. GitHub Account
- **Best for**: Developers and power users who want full ownership of their data.
- **Technology**: Uses Firebase Authentication and GitHub OAuth.
- **Storage**: In addition to standard cloud sync, GitHub users have access to **Gist Backup**.

## GitHub Gist Backup 🛡️

NexScore provides a unique feature for GitHub users: **User-Owned Backups**.

When you sign in with GitHub, NexScore can create a private [Gist](https://gist.github.com) on your behalf called `nexscore_backup.json`.

### How it works:
1. **Authorize**: Sign in with GitHub on the **Account** tab.
2. **Backup**: Tap the **Upload** icon in the GitHub Gist tile. Your entire local database (players, sessions, settings) is serialized and uploaded to your private Gist.
3. **Restore**: On a new device, sign in with the same GitHub account and tap the **Download** icon. Your data will be restored instantly.

!!! important "Privacy"
    NexScore only requests the `gist` scope. We cannot see your other repositories or private data. The backup Gist is created as **private**, meaning only you can see it on GitHub.

## Local-First Storage

Even if you don't sign in, NexScore works perfectly! All data is stored in a local SQLite database on your device.

- **Offline Support**: You can record games without an internet connection.
- **On-Demand Sync**: You can choose to sign in at any time to upload your existing local data to the cloud.
