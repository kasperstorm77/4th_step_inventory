# Windows Migration Plan

## Goal
Create a Windows desktop version with Drive sync while maintaining 100% Android functionality and UI.

## Current State Analysis

### ✅ Already Cross-Platform Compatible
1. **Flutter Framework** - Works on Windows out of the box
2. **Hive Database** - Cross-platform local storage
3. **UI Components** - Material Design works on Windows
4. **File Picker** - `file_picker` package supports Windows
5. **Core Logic** - All business logic is platform-agnostic

### ⚠️ Needs Adaptation for Windows

#### 1. Google Sign-In (Critical)
**Current:** `google_sign_in` package (Android-specific implementation)
**Issue:** Different OAuth flow required for Windows desktop apps
**Solution:**
- Use `google_sign_in_desktop` or `desktop_webview_auth` package
- Or implement custom OAuth 2.0 flow with localhost redirect
- Keep Android implementation intact with conditional imports

#### 2. File Storage Paths
**Current:** `flutter_file_dialog` for Android
**Issue:** Windows uses different file picker
**Solution:**
- `file_picker` already supports Windows (✅ already used)
- `flutter_file_dialog` needs Windows alternative for save dialog
- Use `path_provider` to get Windows documents folder

#### 3. Window Management
**Current:** Mobile-first UI
**Issue:** Desktop needs resizable windows, different aspect ratios
**Solution:**
- Use `window_manager` package for window control
- Add responsive breakpoints for desktop sizing
- Maintain mobile UI/UX on Windows

## Implementation Strategy

### Phase 1: Platform Abstraction Layer ✅
Create platform-specific services that maintain same API:

```
lib/
  platform/
    auth_service.dart (interface)
    auth_service_android.dart
    auth_service_windows.dart
    file_service.dart (interface)
    file_service_android.dart
    file_service_windows.dart
```

### Phase 2: Google Drive Authentication
**Option A: Desktop WebView (Recommended)**
```yaml
dependencies:
  desktop_webview_auth: ^0.0.15
  google_sign_in: ^6.2.1 # Keep for Android
```

**Option B: Custom OAuth with Localhost**
```yaml
dependencies:
  oauth2: ^2.0.2
  url_launcher: ^6.3.0
```

**Implementation:**
- Detect platform at runtime
- Use appropriate auth mechanism
- Store tokens securely (Windows Credential Manager for Windows)
- Maintain same DriveService API

### Phase 3: File Management
**Windows-Specific Changes:**

```yaml
dependencies:
  file_picker: ^8.1.6 # Already have ✅
  path_provider: ^2.1.5 # For Windows paths
```

**Code Changes:**
```dart
// Replace flutter_file_dialog with platform-aware solution
if (Platform.isWindows) {
  // Use file_picker's saveFile method
} else if (Platform.isAndroid) {
  // Use flutter_file_dialog
}
```

### Phase 4: Window Configuration
```yaml
dependencies:
  window_manager: ^0.4.4
```

**main.dart additions:**
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      title: '4th Step Inventory',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // Rest of initialization...
}
```

### Phase 5: UI Adaptations (Minimal)
**Maintain Android UI, add desktop enhancements:**

1. **Responsive Layouts:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isDesktop = constraints.maxWidth > 800;
    return isDesktop 
      ? _buildDesktopLayout()
      : _buildMobileLayout(); // Keep Android UI
  }
)
```

2. **Menu Bar (Windows only):**
```dart
if (Platform.isWindows) {
  PlatformMenuBar(
    menus: [
      PlatformMenu(label: 'File', menus: [...]),
      PlatformMenu(label: 'Edit', menus: [...]),
    ],
  )
}
```

## Detailed Implementation Steps

### Step 1: Add Windows Dependencies
```yaml
# pubspec.yaml
dependencies:
  # Existing...
  
  # Windows-specific
  desktop_webview_auth: ^0.0.15
  window_manager: ^0.4.4
  path_provider: ^2.1.5
  
  # Platform detection
  flutter:
    sdk: flutter
```

### Step 2: Create Platform Service Layer
**lib/platform/platform_service.dart:**
```dart
abstract class PlatformService {
  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  static bool get isMobile =>
      Platform.isAndroid || Platform.isIOS;
}
```

### Step 3: Implement Windows Auth
**lib/platform/auth/google_auth_windows.dart:**
```dart
import 'package:desktop_webview_auth/desktop_webview_auth.dart';

class GoogleAuthWindows {
  static const clientId = 'YOUR_WINDOWS_CLIENT_ID.apps.googleusercontent.com';
  static const scopes = ['email', 'https://www.googleapis.com/auth/drive.appdata'];
  
  Future<AuthResult> signIn() async {
    return await DesktopWebviewAuth.signIn(
      DesktopWebviewAuthOptions(
        clientId: clientId,
        redirectUri: 'http://localhost:8080',
        scope: scopes.join(' '),
      ),
    );
  }
}
```

### Step 4: Update DriveService
**lib/services/drive_service.dart:**
```dart
// Add platform-aware authentication
Future<void> _initializeDriveClient() async {
  if (Platform.isAndroid) {
    // Existing Android flow
  } else if (Platform.isWindows) {
    // Windows OAuth flow
    final auth = await GoogleAuthWindows().signIn();
    _driveClient = await GoogleDriveClient.create(
      googleAccount, // Adapt to use auth result
      auth.accessToken,
    );
  }
}
```

### Step 5: Update File Management
**lib/pages/data_management_tab.dart:**
```dart
Future<void> _exportJson() async {
  final jsonString = // ... generate JSON
  
  if (Platform.isWindows) {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save JSON Export',
      fileName: 'inventory_export_${DateTime.now().millisecondsSinceEpoch}.json',
      allowedExtensions: ['json'],
    );
    
    if (outputFile != null) {
      await File(outputFile).writeAsString(jsonString);
    }
  } else {
    // Existing Android implementation
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final params = SaveFileDialogParams(data: bytes, fileName: '...');
    await FlutterFileDialog.saveFile(params: params);
  }
}
```

### Step 6: Initialize Windows
**main.dart:**
```dart
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Windows-specific initialization
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 900),
      minimumSize: Size(800, 600),
      center: true,
      title: '4th Step Inventory',
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // Existing Hive initialization...
  await Hive.initFlutter();
  // ... rest of init
}
```

## Testing Strategy

### Android Testing (Ensure No Regression)
- [ ] All existing features work identically
- [ ] Google Drive sync unchanged
- [ ] File export/import works
- [ ] UI/UX identical to current version
- [ ] Performance not degraded

### Windows Testing
- [ ] App launches and window appears correctly
- [ ] Hive database initializes in Windows AppData
- [ ] Google OAuth flow completes successfully
- [ ] Drive sync uploads/downloads work
- [ ] JSON export/import with native file dialogs
- [ ] I Am CRUD operations
- [ ] Entry CRUD operations
- [ ] Responsive UI adapts to window resizing
- [ ] Window can be minimized/maximized/closed

## File Structure Changes

```
lib/
  platform/
    platform_service.dart (NEW)
    auth/
      auth_service.dart (NEW - interface)
      google_auth_android.dart (NEW - refactor existing)
      google_auth_windows.dart (NEW)
    storage/
      file_service.dart (NEW - interface)
      file_service_android.dart (NEW)
      file_service_windows.dart (NEW)
  
  services/
    drive_service.dart (MODIFY - add platform detection)
  
  pages/
    data_management_tab.dart (MODIFY - platform-aware file dialogs)
  
  main.dart (MODIFY - add Windows initialization)
```

## Dependencies to Add

```yaml
dependencies:
  # Windows-specific
  desktop_webview_auth: ^0.0.15  # OAuth for desktop
  window_manager: ^0.4.4         # Window control
  path_provider: ^2.1.5          # Platform paths
  
  # Keep existing Android dependencies
  google_sign_in: ^6.2.1
  flutter_file_dialog: ^3.0.2
  # ... all others
```

## Configuration Files

### Windows OAuth Credentials
Create separate OAuth 2.0 credentials in Google Cloud Console:
- Application type: "Desktop application"
- Download credentials JSON
- Store client ID in environment or config

### pubspec.yaml Platform Configuration
```yaml
flutter:
  # Existing config...
  
  # Platform-specific assets
  assets:
    - assets/
  
  # Conditional compilation
  platforms:
    android:
      default: true
    windows:
      default: true
```

## Risks & Mitigation

### Risk 1: OAuth Complexity
**Mitigation:** Use well-tested `desktop_webview_auth` package

### Risk 2: Breaking Android
**Mitigation:** Platform-specific imports, extensive testing

### Risk 3: UI Differences
**Mitigation:** Keep Android UI as default, enhance for desktop only where necessary

### Risk 4: File Path Issues
**Mitigation:** Use `path_provider` for all path operations

## Success Criteria

✅ **Must Have:**
1. Windows app runs and looks identical to Android version
2. Google Drive sync works on Windows
3. All Android functionality preserved 100%
4. JSON import/export works on both platforms
5. I Am feature works identically

✅ **Nice to Have:**
1. Native Windows file dialogs
2. Resizable window with responsive layout
3. Windows-style menu bar
4. Keyboard shortcuts (Ctrl+S, Ctrl+O, etc.)

## Timeline Estimate

- Phase 1 (Platform Abstraction): 2-3 hours
- Phase 2 (Windows Auth): 3-4 hours  
- Phase 3 (File Management): 1-2 hours
- Phase 4 (Window Config): 1 hour
- Phase 5 (UI Polish): 2-3 hours
- Testing: 3-4 hours

**Total: ~15-20 hours**

## Next Steps

1. ✅ Review and approve this plan
2. Create feature branch: `feature/windows-support`
3. Add Windows dependencies
4. Implement platform service layer
5. Test Android (ensure no regression)
6. Implement Windows auth
7. Test Windows functionality
8. Merge to main
