## Repository: AA 4Step Inventory (Flutter)

### Project Overview

This is a Flutter application for managing AA 4th step inventory entries with local Hive storage, optional Google Drive sync, and CSV import/export. The app uses **Flutter Modular** architecture for routing and dependency injection.

---

## Architecture & Design Principles

### 1. Modular Architecture (Flutter Modular)

**CRITICAL**: This app uses `flutter_modular`, NOT traditional Navigator/MaterialApp routing.

- **Entry point**: `lib/main.dart` wraps the app in `ModularApp`
- **Main module**: `lib/app/app_module.dart` defines routes and dependency injection
- **Main widget**: `lib/app/app_widget.dart` wraps MaterialApp with locale provider
- **Home page**: `lib/pages/modular_inventory_home.dart` (NOT inventory_home.dart)

**When adding features:**
- Register dependencies in `AppModule.binds()`
- Use `Modular.get<T>()` for dependency injection
- Navigate with `Modular.to.pushNamed()` or `Navigator.push()` for simple routes

### 2. UI Structure (DO NOT MODIFY WITHOUT REASON)

```
ModularInventoryHome
├── AppBar
│   ├── Title: "AA 4Step Inventory" (localized)
│   ├── Gear Icon (Icons.settings) → Data Management Page
│   └── Language Globe (PopupMenuButton) → English/Danish
│
└── TabBarView (3 bottom tabs)
    ├── FormTab (create/edit entries)
    ├── ListTab (table view of all entries)
    └── SettingsTab (empty placeholder - DO NOT add data management here!)
```

**IMPORTANT SEPARATION OF CONCERNS:**
- **Gear Icon → Data Management Page**: Contains ALL CSV export/import, Google Drive sync, sign-in/out, clear data
- **Settings Tab (bottom)**: EMPTY placeholder for future unrelated settings
- **DO NOT** add data management functionality to the settings tab - it belongs ONLY in the data management page

### 3. Data Model

**InventoryEntry** (Hive model, typeId: 0):
```dart
@HiveType(typeId: 0)
class InventoryEntry extends HiveObject {
  @HiveField(0) String? resentment;  // Who/what
  @HiveField(1) String? reason;      // Why
  @HiveField(2) String? affect;      // Which part of self
  @HiveField(3) String? part;        // Specific aspect (self-esteem, etc.)
  @HiveField(4) String? defect;      // Character defect revealed
}
```

**CRITICAL RULES:**
- NEVER change `typeId` (breaks existing data)
- NEVER remove or reorder `@HiveField` indices
- After schema changes, ALWAYS run: `flutter pub run build_runner build --delete-conflicting-outputs`
- Keep `registerAdapter(InventoryEntryAdapter())` in `main.dart`

### 4. CRUD Operations (ALWAYS Use InventoryService)

**DO NOT** directly call `box.add()`, `box.putAt()`, etc. **ALWAYS** use `InventoryService`:

```dart
// Correct:
await _inventoryService.addEntry(box, entry);
await _inventoryService.updateEntry(box, index, entry);
await _inventoryService.deleteEntry(box, index);

// Wrong:
await box.add(entry); // Missing Drive sync trigger!
```

**Why?** `InventoryService` automatically:
1. Performs the Hive operation
2. Triggers Drive sync if enabled
3. Handles error cases consistently

**Direct box operations are ONLY acceptable for:**
- Read operations: `box.getAt(index)`, `box.values.toList()`
- `box.clear()` when immediately followed by `DriveService.instance.scheduleUploadFromBox(box)`

### 5. Google Drive Sync Architecture

**Service Hierarchy:**
```
DriveService (Singleton)
├── GoogleDriveClient (HTTP client wrapper)
└── InventoryDriveService (Clean service layer)
    └── sync_utils.dart (Background serialization)
```

**Sync Flow:**
1. User signs in → `GoogleDriveClient.create(account, token)`
2. Set client → `DriveService.instance.setClient(client)`
3. Enable sync → `DriveService.instance.setSyncEnabled(true)`
4. CRUD operation → `InventoryService` → Auto-triggers `scheduleUploadFromBox()`
5. Debounced upload (700ms) → Background serialization → Drive API upload

**Key Rules:**
- **Debouncing**: Uploads are debounced to coalesce rapid edits (700ms delay)
- **Background work**: Serialization uses `compute()` to avoid blocking UI
- **Early returns**: All Drive methods check `syncEnabled` and `_client != null`
- **Silent sign-in**: Attempted at app startup in `main.dart`
- **Storage location**: Drive AppData folder (hidden from user)
- **File format**: `inventory_entries.json` (JSON array)

**When to call sync:**
```dart
// After single CRUD operation (automatic in InventoryService)
await _inventoryService.addEntry(box, entry);

// After batch operations or box.clear()
await box.clear();
DriveService.instance.scheduleUploadFromBox(box);

// Manual upload (rare)
await DriveService.instance.uploadFile(jsonData);
```

### 6. CSV Import/Export

**Export Flow:**
```dart
1. Serialize entries to CSV (headers: Resentment,Reason,Affect,Part,Defect)
2. Use ListToCsvConverter with CRLF line endings
3. FlutterFileDialog.saveFile() for Android
4. File picker for other platforms
```

**Import Flow:**
```dart
1. FilePicker.platform.pickFiles()
2. CsvToListConverter.convert()
3. Skip header row, parse entries
4. APPEND to existing data (don't replace)
5. Trigger Drive sync if enabled
```

**IMPORTANT**: CSV operations are in `data_management_tab.dart` ONLY (not settings_tab.dart)

### 7. Localization System

**Supported Languages:**
- English (en)
- Danish (da)

**Translation Function:**
```dart
t(context, 'key')  // Returns localized string
```

**Adding New Keys:**
1. Add to `_translations` map in `lib/localizations.dart` for BOTH languages
2. Use consistent naming: lowercase with underscores
3. Group related keys (e.g., `form_*`, `entry_*`, `data_management_*`)

**Locale Switching:**
- `LocaleProvider` (singleton via Modular)
- PopupMenuButton in AppBar with globe icon
- Persisted in Hive settings box
- Entire app rebuilds on locale change

### 8. State Management

**Approach**: Minimal state management with local StatefulWidget state

- **NO** Provider, Riverpod, BLoC, or complex state management
- **YES** StatefulWidget state for UI
- **YES** Hive for persistence
- **YES** Services (InventoryService, DriveService) for business logic
- **YES** Modular for dependency injection

**Why?** Simple app doesn't need complex state management. Keep it maintainable.

### 9. File Organization Rules

```
lib/
├── main.dart                    # App entry, Hive init, silent sign-in
├── app/
│   ├── app_module.dart          # Modular routes & DI
│   └── app_widget.dart          # MaterialApp wrapper
├── models/
│   └── inventory_entry.dart     # Hive data model
├── pages/
│   ├── modular_inventory_home.dart  # MAIN PAGE (TabBar container)
│   ├── form_tab.dart            # Create/edit form
│   ├── list_tab.dart            # Table view
│   ├── settings_tab.dart        # Empty placeholder
│   ├── data_management_page.dart    # Full-screen wrapper
│   └── data_management_tab.dart     # CSV/Drive functionality
├── services/
│   ├── inventory_service.dart   # CRUD operations
│   ├── drive_service.dart       # Sync orchestration
│   ├── inventory_drive_service.dart  # Drive service layer
│   ├── app_version_service.dart # Version management
│   └── locale_provider.dart     # Localization state
│   └── google_drive/            # Drive implementation details
├── utils/
│   └── sync_utils.dart          # Serialization helpers
├── localizations.dart           # Translation system
└── google_drive_client.dart     # HTTP client for Drive API
```

**DO NOT CREATE:**
- `lib/state/` (deleted - not needed)
- `lib/widgets/` (deleted - components inline in pages)
- `lib/platform/` (deleted - no platform abstraction)
- Alternative main files (use `main.dart` only)

### 10. Code Quality Standards

**Before Committing:**
```bash
flutter analyze  # Must pass with no errors
flutter pub run build_runner build --delete-conflicting-outputs  # If models changed
```

**Allowed Warnings:**
- Deprecation warnings (e.g., `withOpacity` → `withValues`)
- Info-level lint suggestions

**NOT Allowed:**
- Compile errors
- Unused imports
- Dead code (unused methods/classes)
- Null safety errors

### 11. Common Pitfalls & Solutions

**Problem**: Changes to modular_inventory_home.dart not appearing
**Solution**: You may be editing the wrong file. The ACTUAL main page is `modular_inventory_home.dart`, NOT `inventory_home.dart` (which was deleted)

**Problem**: Hive data corrupted/not loading
**Solution**: 
```dart
try {
  await Hive.openBox<InventoryEntry>('entries');
} catch (e) {
  await Hive.deleteBoxFromDisk('entries');
  await Hive.openBox<InventoryEntry>('entries');
}
```

**Problem**: Drive sync not working after CRUD operation
**Solution**: Ensure you're using `InventoryService` methods, not direct `box.add()` calls

**Problem**: Build errors after model changes
**Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Problem**: Hot reload not working
**Solution**: Use `flutter run -d <device>` instead of manual `flutter build apk` + `adb install`

**Problem**: Adding features to settings tab
**Solution**: STOP! Settings tab is empty by design. Add data management features to `data_management_tab.dart` only.

### 12. Development Workflow

**Standard Build & Deploy:**
```bash
# Hot reload (recommended)
flutter run -d emulator-5554

# Manual debug build (when hot reload isn't working)
flutter build apk --debug
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk

# Version increment (before release)
dart scripts/increment_version.dart
```

**Tasks Available:**
- `increment-version`: Runs version increment script
- `flutter-debug-with-version-increment`: Increments version + runs debug

---

## Quick Reference Examples

### Adding a New Entry
```dart
final entry = InventoryEntry(
  resentment,
  reason, 
  affect,
  part,
  defect,
);
await _inventoryService.addEntry(box, entry);
```

### Editing an Entry
```dart
final entry = box.getAt(index);
entry.resentment = newValue;
await _inventoryService.updateEntry(box, index, entry);
```

### Deleting an Entry
```dart
await _inventoryService.deleteEntry(box, index);
```

### Checking Sync Status
```dart
if (DriveService.instance.syncEnabled && DriveService.instance.client != null) {
  // Sync is active
}
```

### Adding Translation
```dart
// In localizations.dart
'new_key': {
  'en': 'English text',
  'da': 'Dansk tekst',
},

// In widget
Text(t(context, 'new_key'))
```

---

## AI Agent Guidelines

**When making changes:**

1. **READ FIRST**: Check current file structure with grep/semantic search before assuming file locations
2. **PRESERVE ARCHITECTURE**: Don't refactor to Provider/BLoC/GetX - keep the existing simple approach
3. **USE SERVICES**: Never bypass InventoryService for CRUD operations
4. **RESPECT SEPARATION**: Data management in gear icon page, NOT settings tab
5. **TEST SYNC**: After CRUD changes, verify Drive sync still triggers
6. **REGENERATE ADAPTERS**: After model changes, run build_runner
7. **CHECK ANALYZER**: Run `flutter analyze` before committing

**When asked to add features:**
- Ask WHERE it should go (form, list, data management, or new page)
- Don't assume settings tab is the right place
- Consider impact on Drive sync
- Check if localization keys are needed

**When debugging:**
- Check console output for Hive errors
- Verify `modular_inventory_home.dart` is being used (not deleted files)
- Confirm InventoryService is being called
- Look for null safety issues with Drive client

---

## Files to Reference

**Architecture**: `lib/main.dart`, `lib/app/app_module.dart`
**Data Model**: `lib/models/inventory_entry.dart`
**CRUD**: `lib/services/inventory_service.dart`
**Sync**: `lib/services/drive_service.dart`, `lib/services/inventory_drive_service.dart`
**UI**: `lib/pages/modular_inventory_home.dart`
**Localization**: `lib/localizations.dart`

---

**If unclear, ask:**
- Which file should this feature go in?
- Should this trigger Drive sync?
- Does this need localization?
- Will this affect existing data?
