# AA 4Step Inventory

A Flutter application for managing 4th step inventory entries with local storage, Google Drive sync, and CSV import/export capabilities.

## Overview

This app helps users create and manage inventory entries following the AA 4-step process. Each entry contains:
- **Resentment**: Who or what you're resentful towards
- **Reason**: Why you're resentful
- **Affect**: Which part of self was affected
- **Part**: Specific aspect affected (self-esteem, security, etc.)
- **Defect**: Character defect revealed

## Architecture

### UI Structure

The app uses **Flutter Modular** architecture with a tab-based interface:

```
ModularInventoryHome (Main Container)
├── AppBar
│   ├── Title: "AA 4Step Inventory"
│   └── Actions
│       ├── Gear Icon (Settings) → Opens Data Management Page
│       └── Language Selector (Globe Icon) → English/Danish toggle
│
└── TabBarView (3 tabs)
    ├── FormTab: Create/Edit entries
    ├── ListTab: View all entries in table format
    └── SettingsTab: Empty placeholder for future settings
```

**Data Management Page** (accessed via gear icon):
- Google Sign In/Out
- Sync toggle (enable/disable Google Drive sync)
- Export to CSV
- Import from CSV
- Fetch from Google Drive
- Clear all entries

### Data Model

**InventoryEntry** (Hive model, typeId: 0)
```dart
@HiveType(typeId: 0)
class InventoryEntry extends HiveObject {
  @HiveField(0) String? resentment;
  @HiveField(1) String? reason;
  @HiveField(2) String? affect;
  @HiveField(3) String? part;
  @HiveField(4) String? defect;
}
```

**Storage**: Local Hive database (`entries` box)

### CRUD Operations

All CRUD operations are handled by `InventoryService`:

**Create:**
```dart
await _inventoryService.addEntry(box, entry);
// Automatically triggers Drive sync if enabled
```

**Read:**
```dart
final entries = box.values.toList();
// or
final entry = box.getAt(index);
```

**Update:**
```dart
await _inventoryService.updateEntry(box, index, updatedEntry);
// Automatically triggers Drive sync if enabled
```

**Delete:**
```dart
await _inventoryService.deleteEntry(box, index);
// Automatically triggers Drive sync if enabled
```

**Clear All:**
```dart
await box.clear();
DriveService.instance.scheduleUploadFromBox(box); // Sync empty state
```

### Google Drive Sync

**Architecture:**
- `DriveService`: Singleton managing sync state and operations
- `GoogleDriveClient`: Handles Drive API communication
- `InventoryDriveService`: Clean service layer for Drive operations
- `sync_utils.dart`: Background serialization helpers

**Sync Flow:**
1. User signs in via Google (OAuth)
2. App creates `GoogleDriveClient` with auth tokens
3. Sync toggle enables/disables automatic uploads
4. CRUD operations trigger debounced uploads (700ms)
5. Data stored in Drive AppData folder as `inventory_entries.json`

**Key Features:**
- Silent sign-in at app startup
- Debounced uploads to coalesce rapid changes
- Background serialization using `compute()` isolates
- Conflict resolution: Drive data overwrites local on fetch

### CSV Import/Export

**Export:**
```dart
await _exportCsv();
// Creates CSV with headers: Resentment,Reason,Affect,Part,Defect
// Uses platform file picker to save
```

**Import:**
```dart
await _importCsv();
// Reads CSV file
// Appends entries to existing data
// Triggers Drive sync if enabled
```

### Localization

Supports **English (en)** and **Danish (da)**:

```dart
t(context, 'key') // Translation helper function
```

**Key translations:**
- `app_title`: "AA 4Step Inventory" / "AA 4 trins opgørelse"
- `data_management`: "Data Management" / "Data Håndtering"
- `form_title`, `entries_title`, `settings_title`
- `export_csv`, `import_csv`, `sync_google_drive`
- Form field labels and validation messages

**Language toggle:** Globe icon in AppBar switches locale, persisted across sessions.

## Development

### Setup
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run
```bash
flutter run -d <device>
```

### Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle
flutter build appbundle --release
```

### Version Increment
```bash
dart scripts/increment_version.dart
```

### Code Quality
```bash
flutter analyze
```

## Key Files

- `lib/main.dart`: App initialization, Hive setup, silent sign-in
- `lib/pages/modular_inventory_home.dart`: Main UI container
- `lib/pages/form_tab.dart`: Entry creation/editing form
- `lib/pages/list_tab.dart`: Table view of entries
- `lib/pages/data_management_tab.dart`: CSV/Drive functionality
- `lib/models/inventory_entry.dart`: Data model
- `lib/services/drive_service.dart`: Google Drive sync logic
- `lib/services/inventory_service.dart`: CRUD operations
- `lib/localizations.dart`: Translation system

## Dependencies

- **flutter_modular**: Routing and dependency injection
- **hive/hive_flutter**: Local NoSQL database
- **google_sign_in**: Google authentication
- **http**: Drive API communication
- **csv**: CSV parsing
- **file_picker**: File selection
- **flutter_file_dialog**: Save file dialogs

## Platform Support

- ✅ Android (full support with Google Drive sync)
- ✅ iOS (tested)
- ⚠️ Windows/Linux/Web (limited - no file picker support)
