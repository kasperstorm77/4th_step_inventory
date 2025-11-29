# Modular Architecture - Twelve Step App

## Overview
This document describes the modular architecture supporting five recovery apps (4th Step Inventory, 8th Step Amends, Evening Ritual, Gratitude, Agnosticism) with shared common components.

## Directory Structure

```
lib/
├── main.dart                        # App entry point
├── app/                            # App-level configuration (Flutter Modular)
│   ├── app_module.dart             # Dependency injection
│   └── app_widget.dart             # Root widget
│
├── shared/                         # SHARED COMPONENTS (Common to all apps)
│   ├── models/
│   │   ├── app_entry.dart          # Multi-app system definition (5 apps)
│   │   └── app_entry.g.dart
│   │
│   ├── services/
│   │   ├── all_apps_drive_service.dart  # Syncs ALL 5 apps to Drive
│   │   ├── legacy_drive_service.dart    # Backward compatibility wrapper
│   │   ├── app_switcher_service.dart    # App switching logic
│   │   ├── app_help_service.dart        # Context-sensitive help
│   │   ├── locale_provider.dart         # Language management
│   │   ├── app_version_service.dart     # Version tracking
│   │   └── google_drive/                # Drive sync infrastructure
│   │       ├── desktop_drive_auth.dart
│   │       ├── desktop_drive_client.dart
│   │       ├── desktop_oauth_config.dart
│   │       ├── drive_config.dart
│   │       ├── drive_crud_client.dart
│   │       ├── enhanced_google_drive_service.dart
│   │       ├── mobile_drive_service.dart
│   │       └── mobile_google_auth_service.dart
│   │
│   ├── pages/
│   │   ├── app_router.dart              # Global routing (switches between apps)
│   │   ├── data_management_page.dart    # Import/Export UI (shared)
│   │   └── data_management_tab.dart
│   │
│   ├── utils/
│   │   ├── platform_helper.dart         # Platform detection
│   │   └── sync_utils.dart
│   │
│   ├── localizations.dart               # All localization strings (EN/DA)
│   └── google_drive_client.dart         # Legacy Drive client
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
│   │   └── i_am_service.dart            # CRUD for I Am definitions
│   │
│   └── pages/
│       ├── fourth_step_home.dart        # Main container (ModularInventoryHome)
│       ├── form_tab.dart                # Entry form
│       ├── list_tab.dart                # Inventory list
│       └── settings_tab.dart            # I Am definitions management
│
├── eighth_step/                    # 8TH STEP AMENDS APP
│   ├── models/
│   │   ├── person.dart                  # Person/amends data
│   │   └── person.g.dart
│   │
│   ├── services/
│   │   └── person_service.dart          # CRUD for people
│   │
│   └── pages/
│       ├── eighth_step_home.dart        # Main container with tabs
│       ├── eighth_step_settings_tab.dart    # Person CRUD management
│       └── eighth_step_view_person_tab.dart # Person detail view
│
├── evening_ritual/                 # EVENING RITUAL APP
│   ├── models/
│   │   ├── reflection_entry.dart        # Daily reflection data
│   │   └── reflection_entry.g.dart
│   │
│   ├── services/
│   │   └── reflection_service.dart      # CRUD for reflections
│   │
│   └── pages/
│       ├── evening_ritual_home.dart     # Main container
│       ├── evening_ritual_form_tab.dart # Reflection form
│       └── evening_ritual_list_tab.dart # Reflections list
│
├── gratitude/                      # GRATITUDE APP
│   ├── models/
│   │   ├── gratitude_entry.dart         # Gratitude data
│   │   └── gratitude_entry.g.dart
│   │
│   ├── services/
│   │   └── gratitude_service.dart       # CRUD for gratitude
│   │
│   └── pages/
│       ├── gratitude_home.dart          # Main container
│       ├── gratitude_form_tab.dart      # Gratitude form
│       └── gratitude_list_tab.dart      # Gratitude list
│
└── agnosticism/                    # AGNOSTICISM APP
    ├── models/
    │   ├── agnosticism_paper.dart       # Barriers/conception paper
    │   └── agnosticism_paper.g.dart
    │
    ├── services/
    │   └── agnosticism_service.dart     # CRUD for papers
    │
    └── pages/
        ├── agnosticism_home.dart        # Main container
        ├── current_paper_tab.dart       # Current paper editor
        ├── archive_tab.dart             # Archived papers
        └── paper_detail_page.dart       # Paper details
```

## Component Responsibilities

### Shared Components (`lib/shared/`)
**Purpose**: Common functionality used by all apps

- **Models**: App switching system (5 apps)
- **Services**: 
  - `AllAppsDriveService`: Syncs all 5 apps to single Drive JSON
  - `AppSwitcherService`: App selection persistence
  - `AppHelpService`: Context-sensitive help for each app
  - `LocaleProvider`: EN/DA language switching
  - Authentication & Drive infrastructure
- **Pages**: 
  - `AppRouter`: Global routing (switches between apps)
  - Data import/export UI (JSON v6.0 format)
- **Utils**: Platform detection, sync utilities
- **Localizations**: All UI strings for all apps (EN/DA)

### App-Specific Components
Each app has its own isolated folder with:
- **Models**: Hive-annotated data classes with unique typeIds
- **Services**: CRUD operations, calls `AllAppsDriveService` for sync
- **Pages**: UI screens (home, tabs, forms, lists)

### Fourth Step App (`lib/fourth_step/`)
**Purpose**: AA 4th Step Inventory - Resentments and character defects

- **Models**: `InventoryEntry` (typeId: 0), `IAmDefinition` (typeId: 1)
- **Services**: `InventoryService`, `IAmService`
- **Pages**: Form entry, list view, I Am settings
- **Data**: Hive boxes `entries`, `i_am_definitions`

### Eighth Step App (`lib/eighth_step/`)
**Purpose**: AA 8th Step - List of persons to make amends to

- **Models**: `Person` (typeId: 3), `ColumnType` enum (typeId: 4)
- **Services**: `PersonService`
- **Pages**: 3-column Kanban view, person details, settings
- **Data**: Hive box `people_box`

### Evening Ritual App (`lib/evening_ritual/`)
**Purpose**: Daily evening reflection and 10th step inventory

- **Models**: `ReflectionEntry` (typeId: 5), `ReflectionType` enum (typeId: 6)
- **Services**: `ReflectionService`
- **Pages**: Form entry, list view
- **Data**: Hive box `reflections_box`

### Gratitude App (`lib/gratitude/`)
**Purpose**: Daily gratitude journal

- **Models**: `GratitudeEntry` (typeId: 7)
- **Services**: `GratitudeService`
- **Pages**: Form entry, list view
- **Data**: Hive box `gratitude_box`

### Agnosticism App (`lib/agnosticism/`)
**Purpose**: Barriers and new conception exercise (Step 2)

- **Models**: `AgnosticismPaper` (typeId: 8), `PaperStatus` enum (typeId: 9)
- **Services**: `AgnosticismService`
- **Pages**: Current paper editor, archive, detail view
- **Data**: Hive box `agnosticism_box`

## Data Isolation

### Hive Type IDs (NEVER reuse!)
```dart
// Shared
AppEntry: typeId 2

// Fourth Step
InventoryEntry: typeId 0
IAmDefinition: typeId 1

// Eighth Step
Person: typeId 3
ColumnType: typeId 4

// Evening Ritual
ReflectionEntry: typeId 5
ReflectionType: typeId 6

// Gratitude
GratitudeEntry: typeId 7

// Agnosticism
AgnosticismPaper: typeId 8
PaperStatus: typeId 9
```

### Hive Boxes
```dart
// App-specific boxes
Box<InventoryEntry> entries           // 4th step
Box<IAmDefinition> i_am_definitions   // 4th step
Box<Person> people_box                // 8th step
Box<ReflectionEntry> reflections_box  // Evening ritual
Box<GratitudeEntry> gratitude_box     // Gratitude
Box<AgnosticismPaper> agnosticism_box // Agnosticism

// Shared box
Box settings  // App preferences, sync settings, selected app
```

## Localization Strategy

### Current Structure (Centralized)
All strings for all 5 apps in `lib/shared/localizations.dart`

**Languages**: English (EN) and Danish (DA)

**Access Function**: `t(context, 'key')` - Returns translated string for current locale

**Locale Management**: `LocaleProvider` (ChangeNotifier) injected via Flutter Modular

**Language Selector**: PopupMenuButton in each app's AppBar

### Key Prefixes by App
- `fourth_step_*` - 4th Step Inventory strings
- `eighth_step_*` - 8th Step Amends strings
- `evening_ritual_*` - Evening Ritual strings
- `gratitude_*` - Gratitude app strings
- `agnosticism_*` - Agnosticism app strings
- Common strings: `cancel`, `delete`, `save`, `yes`, `no`, etc.

## App Switching Architecture

### How It Works

**`AppSwitcherService`** (`lib/shared/services/app_switcher_service.dart`)
- Stores selected app ID in Hive `settings` box
- Static methods for getting/setting current app
- Persists selection across app restarts

**`AppRouter`** (`lib/shared/pages/app_router.dart`)
- Global routing widget at the root level
- Switches between app home pages based on selected ID
- Uses `ValueKey` to force rebuild when app changes
- Passes `onAppSwitched` callback to child apps

**App Home Pages**
- Each app's home page has a grid icon button in AppBar
- Shows dialog with all 5 apps listed
- Highlights currently selected app
- Calls `AppSwitcherService.setSelectedAppId()` on selection
- Triggers `onAppSwitched()` callback to rebuild `AppRouter`

### Flow
```
User clicks grid icon → Dialog shows 5 apps → User selects app
→ AppSwitcherService.setSelectedAppId() → onAppSwitched() callback
→ AppRouter rebuilds → New app page renders
```

### Adding New Apps
1. Add app ID constant to `AvailableApps` in `app_entry.dart`
2. Add `AppEntry` to `AvailableApps.getAll()` list
3. Add case to `AppRouter.build()` switch statement
4. Create app folder with models, services, pages
5. Register new Hive type IDs (must be unique)
6. Update `AllAppsDriveService` to sync new app data

## Google Drive Sync Strategy

### Current Architecture (Centralized - All Apps)

**`AllAppsDriveService`** (`lib/shared/services/all_apps_drive_service.dart`)
- Syncs **all 5 apps** to a single Google Drive JSON file
- JSON format version 6.0
- Uses `MobileDriveService` with mobile OAuth
- Debounced uploads (700ms) to coalesce rapid changes
- Conflict detection via `lastModified` timestamps
- Auto-syncs on app start if remote data is newer

**JSON Structure:**
```json
{
  "version": "6.0",
  "exportDate": "2025-11-22T...",
  "lastModified": "2025-11-22T...",
  "entries": [...],            // 4th step inventory
  "iAmDefinitions": [...],     // 4th step I Am
  "people": [...],             // 8th step
  "reflections": [...],        // Evening ritual
  "gratitudeEntries": [...],   // Gratitude
  "agnosticismPapers": [...]   // Agnosticism
}
```

**Legacy Wrapper:**
`LegacyDriveService` (`lib/shared/services/legacy_drive_service.dart`) provides backward compatibility for old code

**App-Specific Services:**
Each app's CRUD service calls `AllAppsDriveService.instance.scheduleUploadFromBox()` after data changes

**Shared Drive Infrastructure** (`lib/shared/services/google_drive/`):
- **Mobile**: `MobileGoogleAuthService` + `MobileDriveService` (Android/iOS)
- **Web**: Same services with web-specific OAuth2 implementation via `google_sign_in` package
- **Desktop**: `DesktopDriveAuth` + `DesktopDriveClient` (Windows/macOS/Linux)
- **CRUD**: `DriveCrudClient` (pure Drive API operations)
- **Enhanced**: `EnhancedGoogleDriveService` (debouncing, events)

**Platform-Specific Implementations:**
- Conditional exports (`if (dart.library.html)`) route to platform-specific code
- Web uses OAuth2 flow in browser with client ID in `web/index.html`
- Mobile uses `google_sign_in` with platform-specific OAuth clients
- Desktop uses out-of-band OAuth flow with manual auth code entry

## Benefits of Modular Architecture

1. **Clear Separation**: Easy to identify which code belongs to which app
2. **Independent Development**: Apps can evolve independently while sharing infrastructure
3. **Reusable Components**: Shared Drive sync, localization, auth in one place
4. **Easy Testing**: Test apps in isolation
5. **Scalability**: Easy to add new apps (just 6 steps - see App Switching section)
6. **Maintainability**: Changes to one app don't affect others
7. **Code Organization**: Logical grouping by functionality
8. **Single Source of Truth**: One Drive file syncs all apps, no conflicts

## Current Status

✅ **Fully Modular** - 5 apps with clear separation:
- Fourth Step Inventory
- Eighth Step Amends  
- Evening Ritual
- Gratitude
- Agnosticism

✅ **Centralized Infrastructure**:
- Single `AllAppsDriveService` syncs all apps
- Shared `AppRouter` for global routing
- Unified localization in `shared/localizations.dart`
- Common UI patterns (app switcher, help icons, language selector)

✅ **Data Safety**:
- Unique Hive type IDs (0-9 assigned)
- Separate Hive boxes per app
- JSON v6.0 format with backward compatibility
- Conflict detection via timestamps

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│           main.dart                     │
│  (Hive init, silent sign-in)            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         AppWidget                       │
│  (Material app, locale management)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         AppModule                       │
│  (Flutter Modular DI, routes)           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          AppRouter                      │
│  (Switches between apps)                │
└───┬────┬────┬────┬────┬─────────────────┘
    │    │    │    │    │
    ▼    ▼    ▼    ▼    ▼
   4th  8th  Eve  Gra  Agn
  Step Step Rit  tit  ost
  Home Home Home Home Home
    │    │    │    │    │
    └────┴────┴────┴────┘
              │
    ┌─────────▼────────────┐
    │ AllAppsDriveService  │
    │  (Single JSON sync)  │
    └──────────────────────┘
```
