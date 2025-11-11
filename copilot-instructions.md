## Repository: AA 4Step Inventory (Flutter)

Quick orientation (what matters to an AI assistant):

- This is a small Flutter app using Hive for local storage and Google Drive for optional sync.
- Key entry point: `lib/main.dart` — app initializes Hive, registers `InventoryEntryAdapter`, attempts silent Google Sign-In and sets the `DriveService` client.
- Local model: `lib/models/inventory_entry.dart` (HiveType, typeId: 0). Use the fields defined there when serializing/deserializing entries.
- Drive sync service: `lib/services/drive_service.dart`. All Drive interactions are mediated through `GoogleDriveClient` (see `lib/google_drive_client.dart`) and `DriveService.instance` is a singleton.

What an AI agent should do first when editing code:

- Preserve Hive adapter registrations in `main.dart` when touching models. Removing the `registerAdapter` call breaks runtime type mapping.
- If changing the schema of `InventoryEntry`, update `inventory_entry.g.dart` via `flutter pub run build_runner build --delete-conflicting-outputs` and keep `typeId` stable.
- Any code that mutates the `entries` Hive box should call `DriveService.instance.scheduleUploadFromBox(...)` or trigger `DriveService.uploadFile(...)` when sync is enabled. See `scheduleUploadFromBox`'s debouncing and use of `compute(serializeEntries, ...)` for background serialization.

Developer workflows / commands (Windows Powershell):

- Install/update packages: flutter pub get
- Generate Hive adapters / build files: flutter pub run build_runner build --delete-conflicting-outputs
- Run the app (debug): flutter run -d <device>
- Run flutter analyze: flutter analyze

Project-specific conventions & gotchas:

- Sync toggle is persisted in a Hive box named `settings` under key `syncEnabled`. Drive operations early-return if sync is disabled.
- The app attempts silent sign-in at startup; network-auth flows are triggered from the Settings UI. Don't assume a Drive client exists — guard with null-checks on `DriveService._client`.
- Drive uploads are debounced (700ms) in `DriveService` to coalesce frequent edits. Prefer calling `scheduleUploadFromBox` after batch mutations instead of calling upload directly.
- The code serializes entries using a custom serializer helper (`serializeEntries`) called via `compute` for background work — keep heavy CPU tasks off the main isolate.

Integration points to inspect when making changes:

- `lib/google_drive_client.dart` — adapter between GoogleAuth tokens and Drive REST operations.
- `lib/services/drive_service.dart` — central sync logic; tests or fixes for sync behavior belong here.
- `lib/utils/sync_utils.dart` — helper serialization logic used by `DriveService`.

Examples to copy/use:

- Debounced upload call (from UI or model layer):
  final box = Hive.box<InventoryEntry>('entries');
  DriveService.instance.scheduleUploadFromBox(box);

- Guarding Drive calls:
  if (!DriveService.instance.syncEnabled || DriveService.instance == null) return; // prefer null-safe checks

When editing: run these checks before committing

- flutter analyze → ensure no analyzer errors.
- flutter pub run build_runner build --delete-conflicting-outputs if you changed `@HiveType` models.

If you need more context, open these files: `lib/main.dart`, `lib/services/drive_service.dart`, `lib/models/inventory_entry.dart`, `lib/google_drive_client.dart`, `lib/utils/sync_utils.dart`.

If anything in this file is unclear or you want extra examples (tests, PR checklist), tell me which section to expand.
