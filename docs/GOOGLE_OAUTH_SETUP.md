# Google OAuth Setup

This document covers OAuth setup for **desktop platforms only** (Windows/macOS/Linux). Mobile (Android/iOS) platforms have OAuth already configured and working.

## Platform Status

- ✅ **Android**: OAuth configured via SHA-1 fingerprint + package name (no setup needed)
- ✅ **iOS**: OAuth configured via iOS client ID in code and Info.plist (no setup needed)
- ⚙️ **Windows/macOS/Linux**: Requires OAuth setup (this document)

## Desktop OAuth Setup (Windows/macOS/Linux)

Desktop platforms use the **Loopback IP Address** OAuth method. This is the Google-recommended approach for native desktop apps - it starts a local HTTP server on `127.0.0.1` to receive the OAuth callback.

### Step 1: Create OAuth Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Select your project (or create a new one)
3. Click **"Create Credentials"** → **"OAuth client ID"**
4. Choose Application type: **"Desktop app"**
5. Give it a name (e.g., "12 Steps App - Desktop")
6. Click **"Create"**

You'll get:
- **Client ID**: Something like `1234567890-abc123def456.apps.googleusercontent.com`
- **Client Secret**: Something like `GOCSPX-abc123def456`

### Step 2: Enable Google Drive API

1. In Google Cloud Console, go to **"APIs & Services"** → **"Library"**
2. Search for **"Google Drive API"**
3. Click **"Enable"**

### Step 3: Add Credentials to Your App

Copy the template configuration file:

```bash
cp lib/shared/services/google_drive/desktop_oauth_config.dart.template \
   lib/shared/services/google_drive/desktop_oauth_config.dart
```

Open `lib/shared/services/google_drive/desktop_oauth_config.dart` and replace:

```dart
const String desktopOAuthClientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
const String desktopOAuthClientSecret = 'YOUR_CLIENT_SECRET';
```

With your actual credentials:

```dart
const String desktopOAuthClientId = '1234567890-abc123def456.apps.googleusercontent.com';
const String desktopOAuthClientSecret = 'GOCSPX-abc123def456';
```

**Note**: The file `desktop_oauth_config.dart` is gitignored for security. The template is tracked in git for reference.

### Step 4: Test the Flow

1. Run the app on Windows: `flutter run -d windows`
2. Go to **Data Management** tab
3. Click **"Sign in to Google"**
4. Browser opens automatically
5. Sign in to Google and grant permissions
6. Browser shows "Sign-in Successful!" page
7. Return to app - you're now signed in!

## How It Works

### Loopback IP Address Flow

Google requires desktop apps to use the loopback address method (custom URI schemes are not supported for desktop apps).

```
┌─────────┐           ┌─────────┐           ┌────────────┐
│  User   │           │   App   │           │   Google   │
└────┬────┘           └────┬────┘           └─────┬──────┘
     │                     │                      │
     │  1. Click sign-in   │                      │
     ├────────────────────►│                      │
     │                     │                      │
     │                     │  2. Start local      │
     │                     │  HTTP server on      │
     │                     │  127.0.0.1:PORT      │
     │                     │                      │
     │                     │  3. Open browser     │
     │                     │  with OAuth URL      │
     │                     ├─────────────────────►│
     │                     │                      │
     │  4. Sign in & authorize                    │
     ├───────────────────────────────────────────►│
     │                     │                      │
     │                     │  5. Google redirects │
     │                     │  to 127.0.0.1:PORT   │
     │                     │◄─────────────────────┤
     │                     │                      │
     │  6. Browser shows   │  6. App receives     │
     │  success page       │  auth code           │
     │◄────────────────────┤                      │
     │                     │                      │
     │                     │  7. Exchange code    │
     │                     │  for tokens          │
     │                     ├─────────────────────►│
     │                     │                      │
     │                     │  8. Return tokens    │
     │                     │◄─────────────────────┤
     │                     │                      │
     │  9. App shows       │  9. Credentials      │
     │  signed in!         │  cached locally      │
     │◄────────────────────┤                      │
```

### Why Loopback IP?

✅ **Google-approved** - Required method for desktop apps (custom schemes deprecated)
✅ **Automatic** - No manual code copying needed
✅ **Secure** - OAuth 2.0 standard flow
✅ **No external server** - Everything runs locally
✅ **No firewall issues** - Loopback address is always accessible

### Security Notes

- **Client ID & Secret**: For desktop apps, these identify your app (not true secrets like server apps)
- **Loopback-only**: Server only binds to `127.0.0.1`, not accessible from network
- **Temporary server**: Server stops immediately after receiving the callback
- **Refresh tokens**: Stored locally in Hive, allows silent re-auth

## Troubleshooting

### "Invalid client" error

**Cause:** Wrong client ID or secret

**Solution:**
1. Double-check you copied the full client ID and secret
2. Make sure you selected "Desktop app" type in Google Cloud Console

### "Access blocked" error

**Cause:** Google Drive API not enabled

**Solution:**
1. Go to Google Cloud Console
2. APIs & Services → Library
3. Search "Google Drive API"
4. Click Enable

### "redirect_uri_mismatch" error

**Cause:** OAuth client type mismatch

**Solution:** Ensure you created a **"Desktop app"** OAuth client, not "Web application". Desktop clients automatically allow loopback redirects.

### Browser doesn't open

**Cause:** No default browser or url_launcher issue

**Solution:**
1. Set a default web browser in Windows settings
2. Try running the app as administrator

### Port already in use

**Cause:** Another process is using the randomly selected port

**Solution:** This is extremely rare with random port selection. Try signing in again - a different port will be used.

## Mobile Platforms

### Android
- **Already configured** - uses Android OAuth client
- **Authentication**: SHA-1 fingerprint + package name
- **No code changes needed** - works out of the box
- **Setup required**: Register your debug SHA-1 in Google Cloud Console (see `docs/LOCAL_SETUP.md`)

### iOS
- **Already configured** - uses iOS OAuth client  
- **Configured in**: `lib/shared/services/google_drive/mobile_google_auth_service.dart` and `ios/Runner/Info.plist`
- **No code changes needed** - works out of the box
