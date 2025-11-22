# Twelve Step App - AI Agent Instructions

## Project Overview

Multi-app Flutter system for AA recovery tools (4th Step Inventory, 8th Step Amends, Evening Ritual) with shared infrastructure. Uses Hive for local storage, Google Drive for cloud sync, and Flutter Modular for DI/routing.

## Architecture Pattern

**Modular Structure**: Each app lives in its own folder (`lib/fourth_step/`, `lib/eighth_step/`, `lib/evening_ritual/`) with app-specific models, services, pages, and localizations. Shared code in `lib/shared/`.

**App Switching**: `AppSwitcherService` stores selected app ID in Hive `settings` box. Apps conditionally render based on `AppSwitcherService.isAppSelected(appId)`. See `lib/app/app_widget.dart` for routing logic.

**Data Isolation**: Each app has separate Hive boxes:
- 4th Step: `entries` (Box<InventoryEntry>), `i_am_definitions` (Box<IAmDefinition>)
- 8th Step: `people_box` (Box<Person>)  
- Evening Ritual: `reflections_box` (Box<ReflectionEntry>)

**Hive Type IDs** (NEVER reuse):
- `typeId: 0` - InventoryEntry
- `typeId: 1` - IAmDefinition  
- `typeId: 2` - AppEntry
- `typeId: 3` - Person
- `typeId: 4` - ColumnType
- `typeId: 5` - ReflectionEntry
- `typeId: 6` - ReflectionType

## Critical Developer Workflows

### Build & Version Management
```bash
# Auto-increment version (1.0.1+36 → 1.0.1+37)
dart scripts/increment_version.dart

# Build with version increment (VS Code tasks)
# Run task: "flutter-debug-with-version-increment"
# Or manually: dart scripts/increment_version.dart && flutter build apk --debug
```

### Code Generation (After Model Changes)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Debugging
- VS Code launch configs in `.vscode/launch.json` support mobile/desktop
- See `docs/VS_CODE_DEBUG.md` for platform-specific setup

## Data Safety Rules

1. **I Am Deletion Protection**: Check usage in entries before deleting (see `lib/fourth_step/pages/settings_tab.dart`). Show count of affected entries if in use.

2. **Import Order**: ALWAYS import I Am definitions BEFORE entries to prevent orphaned references. Export follows same order.

3. **Drive Sync Timestamps**: Use `lastModified` field for conflict detection. Compare remote vs local timestamp before syncing. See `lib/shared/services/google_drive/enhanced_google_drive_service.dart`.

4. **Null Safety**: All I Am references are nullable. Show `-` in UI when I Am not found (never crash).

5. **Data Replacement Warning**: Show warning dialog before JSON import or Drive fetch (ALL local data will be replaced).

## Google Drive Sync Architecture

**Layered Design**:
- **App Layer**: `InventoryDriveService`, `ReflectionDriveService` (model serialization)
- **Enhanced Service**: `EnhancedGoogleDriveService` (debouncing, conflict detection, events)
- **Auth Layer**: `MobileGoogleAuthService` (mobile), `DesktopDriveAuth` (desktop)
- **CRUD Layer**: `GoogleDriveCrudClient` (pure Drive API operations)

**Conflict Detection Pattern**:
```dart
// On app start: compare timestamps
final remoteTimestamp = await fetchRemoteTimestamp();
final localTimestamp = await loadLocalTimestamp();
if (remoteTimestamp.isAfter(localTimestamp)) {
  await syncDownFromDrive(); // Remote is newer
}
```

**Debounced Upload**: Schedule uploads with 700ms debounce to coalesce rapid changes. See `scheduleUpload()` in `EnhancedGoogleDriveService`.

**JSON Format**: Always include `version`, `exportDate`, and `lastModified` fields. Example:
```json
{
  "version": "2.0",
  "exportDate": "2025-11-22T...",
  "lastModified": "2025-11-22T...",
  "entries": [...]
}
```

## Localization System

**Translation Function**: `t(context, 'key')` defined in `lib/shared/localizations.dart`. Returns translated string for current locale (en/da).

**Locale Management**: `LocaleProvider` (ChangeNotifier) injected via Flutter Modular. Change locale with `localeProvider.changeLocale(Locale('da'))`.

**Language Selector**: PopupMenuButton in AppBar actions. Use `LanguageSelectorButton` pattern from `docs/REUSABLE_COMPONENTS.md`.

## Flutter Modular Patterns

**Dependency Injection** (`lib/app/app_module.dart`):
```dart
binds.add(Bind.singleton((i) => LocaleProvider()));
binds.add(Bind.lazySingleton((i) => Box<InventoryEntry>()));
```

**Accessing Services**:
```dart
final provider = Modular.get<LocaleProvider>();
final box = Modular.get<Box<InventoryEntry>>();
```

**Routing**: Single route (`/`) points to `AppHomePage` which wraps the currently selected app.

## Common Patterns

### Hive Box Opening (main.dart)
Always wrap in try-catch. On corruption, delete and recreate:
```dart
try {
  await Hive.openBox<InventoryEntry>('entries');
} catch (e) {
  await Hive.deleteBoxFromDisk('entries');
  await Hive.openBox<InventoryEntry>('entries');
}
```

### CRUD Operations
Use app-specific service classes (`InventoryService`, `PersonService`). These automatically trigger Drive sync when enabled:
```dart
await inventoryService.addEntry(box, entry); // Auto-syncs
await inventoryService.updateEntry(box, index, entry); // Auto-syncs
await inventoryService.deleteEntry(box, index); // Auto-syncs
```

### Conditional App Rendering
```dart
final isInventory = AppSwitcherService.is4thStepInventorySelected();
return isInventory ? FourthStepHome() : EighthStepHome();
```

### App Switcher Dialog
See `_showAppSwitcher()` in any home page. Lists all apps from `AvailableApps.getAll()`, highlights current selection.

## Platform-Specific Code

**Mobile vs Desktop**: Use `PlatformHelper.isMobile` and `PlatformHelper.isDesktop` (see `lib/shared/utils/platform_helper.dart`).

**Google Sign-In**: Only works on mobile. Wrap in platform check:
```dart
if (PlatformHelper.isMobile) {
  await googleSignIn.signIn();
}
```

**Desktop OAuth**: Requires `desktop_oauth_config.dart` (not tracked in git). See `docs/GOOGLE_OAUTH_SETUP.md` for setup.

## Key Files Reference

- **App Entry**: `lib/main.dart` (Hive init, silent sign-in, auto-sync)
- **Routing**: `lib/app/app_module.dart`, `lib/app/app_widget.dart`
- **4th Step Home**: `lib/fourth_step/pages/fourth_step_home.dart`
- **Drive Sync**: `lib/shared/services/google_drive/enhanced_google_drive_service.dart`
- **App Switching**: `lib/shared/services/app_switcher_service.dart`
- **Translations**: `lib/shared/localizations.dart`
- **Version Script**: `scripts/increment_version.dart`

## Documentation

Essential docs in `docs/`:
- `MODULAR_ARCHITECTURE.md` - Detailed app separation strategy
- `REUSABLE_COMPONENTS.md` - Modular components for copying to other projects
- `DATA_SAFETY.md` - Data integrity testing checklist
- `BUILD_SCRIPTS.md` - Version management and build automation

## Testing Considerations

Before making changes that affect data:
1. Export current data to JSON (backup)
2. Test on new installation first
3. Verify I Am references preserved
4. Check Drive sync conflict detection
5. Confirm backward compatibility with old JSON format

## Common Pitfalls

❌ **Don't**: Reuse Hive type IDs  
❌ **Don't**: Delete I Am without checking usage  
❌ **Don't**: Import entries before I Am definitions  
❌ **Don't**: Skip timestamp comparison in Drive sync  
❌ **Don't**: Use `flutter test` (no tests yet)  
✅ **Do**: Use debounced uploads for performance  
✅ **Do**: Show warnings before data replacement  
✅ **Do**: Handle null I Am references gracefully  
✅ **Do**: Include lastModified in all sync JSON
