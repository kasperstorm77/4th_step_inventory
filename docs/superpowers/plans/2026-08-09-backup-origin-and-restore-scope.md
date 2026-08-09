# Backup Origin and Restore Scope Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tag new Twelve Steps backups with `product: twelve-steps`, preserve provable legacy-native restores, restrict Emotional Sobriety imports to five shared datasets, and schedule a canonical Twelve Steps backup after compatibility import.

**Architecture:** `BackupRestoreService` classifies origin before validation or mutation, combines it with an explicit `RestoreIntent`, and selects native-full or shared-compatibility scope. A committed compatibility import invokes one required scheduler callback, which rebuilds from Hive through the existing backup pipeline. Emotional Sobriety receives a separate pre-release implementation task requiring the exact marker and no product-less exception.

**Tech Stack:** Flutter, Dart, Hive, `flutter_test`, existing sync/backup services, Markdown canonical documentation.

**Execution status (2026-08-09):** Twelve Steps implementation, documentation,
clean analysis, and all 158 local tests complete. The mandatory cross-app gate
passes this application's direction and then fails at Emotional Sobriety's
current validator with `Unsupported backup product or version`; prerelease peer
task P5.18 is the remaining release blocker.

## Global Constraints

- Keep schema version `8.0`; add only the stable product marker to the envelope.
- Preserve product-less historical Twelve Steps restores only with a Twelve Steps-only fingerprint.
- Reject missing-product shared-only JSON as ambiguous.
- Accept `emotional-sobriety`/`1.0` only through manual JSON compatibility import.
- Replace only `iAmDefinitions`, `entries`, `agnosticism`, `morningRitualItems`, and `morningRitualEntries` across apps.
- Preserve `people`, `reflections`, `gratitude`, `notifications`, and `appSettings` across compatibility import.
- Reject unsupported origin before safety backup creation or Hive mutation.
- Rebuild post-import backup from Hive through `AllAppsDriveService.scheduleUploadFromBox()`.
- Do not add product-less compatibility to Emotional Sobriety; it is pre-release.
- Do not change Hive IDs, fields, enums, box names, Drive scope, dependencies, or app version.
- Do not commit, push, build, or publish without a separate explicit request.
- Never inspect or modify `NEVER_READ_THIS_FILE.md`.

## File map

| File | Responsibility |
| --- | --- |
| `lib/shared/services/sync_payload_builder.dart` | Write the stable product identifier. |
| `lib/shared/services/backup_restore_service.dart` | Classify origin, enforce intent/scope, validate foreign input, translate the whitelist, and schedule after commit. |
| `lib/shared/pages/data_management_tab_mobile.dart` | Pass manual intent and scheduler on mobile. |
| `lib/shared/pages/data_management_tab_windows.dart` | Pass manual intent and scheduler on desktop. |
| `test/backup_round_trip_test.dart` | Pin labeled native and product-less legacy restores. |
| `test/emotional_sobriety_import_test.dart` | Pin origin rejection, scope isolation, and scheduling. |
| `test/cross_app_export_fixture_test.dart` | Pin the labeled live export. |
| `test/morning_ritual_randomizer_portability_test.dart` | Keep a partial legacy fixture authenticated. |
| `lib/shared/CLAUDE.md`, `docs/*.md` | Own current rules, architecture, plan blocker, and completed history. |
| `../emotional_sobriety/docs/implementation_plan.md` | Own the strict peer task. |

---

### Task 1: Product marker and origin classifier

**Files:**
- Modify: `lib/shared/services/sync_payload_builder.dart`
- Modify: `lib/shared/services/backup_restore_service.dart`
- Test: `test/backup_round_trip_test.dart`
- Test: `test/emotional_sobriety_import_test.dart`
- Test: `test/cross_app_export_fixture_test.dart`

**Interfaces:**
- Produces: `SyncPayloadBuilder.productId == 'twelve-steps'`.
- Produces: `BackupOrigin` with `twelveSteps`, `legacyTwelveSteps`, `emotionalSobriety`, and `unsupported`.
- Produces: `BackupRestoreService.originOf(Map<String, dynamic>)`.

- [ ] **Step 1: Write failing marker tests**

Replace every old no-product assertion with:

```dart
expect(payload['product'], 'twelve-steps');
expect(payload['version'], '8.0');
```

- [ ] **Step 2: Write failing classifier tests**

Add cases for exact `twelve-steps`/`8.0`, product-less `gratitudeEntries`, exact `emotional-sobriety`/`1.0`, product-less shared-only data, blank/numeric/unknown products, and mismatched versions. Require only the first three valid shapes to classify as supported origins.

- [ ] **Step 3: Run the red tests**

```bash
flutter test test/backup_round_trip_test.dart test/emotional_sobriety_import_test.dart test/cross_app_export_fixture_test.dart
```

Expected: FAIL because `productId`, `BackupOrigin`, and `originOf` do not exist.

- [ ] **Step 4: Implement the marker**

Add `static const String productId = 'twelve-steps';` to `SyncPayloadBuilder` and write `'product': productId` before `version` in every built payload.

- [ ] **Step 5: Implement exact classification**

Add:

```dart
enum BackupOrigin {
  twelveSteps,
  legacyTwelveSteps,
  emotionalSobriety,
  unsupported,
}
```

Classify current native only for `twelve-steps`/`8.0`; foreign only for `emotional-sobriety`/`1.0`; legacy native only when `product` is absent and at least one of `people`, `reflections`, `gratitude`, `gratitudeEntries`, `notifications`, or `appSettings` is present. Treat all other shapes as unsupported. Replace `foreignProductOf` use in `isSupportedForeignPayload` and `describeForeignPayload` with `originOf`.

- [ ] **Step 6: Run and review Task 1**

```bash
flutter test test/backup_round_trip_test.dart test/emotional_sobriety_import_test.dart test/cross_app_export_fixture_test.dart
```

```bash
git diff --check
```

Expected: marker/classifier assertions pass; restore API failures may remain until Task 2.

---

### Task 2: Explicit restore intent and strict scope gate

**Files:**
- Modify: `lib/shared/services/backup_restore_service.dart`
- Modify: `test/backup_round_trip_test.dart`
- Modify: `test/emotional_sobriety_import_test.dart`
- Modify: `test/morning_ritual_randomizer_portability_test.dart`

**Interfaces:**
- Consumes: `BackupOrigin` and `originOf` from Task 1.
- Produces: `enum RestoreIntent { nativeRestore, manualJsonImport }`.
- Produces: optional named `scheduleCanonicalBackup` callback that is required for compatibility scope.

- [ ] **Step 1: Write failing native/legacy tests**

Require a labeled builder payload to full-restore with default intent. Keep the legacy alias test product-less and change its version to `7.0`, proving version remains informational. Add a product-less shared-only rejection test that seeds native data and proves it remains unchanged.

- [ ] **Step 2: Write failing foreign-scope tests**

Replace `allowForeignProduct: true` in tests with:

```dart
intent: RestoreIntent.manualJsonImport,
scheduleCanonicalBackup: () {},
```

Add cases requiring all five foreign sections to be lists. For each missing or malformed shared section, seed native data and prove failure leaves it unchanged. Add native-intent, wrong-version, blank-product, numeric-product, and unknown-product rejection cases.

- [ ] **Step 3: Run the red tests**

```bash
flutter test test/backup_round_trip_test.dart test/emotional_sobriety_import_test.dart test/morning_ritual_randomizer_portability_test.dart
```

Expected: FAIL because `RestoreIntent` and strict scope validation do not exist.

- [ ] **Step 4: Implement intent and scope selection**

Add `RestoreIntent`, remove `allowForeignProduct`, and add these named parameters to both restore entry points:

```dart
RestoreIntent intent = RestoreIntent.nativeRestore,
void Function()? scheduleCanonicalBackup,
```

Allow current/legacy Twelve Steps to proceed to native validation. Allow Emotional Sobriety only with manual intent and a non-null scheduler callback. Reject unsupported origins immediately. Preserve a local `isCompatibilityImport` Boolean for the post-commit step.

- [ ] **Step 5: Implement exact foreign validation**

Add `validateEmotionalSobrietyPayload(Map<String, dynamic>)`. Require exact origin plus list values for `iAmDefinitions`, `entries`, `agnosticismPairs`, `morningRitualItems`, and `morningRitualEntries`. Make `describeForeignPayload` return null unless this validation succeeds. Translate only those five lists and `lastModified`; never copy a product marker or foreign-only section into `_applyPayload`.

- [ ] **Step 6: Authenticate the partial legacy Morning fixture**

Add `'people': <dynamic>[]` to the product-less partial payload in `morning_ritual_randomizer_portability_test.dart`. Do not add a product marker; this fixture must exercise the legacy-native classifier.

- [ ] **Step 7: Run and review Task 2**

```bash
flutter test test/backup_round_trip_test.dart test/emotional_sobriety_import_test.dart test/morning_ritual_randomizer_portability_test.dart
```

```bash
rg -n "allowForeignProduct|foreignProductOf" lib test --glob '!NEVER_READ_THIS_FILE.md'
```

Expected: tests pass and the two unsafe symbols have no matches.

---

### Task 3: Canonical backup scheduling and UI wiring

**Files:**
- Modify: `lib/shared/services/backup_restore_service.dart`
- Modify: `lib/shared/pages/data_management_tab_mobile.dart`
- Modify: `lib/shared/pages/data_management_tab_windows.dart`
- Modify: `test/emotional_sobriety_import_test.dart`
- Modify: `test/morning_ritual_editor_and_import_dialog_test.dart`

**Interfaces:**
- Consumes: Task 2's manual intent and scheduler callback.
- Consumes: `AllAppsDriveService.instance.scheduleUploadFromBox()`.
- Produces: exactly one canonical backup schedule after a committed compatibility import.

- [ ] **Step 1: Write the failing exactly-once test**

Import the captured Emotional fixture with a counter callback. Require count `1` on success and `0` on validation failure, native restore, or rejected native intent. Seed gratitude before foreign import, rebuild with `SyncPayloadBuilder`, and require labeled output containing both imported entries and retained gratitude.

- [ ] **Step 2: Run the red scheduler test**

```bash
flutter test test/emotional_sobriety_import_test.dart
```

Expected: FAIL because the service does not invoke the callback.

- [ ] **Step 3: Schedule after commit only**

After successful apply, timestamp update, and refresh notification, call `scheduleCanonicalBackup!()` only when `isCompatibilityImport`. Catch scheduler failure as a post-commit sync warning so already-persisted data is not reported as a failed restore.

- [ ] **Step 4: Wire mobile and desktop manual imports**

Use `originOf` for unsupported/foreign confirmation. Pass:

```dart
intent: RestoreIntent.manualJsonImport,
scheduleCanonicalBackup:
    AllAppsDriveService.instance.scheduleUploadFromBox,
```

Keep Drive/local restore on default native intent. Remove the mobile post-success `_uploadToDrive()` special case so the service callback is the only compatibility schedule.

- [ ] **Step 5: Update UI contract coverage**

Keep the dialog copy test using a valid `ForeignImportSummary`. Add source-level assertions that both platform manual JSON paths pass manual intent and the scheduler, while their Drive/local paths do not.

- [ ] **Step 6: Run and review Task 3**

```bash
flutter test test/emotional_sobriety_import_test.dart test/morning_ritual_editor_and_import_dialog_test.dart
```

```bash
git diff --check
```

Expected: all tests pass; one schedule occurs only after compatibility commit.

---

### Task 4: Update Twelve Steps canonical documentation

**Files:**
- Modify: `lib/shared/CLAUDE.md`
- Modify: `docs/architecture.md`
- Modify: `docs/implementation_plan.md`
- Modify: `docs/historic_implementation.md`

- [ ] **Step 1: Update shared agent rules**

Replace “never writes a product key” with exact `twelve-steps`/`8.0`, legacy fingerprint, manual-only `emotional-sobriety`/`1.0`, five-section scope, and post-commit canonical backup rules.

- [ ] **Step 2: Update architecture**

Add `"product": "twelve-steps"` to §3.1. Replace §3.6.1's missing-marker inference with the origin/scope table, rejection order, legacy exception, five-section map, and rebuild-from-Hive post-import flow.

- [ ] **Step 3: Update implementation plan**

Update P2.2 with the labeled wire contract. Add one unchecked release blocker requiring the Emotional Sobriety strict peer task before the mandatory cross-app gate can pass. Add no bypass.

- [ ] **Step 4: Append completed history**

Record the missing-marker-as-native root cause, marker, legacy fingerprint, shared-only transaction, retained native data, scheduler behavior, verification evidence, and outstanding peer gate. Do not claim cross-app verification passed.

- [ ] **Step 5: Check documentation**

```bash
rg -n "never writes a `product`|never tags a product|writing a product tag would make" CLAUDE.md lib docs test --glob '!NEVER_READ_THIS_FILE.md'
```

```bash
git diff --check
```

Expected: no stale product-less-native claims or Markdown whitespace errors.

---

### Task 5: Register Emotional Sobriety's strict peer task

**Files:**
- Modify: `../emotional_sobriety/docs/implementation_plan.md`

- [ ] **Step 1: Re-check peer instructions and state**

Run `git -C ../emotional_sobriety status --short --branch`. Re-read its root/docs agent instructions and current P5 task sequence. Preserve unrelated changes.

- [ ] **Step 2: Add the next P5 task**

Use Outcome/Driver/Work rules/Acceptance/Validation/Document impact. Require exact `product == twelve-steps` and `version == 8.0`; shared transaction only; product-less rejection with no legacy inference because Emotional Sobriety is pre-release; rejection before safety backup/mutation; native Emotional/Drive restriction to `emotional-sobriety`; live fixture, validator, docs, and both-direction gate updates.

- [ ] **Step 3: Pin acceptance**

Require labeled live export success, product-less/wrong-label failure without mutation or safety backup, retention of Workshop/draft/settings/auth/sync state, rejection on complete/Drive paths, and passing cross-app gates in both repositories.

- [ ] **Step 4: Verify only the peer plan diff**

```bash
git -C ../emotional_sobriety diff --check -- docs/implementation_plan.md
```

Expected: one plan task only; no peer code, test, version, release, or unrelated changes.

---

### Task 6: Format and verify

**Files:**
- Format: all Dart files changed in Tasks 1–3
- Verify: all intended Twelve Steps changes and the single peer plan change

- [ ] **Step 1: Format changed Dart files**

Run `dart format` with the exact changed Dart/test paths from Tasks 1–3.

- [ ] **Step 2: Run focused suites**

```bash
flutter test test/backup_round_trip_test.dart test/emotional_sobriety_import_test.dart test/cross_app_export_fixture_test.dart test/morning_ritual_randomizer_portability_test.dart test/morning_ritual_editor_and_import_dialog_test.dart
```

- [ ] **Step 3: Run full static and test gates**

```bash
flutter analyze
```

```bash
flutter test
```

Expected: no analysis issues and all Twelve Steps tests pass.

- [ ] **Step 4: Run the cross-app gate honestly**

```bash
bash scripts/verify-cross-app-recovery.sh
```

Expected before the peer task lands: FAIL specifically because Emotional Sobriety still expects product-less Twelve Steps `8.0`. Confirm the registered peer gap is the only cause. Never bypass or report this gate as passing.

- [ ] **Step 5: Run final status checks**

```bash
git diff --check
```

```bash
git status --short --branch
```

```bash
git -C ../emotional_sobriety status --short --branch
```

Expected: only intended implementation/docs, `AGENTS.md`, approved spec/plan, and the peer plan task are dirty. If `NEVER_READ_THIS_FILE.md` appears, report only its filename/status.

- [ ] **Step 6: Handoff**

Report implemented behavior, exact verification, the peer release blocker, and that no commit, push, version bump, build, or release occurred.
