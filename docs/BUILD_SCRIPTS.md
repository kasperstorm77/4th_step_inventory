# Build Scripts

This project includes automatic version increment and platform-specific build scripts.

## Scripts Available

| Script | Purpose |
|--------|---------|
| `scripts/increment_version.dart` | Auto-increment build number in pubspec.yaml |
| `scripts/build_windows_release.ps1` | Build Windows release and create ZIP distribution |

## VS Code Tasks

Run via `Ctrl+Shift+P` → "Tasks: Run Task":

| Task | Description |
|------|-------------|
| `increment-version` | Just increment the version number |
| `flutter-debug-with-version-increment` | Increment version + run debug build |
| `build-windows-release-zip` | Increment version + build Windows release + create ZIP |

## Usage

### Increment Version Only
```powershell
dart scripts/increment_version.dart
```
Changes `1.0.1+47` → `1.0.1+48` in pubspec.yaml

### Android Release
```powershell
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Windows Release + ZIP Distribution
```powershell
.\scripts\build_windows_release.ps1
# Output: build/releases/twelvestepsapp-windows-{version}.zip
```

This script:
1. Builds Windows release
2. Reads version from pubspec.yaml
3. Creates ZIP with all required files
4. Reports file size and location

### Windows Debug
```powershell
flutter run -d windows
```

## Version Format

The app uses semantic versioning with build number:
```yaml
version: 1.0.1+48  # major.minor.patch+buildNumber
```

- **major.minor.patch** - Displayed to users
- **buildNumber** - Internal tracking, auto-incremented by scripts

## Version Detection in App

The app automatically detects new installations and updates using the `AppVersionService`:

- **New Installation**: When the app is installed for the first time, it will prompt to fetch data from Google Drive if the user is signed in
- **App Update**: When the app version changes, it will also prompt for Google Drive sync
- **Debug Mode**: Additional console output shows version detection details

## Distribution

### Android
Upload `build/app/outputs/flutter-apk/app-release.apk` to Play Store or distribute directly.

### Windows
Distribute the ZIP file from `build/releases/`. Users extract and run `twelvestepsapp.exe` directly - no installation required.