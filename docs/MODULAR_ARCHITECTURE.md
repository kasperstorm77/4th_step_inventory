# Modular Architecture - Twelve Step App

## Overview
This document describes the modular architecture separating the 4th Step Inventory and 8th Step Amends apps with shared common components.

## Directory Structure

```
lib/
├── main.dart                        # App entry point
├── app/                            # App-level configuration
│   ├── app_module.dart
│   └── app_widget.dart
│
├── shared/                         # SHARED COMPONENTS (Common to all apps)
│   ├── models/
│   │   ├── app_entry.dart         # Multi-app system definition
│   │   └── app_entry.g.dart
│   │
│   ├── services/
│   │   ├── app_switcher_service.dart    # App switching logic
│   │   ├── locale_provider.dart         # Language management
│   │   ├── app_version_service.dart     # Version tracking
│   │   └── google_drive/               # Drive sync (shared)
│   │       ├── desktop_drive_auth.dart
│   │       ├── desktop_drive_client.dart
│   │       ├── desktop_oauth_config.dart
│   │       ├── drive_config.dart
│   │       ├── drive_crud_client.dart
│   │       ├── mobile_drive_service.dart
│   │       └── mobile_google_auth_service.dart
│   │
│   ├── pages/
│   │   ├── data_management_page.dart    # Import/Export UI (shared)
│   │   └── data_management_tab.dart
│   │
│   ├── utils/
│   │   ├── platform_helper.dart         # Platform detection
│   │   └── sync_utils.dart
│   │
│   ├── localizations.dart          # Base localization infrastructure
│   └── google_drive_client.dart    # Drive client (shared)
│
├── fourth_step/                    # 4TH STEP INVENTORY APP
│   ├── models/
│   │   ├── inventory_entry.dart         # Resentment/inventory data
│   │   ├── inventory_entry.g.dart
│   │   ├── i_am_definition.dart         # Identity definitions
│   │   └── i_am_definition.g.dart
│   │
│   ├── services/
│   │   ├── inventory_service.dart       # CRUD for inventory
│   │   ├── i_am_service.dart            # CRUD for I Am definitions
│   │   ├── inventory_drive_service.dart # Drive sync for 4th step
│   │   └── drive_service.dart           # Legacy drive service
│   │
│   ├── pages/
│   │   ├── fourth_step_home.dart        # Main container (was modular_inventory_home.dart)
│   │   ├── form_tab.dart                # Entry form
│   │   ├── list_tab.dart                # Inventory list
│   │   └── settings_tab.dart            # I Am definitions management
│   │
│   └── localizations/
│       └── fourth_step_localizations.dart  # 4th step specific strings
│
└── eighth_step/                    # 8TH STEP AMENDS APP
    ├── models/
    │   ├── person.dart                  # Person/amends data
    │   └── person.g.dart
    │
    ├── services/
    │   └── person_service.dart          # CRUD for people
    │
    ├── pages/
    │   ├── eighth_step_home.dart        # Main container with tabs
    │   ├── eighth_step_settings_tab.dart    # Person CRUD management
    │   └── eighth_step_view_person_tab.dart # Person detail view
    │
    └── localizations/
        └── eighth_step_localizations.dart   # 8th step specific strings
```

## Component Responsibilities

### Shared Components (`lib/shared/`)
**Purpose**: Common functionality used by multiple apps

- **Models**: App switching system
- **Services**: Authentication, Drive sync infrastructure, localization
- **Pages**: Data import/export UI
- **Utils**: Platform detection, sync utilities

### Fourth Step App (`lib/fourth_step/`)
**Purpose**: AA 4th Step Inventory - Resentments and character defects

- **Models**: `InventoryEntry`, `IAmDefinition`
- **Services**: Inventory CRUD, I Am management, Drive sync
- **Pages**: Form entry, list view, settings
- **Data**: Stored in `entries` and `i_am_definitions` Hive boxes

### Eighth Step App (`lib/eighth_step/`)
**Purpose**: AA 8th Step - List of persons to make amends to

- **Models**: `Person` with `ColumnType` enum
- **Services**: Person CRUD
- **Pages**: 3-column view, person details, settings
- **Data**: Stored in `people_box` Hive box

## Data Isolation

### Hive Type IDs
```dart
// Shared
AppEntry: typeId 2

// Fourth Step
InventoryEntry: typeId 0
IAmDefinition: typeId 1

// Eighth Step
Person: typeId 3
ColumnType: typeId 4
```

### Hive Boxes
```dart
// Fourth Step
Box<InventoryEntry> entries
Box<IAmDefinition> i_am_definitions

// Eighth Step
Box<Person> people_box

// Shared
Box settings  // App preferences, sync settings
```

## Localization Strategy

### Current Structure (Centralized)
All strings in `lib/shared/localizations.dart`

### Recommended Modular Structure

#### `lib/shared/localizations.dart`
```dart
// Common strings used across all apps
'cancel', 'delete', 'save', 'yes', 'no', etc.
```

#### `lib/fourth_step/localizations/fourth_step_localizations.dart`
```dart
// 4th step specific strings
'app_title', 'form_title', 'resentment', 'i_am', 'character_defects', etc.
```

#### `lib/eighth_step/localizations/eighth_step_localizations.dart`
```dart
// 8th step specific strings
'eighth_step_main', 'person_name', 'amends_needed', 'amends_done', etc.
```

## Import/Export Strategy

### Current Approach
- Centralized in `data_management_page.dart`
- Handles both apps

### Recommended Modular Approach

#### Shared Interface
```dart
// lib/shared/services/export_service.dart
abstract class ExportService {
  Future<Map<String, dynamic>> exportData();
  Future<void> importData(Map<String, dynamic> data);
}
```

#### App-Specific Implementations
```dart
// lib/fourth_step/services/fourth_step_export_service.dart
class FourthStepExportService implements ExportService {
  // Handles inventory + I Am definitions
}

// lib/eighth_step/services/eighth_step_export_service.dart
class EighthStepExportService implements ExportService {
  // Handles people data
}
```

## Google Drive Sync Strategy

### Current Approach
- `inventory_drive_service.dart` - 4th step sync
- Shared Drive infrastructure in `lib/services/google_drive/`

### Recommended Modular Approach

#### Shared Drive Infrastructure (`lib/shared/services/google_drive/`)
- Authentication (mobile/desktop)
- CRUD client
- Configuration

#### App-Specific Sync Services
```dart
// lib/fourth_step/services/fourth_step_drive_sync.dart
class FourthStepDriveSync extends BaseDriveSync {
  // Syncs inventory + I Am definitions
  // Uses shared Drive client
}

// lib/eighth_step/services/eighth_step_drive_sync.dart
class EighthStepDriveSync extends BaseDriveSync {
  // Syncs people data
  // Uses shared Drive client
}
```

## Benefits of Modular Architecture

1. **Clear Separation**: Easy to identify which code belongs to which app
2. **Independent Development**: Apps can evolve independently
3. **Reusable Components**: Shared code in one place
4. **Easier Testing**: Test apps in isolation
5. **Scalability**: Easy to add new apps (9th step, 10th step, etc.)
6. **Maintainability**: Changes to one app don't affect others
7. **Code Organization**: Logical grouping of related functionality

## Migration Notes

**Status**: Current structure is partially modular
- 8th step pages are in `lib/pages/eighth_step/`
- Models, services still mixed in `lib/models/` and `lib/services/`

**Recommended Next Steps**:
1. Move models to app-specific folders
2. Move services to app-specific folders
3. Split localizations into app-specific files
4. Refactor import/export to use app-specific services
5. Update all import statements

**Impact**: Requires updating ~50-100 import statements across the codebase
