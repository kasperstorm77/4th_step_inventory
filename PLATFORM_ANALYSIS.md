# Platform Dependencies Analysis

## Platform-Specific Packages

### 1. google_sign_in (Android/iOS only)
**Files:** 
- `lib/pages/data_management_tab.dart`
- `lib/services/google_drive/google_auth_service.dart`
- `lib/google_drive_client.dart`
- `lib/main.dart`

**Status:** ❌ NOT cross-platform
- Android: Works natively
- iOS: Works natively  
- Windows/macOS/Linux: NOT supported
- Web: Has separate implementation

**Replacement for Desktop:**
- Use `desktop_webview_auth` package
- Or implement custom OAuth 2.0 flow

**Action:** Wrap all GoogleSignIn usage with `PlatformHelper.isMobile`

---

### 2. flutter_file_dialog (Android/iOS only)
**Files:**
- `lib/pages/data_management_tab.dart` (line 5)

**Usage:**
- `_exportJson()` - SaveFileDialogParams
- Used for saving JSON export files

**Status:** ❌ NOT cross-platform
- Android: Works
- iOS: Works
- Windows/macOS/Linux: NOT supported

**Replacement for Desktop:**
- Use `file_picker` package's `saveFile()` method (already in dependencies!)

**Action:** Wrap with platform check

---

### 3. file_picker ✅
**Status:** ✅ CROSS-PLATFORM
- Works on all platforms
- No wrapping needed

---

### 4. hive_flutter ✅
**Status:** ✅ CROSS-PLATFORM
- Works on all platforms
- No wrapping needed

---

### 5. googleapis & googleapis_auth ✅
**Status:** ✅ CROSS-PLATFORM
- Works on all platforms after auth
- No wrapping needed

---

## UI Elements Check

### Material Design Widgets ✅
**All platform-independent:**
- `Scaffold`
- `AppBar`
- `TabBar`
- `TextField`
- `ElevatedButton`
- `Card`
- `ListTile`
- `AlertDialog`
- `SnackBar`
- `IconButton`

**No alternatives needed** - Material Design works identically on all platforms.

---

### Adaptive Widgets (Optional Enhancement)
If you want platform-native look and feel:

```dart
// Current: Material (works everywhere)
AlertDialog(...)

// Alternative: Adaptive (looks native on each platform)
if (PlatformHelper.isIOS || PlatformHelper.isMacOS) {
  CupertinoAlertDialog(...)
} else {
  AlertDialog(...)
}
```

**Recommendation:** Keep Material Design for consistency. It works perfectly on all platforms.

---

## Code Locations Requiring Platform Wrapping

### HIGH PRIORITY (Blocking cross-platform)

#### 1. data_management_tab.dart - Google Sign-In
**Lines:** 32, 45-50, 100-200+

```dart
// BEFORE
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

// AFTER
import '../utils/platform_helper.dart';

final GoogleSignIn? _googleSignIn = PlatformHelper.isMobile 
    ? GoogleSignIn(scopes: _scopes)
    : null;
```

#### 2. data_management_tab.dart - File Save Dialog
**Lines:** ~340-350 in `_exportJson()`

```dart
// BEFORE
final params = SaveFileDialogParams(
  data: bytes,
  fileName: 'inventory_export_${DateTime.now().millisecondsSinceEpoch}.json',
);
final savedPath = await FlutterFileDialog.saveFile(params: params);

// AFTER
import '../utils/platform_helper.dart';

String? savedPath;
if (PlatformHelper.isMobile) {
  final params = SaveFileDialogParams(
    data: bytes,
    fileName: 'inventory_export_${DateTime.now().millisecondsSinceEpoch}.json',
  );
  savedPath = await FlutterFileDialog.saveFile(params: params);
} else if (PlatformHelper.isDesktop) {
  savedPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save JSON Export',
    fileName: 'inventory_export_${DateTime.now().millisecondsSinceEpoch}.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  
  if (savedPath != null) {
    await File(savedPath).writeAsBytes(bytes);
  }
}
```

#### 3. services/drive_service.dart - Authentication
**Entire file** uses GoogleSignIn

```dart
// BEFORE
import 'package:google_sign_in/google_sign_in.dart';

// AFTER  
import '../utils/platform_helper.dart';
// Conditional import based on platform
```

---

### MEDIUM PRIORITY (Future enhancement)

#### 4. main.dart - Window Configuration (Desktop)
**Action:** Add desktop window setup

```dart
import '../utils/platform_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Desktop-specific window setup
  if (PlatformHelper.isDesktop) {
    // TODO: Add window_manager configuration
    // await windowManager.ensureInitialized();
    // ... setup window size, title, etc.
  }
  
  // Existing Hive initialization...
}
```

---

## Summary

### Platform Dependencies Matrix

| Package | Android | iOS | Windows | macOS | Linux | Web |
|---------|---------|-----|---------|-------|-------|-----|
| google_sign_in | ✅ | ✅ | ❌ | ❌ | ❌ | ⚠️ |
| flutter_file_dialog | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| file_picker | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| hive_flutter | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| googleapis | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Material Widgets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### Required Actions

1. ✅ Create `PlatformHelper` (DONE)
2. ⏳ Wrap Google Sign-In code
3. ⏳ Wrap FlutterFileDialog code
4. ⏳ Add desktop dependencies (future)
5. ⏳ Implement desktop auth (future)

### UI Elements Status

**✅ ALL UI ELEMENTS ARE CROSS-PLATFORM**

No alternatives needed. Material Design works identically on:
- Android (native feel)
- iOS (works perfectly)
- Windows (works perfectly)
- macOS (works perfectly)  
- Linux (works perfectly)
- Web (works perfectly)

The only platform-specific code is:
1. **Authentication** (GoogleSignIn)
2. **File dialogs** (FlutterFileDialog vs FilePicker.saveFile)

Everything else is already cross-platform!
