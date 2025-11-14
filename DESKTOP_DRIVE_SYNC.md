# Desktop Google Drive Sync - User Guide

## Overview

The Windows/macOS/Linux desktop version now supports **manual Google Drive sync** with the same backend as the Android/iOS app. Your data syncs to the same location in Google Drive's AppDataFolder, allowing seamless data transfer between mobile and desktop.

---

## Features

### ✅ What Works on Desktop

- **Upload to Google Drive** - Manually upload your current inventory to Drive
- **Import from Google Drive** - Manually download and import from Drive
- **Same Data Format** - Uses identical JSON format as mobile (v2.0)
- **Same Drive Location** - Stores in the same AppDataFolder as mobile app
- **Bi-directional Sync** - Changes on desktop appear on mobile and vice versa

### 🔄 Difference from Mobile

| Feature | Android/iOS | Windows/macOS/Linux |
|---------|-------------|---------------------|
| Authentication | Auto sign-in | Manual OAuth each time |
| Sync Trigger | Automatic on CRUD | Manual button press |
| Persistence | Stays signed in | Re-auth per operation |
| UX | Seamless background | Deliberate user action |

---

## How to Use

### First Time Setup

1. **Launch the app on Windows**
2. **Navigate to Data Management tab**
3. You'll see a blue banner: "Desktop: Use manual Google Drive sync below"

No configuration needed - just use the buttons when you want to sync!

---

### Upload to Google Drive

**When to use:** After making changes on desktop that you want available on mobile

1. Click **"Upload to Google Drive (Manual)"** button
2. A browser window opens with Google sign-in
3. Sign in with your Google account (same one as on mobile)
4. Grant permission to access Drive AppDataFolder
5. Browser closes automatically
6. App uploads your data
7. Success message appears: "Uploaded X entries to Google Drive"

**Note:** Each upload overwrites the previous Drive backup (same as mobile)

---

### Import from Google Drive

**When to use:** To get data from mobile or another desktop, or to restore a backup

1. Click **"Import from Google Drive"** button
2. Browser opens for Google sign-in
3. Sign in and grant permissions
4. Browser closes
5. **WARNING DIALOG** appears:
   - "This will REPLACE all current data with data from Google Drive"
   - "Make sure you have exported your current data first!"
6. Click **"Import from Drive"** to confirm
7. Data downloads and replaces local data
8. Success message: "Imported X entries from Google Drive"

**⚠️ IMPORTANT:** Import is destructive! Export first if you have local changes you want to keep.

---

## Workflow Examples

### Scenario 1: Start on Desktop, Continue on Mobile

1. **Desktop:** Create entries in the desktop app
2. **Desktop:** Click "Upload to Google Drive"
3. **Mobile:** Open app (auto-syncs on launch)
4. **Mobile:** Your desktop entries appear automatically

### Scenario 2: Start on Mobile, Continue on Desktop

1. **Mobile:** Create entries (auto-uploads to Drive)
2. **Desktop:** Open app
3. **Desktop:** Click "Import from Google Drive"
4. **Desktop:** Confirm import
5. **Desktop:** Your mobile entries appear

### Scenario 3: Work on Both Platforms

**Option A - Desktop First:**
1. **Desktop:** Make changes
2. **Desktop:** Upload to Drive
3. **Mobile:** Open app (auto-fetches)

**Option B - Mobile First:**
1. **Mobile:** Make changes (auto-uploads)
2. **Desktop:** Import from Drive

**⚠️ Important:** Last upload wins! If you work offline on both platforms, one set of changes will be lost. Always sync before switching platforms.

---

## Authentication Details

### Why Re-authenticate Each Time?

Desktop OAuth uses a different flow than mobile:
- **Mobile:** Persistent sign-in via Google Sign-In SDK
- **Desktop:** Browser-based OAuth with temporary tokens

This is normal behavior for desktop applications and provides better security.

### What Permissions Are Requested?

- **Email:** To identify your Google account
- **Drive AppDataFolder:** To read/write your inventory data

Your data is stored in a special AppDataFolder that:
- Only your app can access
- Users cannot see in regular Drive
- Automatically backs up with Drive
- Syncs across all your devices

---

## Troubleshooting

### "Authentication cancelled"

**Cause:** You closed the browser before completing sign-in

**Solution:** Try again and complete the Google sign-in flow

### "No data found in Google Drive"

**Cause:** You haven't uploaded from mobile or desktop yet

**Solution:** 
1. Create some entries
2. Click "Upload to Google Drive"
3. Then try import again

### "Upload/Import failed: [error]"

**Possible causes:**
- No internet connection
- Google Drive API quota exceeded (rare)
- Invalid OAuth credentials

**Solution:**
1. Check internet connection
2. Try again in a few minutes
3. If persists, use JSON export/import as alternative

### Browser doesn't open

**Cause:** System doesn't have default browser set

**Solution:** Set a default web browser in Windows/macOS settings

---

## Security & Privacy

### Is My Data Safe?

✅ **Yes!** Your data is:
- Stored in Google Drive's AppDataFolder (not visible in regular Drive)
- Encrypted in transit (HTTPS)
- Only accessible with your Google credentials
- Backed up automatically by Google

### Can Others See My Inventory?

❌ **No!** 
- Only you can access your AppDataFolder data
- Even if you share your Google Drive, they can't see app data
- The app only requests minimal permissions

### What About the OAuth Credentials in Code?

✅ **Safe!** 
- These are public "Client ID" credentials
- They identify the app, not you
- Google requires these for OAuth
- Your personal credentials are obtained during sign-in
- Industry-standard practice for desktop apps

---

## Alternative: JSON Export/Import

If you prefer not to use Google Drive on desktop:

1. **Mobile:** Export JSON
2. **Transfer:** Email/USB/cloud storage
3. **Desktop:** Import JSON

This works identically to Drive sync but requires manual file transfer.

---

## Tips & Best Practices

### ✅ DO:
- Upload to Drive after major desktop editing sessions
- Import from Drive before starting desktop work
- Export JSON backups periodically (extra safety)
- Use the same Google account on all devices

### ❌ DON'T:
- Work offline on both platforms simultaneously
- Import without exporting first (if you have local changes)
- Use different Google accounts (data won't sync)

---

## Technical Notes

### Same Backend as Mobile

The desktop implementation uses:
- **Same API:** `googleapis` package
- **Same endpoints:** Google Drive API v3
- **Same storage:** AppDataFolder
- **Same format:** JSON v2.0 with entries and I Am definitions

The only difference is the authentication method:
- **Mobile:** `google_sign_in` package (persistent)
- **Desktop:** `desktop_webview_auth` package (on-demand)

### Data Format Compatibility

100% compatible! The desktop sync creates identical JSON to mobile:

```json
{
  "version": "2.0",
  "exportDate": "2025-11-14T10:30:00.000Z",
  "iAmDefinitions": [...],
  "entries": [...]
}
```

---

## Support

If you encounter issues:

1. **Try JSON export/import** as a workaround
2. **Check Google account** is the same on all devices
3. **Verify internet connection**
4. **Restart the app** and try again

The manual Drive sync is completely separate from Android auto-sync, so if one has issues, the other still works!
