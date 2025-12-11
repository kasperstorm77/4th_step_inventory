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

## Automatic Sync

The app automatically syncs with Google Drive using timestamp comparison:

- **On App Start**: `main.dart` calls `AllAppsDriveService.checkAndSyncIfNeeded()` which compares the local `lastModified` timestamp with the remote backup
- **If Remote is Newer**: Data is automatically downloaded and merged
- **Manual Restore**: Users can always manually restore from any backup via Data Management page
- **Debug Mode**: Additional console output shows sync detection details

## Distribution

### Android
Upload `build/app/outputs/flutter-apk/app-release.apk` to Play Store or distribute directly.

### Windows
Distribute the ZIP file from `build/releases/`. Users extract and run `twelvestepsapp.exe` directly - no installation required.