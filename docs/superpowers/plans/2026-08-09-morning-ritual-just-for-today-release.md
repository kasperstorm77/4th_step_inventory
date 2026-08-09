# Morning Ritual Just for Today Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Just for Today a first-class Morning Ritual item choice, preserve the shared Emotional Sobriety backup contract, publish `2.3.6+114` to Play closed alpha, and upload the matching App Store IPA to TestFlight.

**Architecture:** Add a presentation-only three-value kind that maps Just for Today to the frozen persisted prayer ordinal plus `randomizerSourceId: just_for_today`. Keep the existing catalog, daily draw, draft, history, JSON schema, and Hive adapters unchanged. Release both platforms from the same pushed `main` commit and the same bilingual top block in `release.md`.

**Tech Stack:** Flutter/Dart, Hive, Flutter widget tests, Bash release scripts, Google Play Android Publisher API, Xcode/altool, App Store Connect API.

## Global constraints

- Keep `RitualItemType` frozen at `timer=0, prayer=1`.
- Keep Hive type IDs, `HiveField` indices, schema `8.0`, JSON keys, source ID `just_for_today`, and the ten generated option IDs unchanged.
- Use the exact label `Just for Today` in both `en` and `da` UI.
- Keep at most one randomized Morning Ritual definition and contiguous definition sort orders.
- Do not read, stage, modify, or commit `NEVER_READ_THIS_FILE.md`.
- Run `dart run build_runner build --delete-conflicting-outputs` after editing `ritual_item.dart`; require no generated adapter change.
- Run the bidirectional `bash scripts/verify-cross-app-recovery.sh` gate before either store upload.
- Publish Android only to hard-pinned closed track `alpha`.
- Push the verified release commit to `main` before building or uploading store artifacts.
- Use `2.3.6+114` for both stores and the top `release.md` block for `en-GB` and `da-DK` notes.

---

### Task 1: Add failing model and editor regression tests

**Files:**
- Modify: `test/morning_ritual_randomizer_portability_test.dart`
- Modify: `test/morning_ritual_editor_and_import_dialog_test.dart`

**Interfaces:**
- Consumes: `RitualItem.copyWith`, `MorningRitualSettingsTabState.showAddItemDialog`, existing localization harness and Hive test boxes.
- Produces: failing coverage for `clearPrayerText` and a first-class Just for Today dropdown choice.

- [x] **Step 1: Add the failing copyWith test**

Add this test to `morning_ritual_randomizer_portability_test.dart`:

```dart
test('copyWith clears fixed prayer text for a randomized definition', () {
  final item = RitualItem(
    id: 'reading',
    name: 'Reading',
    type: RitualItemType.prayer,
    prayerText: 'Old fixed text',
  );

  final randomized = item.copyWith(
    clearPrayerText: true,
    randomizerSourceId:
        MorningRandomizerContract.justForTodaySourceId,
  );

  expect(randomized.prayerText, isNull);
  expect(
    randomized.randomizerSourceId,
    MorningRandomizerContract.justForTodaySourceId,
  );
});
```

- [x] **Step 2: Add an add-dialog helper and failing dropdown test**

Add a helper using a `GlobalKey<MorningRitualSettingsTabState>`:

```dart
Future<void> openAddEditor(
  WidgetTester tester, {
  String locale = 'en',
}) async {
  final key = GlobalKey<MorningRitualSettingsTabState>();
  await tester.pumpWidget(
    harness(MorningRitualSettingsTab(key: key), locale),
  );
  await tester.pumpAndSettle();
  key.currentState!.showAddItemDialog();
  await tester.pumpAndSettle();
}
```

Add a widget test that opens the type dropdown, selects `Just for Today`, and asserts:

```dart
expect(find.text('Just for Today'), findsOneWidget);
await tester.tap(find.byType(DropdownButtonFormField).first);
await tester.pumpAndSettle();
expect(find.text('Timer'), findsWidgets);
expect(find.text('Prayer'), findsOneWidget);
expect(find.text('Just for Today'), findsOneWidget);
await tester.tap(find.text('Just for Today').last);
await tester.pumpAndSettle();
final nameField = tester.widget<TextField>(find.byType(TextField).first);
expect(nameField.controller!.text, 'Just for Today');
expect(find.text('Prayer Text'), findsNothing);
await act(tester, () => tester.tap(find.text('Add')));
final saved = items().values.single;
expect(saved.type, RitualItemType.prayer);
expect(saved.prayerText, isNull);
expect(
  saved.randomizerSourceId,
  MorningRandomizerContract.justForTodaySourceId,
);
```

Add a Danish rendering case that opens the dropdown and asserts `Timer`, `Bøn`, and the exact English label `Just for Today`.

- [x] **Step 3: Run the focused tests and verify RED**

Run:

```bash
flutter test test/morning_ritual_randomizer_portability_test.dart test/morning_ritual_editor_and_import_dialog_test.dart
```

Expected: compilation fails because `clearPrayerText` and the three-value dropdown behavior do not exist.

---

### Task 2: Implement the presentation-only kind and editor behavior

**Files:**
- Create: `lib/morning_ritual/pages/morning_ritual_definition_kind.dart`
- Modify: `lib/morning_ritual/models/ritual_item.dart`
- Modify: `lib/morning_ritual/pages/morning_ritual_settings_tab.dart`

**Interfaces:**
- Consumes: `RitualItemType`, `MorningRandomizerContract.justForTodaySourceId`, existing editor localization keys.
- Produces: `MorningRitualDefinitionKind.fromItem`, `persistedType`, `randomizerSourceId`, and `RitualItem.copyWith(clearPrayerText:)`.

- [x] **Step 1: Add the presentation-only kind**

Create:

```dart
import '../models/ritual_item.dart';
import '../services/morning_randomizer_source.dart';

enum MorningRitualDefinitionKind {
  timer,
  prayer,
  justForToday;

  static MorningRitualDefinitionKind fromItem(RitualItem item) {
    if (item.randomizerSourceId ==
        MorningRandomizerContract.justForTodaySourceId) {
      return MorningRitualDefinitionKind.justForToday;
    }
    return item.type == RitualItemType.timer
        ? MorningRitualDefinitionKind.timer
        : MorningRitualDefinitionKind.prayer;
  }

  RitualItemType get persistedType =>
      this == timer ? RitualItemType.timer : RitualItemType.prayer;

  String? get randomizerSourceId => this == justForToday
      ? MorningRandomizerContract.justForTodaySourceId
      : null;
}
```

- [x] **Step 2: Let copyWith explicitly clear fixed prayer text**

Add `bool clearPrayerText = false` and resolve the field with:

```dart
prayerText: clearPrayerText ? null : prayerText ?? this.prayerText,
```

Do not change annotations, constructors, JSON, or generated adapter fields.

- [x] **Step 3: Replace the hidden switch with the three-choice dropdown**

Use `MorningRitualDefinitionKind.fromItem(item)` for edits and `timer` for adds. Build dropdown entries for Timer, Prayer, and Just for Today; use the existing timer/book icons and localization keys. Disable only the Just for Today entry when another active or inactive item already carries `just_for_today`.

On selection:

```dart
selectedKind = value;
if (value == MorningRitualDefinitionKind.justForToday &&
    nameController.text.trim().isEmpty) {
  nameController.text = t(context, 'morning_ritual_just_for_today');
}
```

Show the fixed prayer text field only for `prayer`. Show the existing Just for Today explanation only for `justForToday`. Show timer controls only for `timer`.

- [x] **Step 4: Map the presentation kind back to the frozen model**

Save with:

```dart
final persistedType = selectedKind.persistedType;
final wantsRandomizer =
    selectedKind == MorningRitualDefinitionKind.justForToday;
```

For edits, pass `clearPrayerText: selectedKind != MorningRitualDefinitionKind.prayer`, the mapped type, and the mapped source ID. For new items, pass `prayerText` only for ordinary Prayer and `null` otherwise. Retain the existing duplicate-source guard as the service/UI fallback.

- [x] **Step 5: Regenerate and prove generated adapters are unchanged**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff -- lib/morning_ritual/models/ritual_item.g.dart
```

Expected: no diff in `ritual_item.g.dart`.

- [x] **Step 6: Format and verify GREEN**

Run:

```bash
dart format lib/morning_ritual/models/ritual_item.dart lib/morning_ritual/pages/morning_ritual_definition_kind.dart lib/morning_ritual/pages/morning_ritual_settings_tab.dart test/morning_ritual_randomizer_portability_test.dart test/morning_ritual_editor_and_import_dialog_test.dart
flutter test test/morning_ritual_randomizer_portability_test.dart test/morning_ritual_editor_and_import_dialog_test.dart test/morning_ritual_runner_test.dart
```

Expected: all focused tests pass, including the existing daily draw and history behavior.

---

### Task 3: Update canonical documentation and close the design records

**Files:**
- Modify: `lib/morning_ritual/CLAUDE.md`
- Modify: `docs/architecture.md`
- Modify: `docs/implementation_plan.md`
- Modify: `docs/historic_implementation.md`
- Modify: `docs/superpowers/specs/2026-08-09-morning-ritual-just-for-today-choice-design.md`
- Modify: `docs/superpowers/plans/2026-08-09-morning-ritual-just-for-today-release.md`

**Interfaces:**
- Consumes: implemented editor behavior and verified shared contract.
- Produces: one current-state owner in architecture, one concise area rule, one standing cross-app release rule, and one Phase 24 history entry.

- [x] **Step 1: Update current behavior in architecture**

In `architecture.md` §1.3, state that the editor presents Timer, Prayer, and Just for Today while persisting Just for Today as prayer ordinal 1 plus `randomizerSourceId: just_for_today`.

- [x] **Step 2: Update the area contract**

In `lib/morning_ritual/CLAUDE.md`, add a concise rule that the third editor kind is presentation-only and must never become a third `RitualItemType` ordinal.

- [x] **Step 3: Update the standing implementation-plan rule**

In P2.2, link the first-class editor choice to the frozen portable representation and keep `scripts/verify-cross-app-recovery.sh` as its acceptance gate. Do not add a completed roadmap item.

- [x] **Step 4: Record completion in history**

Append `## Phase 24 — Just for Today becomes a first-class ritual choice`. Record the hidden-switch root cause, the presentation-only mapping, the unchanged runner, and the bidirectional validator result. Add final store details only after both store commands return their verified states.

- [ ] **Step 5: Close the design and plan records**

Change the design status to `Implemented and released in 2.3.6+114`. Mark completed plan checkboxes only after their commands succeed. Keep failed or blocked store steps unchecked with the exact evidence in the history entry.

- [x] **Step 6: Verify documentation structure**

Run:

```bash
git diff --check
ruby -e 'require "pathname"; errors=[]; Dir.glob("{README.md,CLAUDE.md,docs/**/*.md,benchmarks/results/README.md}").reject{|f| f.start_with?("benchmarks/vendor/")}.each do |f|; File.read(f).scan(/\[[^\]]*\]\(([^)]+)\)/).flatten.each do |raw|; target=raw.strip; next if target.empty? || target.start_with?("http://","https://","mailto:","#"); target=target.split("#",2).first; next if target.empty?; target=target[1..-2] if target.start_with?("<") && target.end_with?(">"); path=Pathname.new(File.dirname(f)).join(target).cleanpath; errors << "#{f}: missing #{target}" unless path.exist?; end; end; if errors.empty?; puts "Local Markdown links passed."; else; warn errors.join("\n"); exit 1; end'
```

Expected: no whitespace errors and all local Markdown links pass.

---

### Task 4: Prepare release `2.3.6+114`

**Files:**
- Modify: `pubspec.yaml`
- Modify: `release.md`

**Interfaces:**
- Consumes: current `2.3.5+113` baseline and the feature diff since `7c62e71`.
- Produces: one version SSOT and the exact notes consumed by both store scripts.

- [x] **Step 1: Bump the shared version**

Change:

```yaml
version: 2.3.6+114
```

- [x] **Step 2: Add the newest-first bilingual notes**

Insert at the top of `release.md`:

```markdown
2.3.6 - 2026-08-09:
<en-GB>
- "Just for Today" is now a direct choice when adding or editing a morning
  ritual item. Choose it once and the ritual shows one of the ten readings each
  morning.
- Backups remain compatible with Emotional Sobriety.
</en-GB>
<da-DK>
- "Just for Today" kan nu vælges direkte, når du tilføjer eller retter et
  element i morgenritualet. Vælg det én gang, så viser ritualet én af de ti
  læsninger hver morgen.
- Sikkerhedskopier er fortsat kompatible med Emotional Sobriety.
</da-DK>
```

- [x] **Step 3: Verify store-note inputs**

Run the Play script in self-test mode and use its preflight during the eventual upload to enforce matching top version and ≤500 characters per locale:

```bash
bash scripts/upload-aab-to-play.sh --self-test
```

Expected: gate self-test passes.

---

### Task 5: Run release gates, commit intentionally, and push `main`

**Files:**
- Stage only files listed in Tasks 1–4.
- Exclude: `NEVER_READ_THIS_FILE.md`

**Interfaces:**
- Consumes: implemented feature, docs, version, and notes.
- Produces: a verified release commit on local and remote `main`.

- [x] **Step 1: Fetch and require a safe main baseline**

Run:

```bash
git fetch origin main
git rev-list --left-right --count HEAD...origin/main
```

Expected: `0 0`. If remote advanced, integrate with `git pull --ff-only origin main` only when it does not overlap the intended files.

- [x] **Step 2: Run the complete verification gates**

Run:

```bash
flutter analyze
flutter test
bash scripts/verify-cross-app-recovery.sh
git diff --check
```

Expected: analyzer clean, full test suite passes, both cross-app directions pass, and no whitespace errors.

- [x] **Step 3: Inspect and stage only intended files**

Run explicit `git add` paths for the created/modified feature, test, docs, `pubspec.yaml`, and `release.md` files. Then run:

```bash
git diff --cached --check
git diff --cached --stat
git status --short
```

Expected: `NEVER_READ_THIS_FILE.md` remains unstaged.

- [ ] **Step 4: Commit and push main**

Commit with:

```text
feat(morning): expose Just for Today choice (2.3.6)
```

Push with:

```bash
git push origin main
```

- [ ] **Step 5: Read back exact Git state**

Run:

```bash
git fetch origin main
git rev-parse HEAD
git rev-parse origin/main
git ls-remote origin refs/heads/main
git status --short --branch
```

Expected: all three SHAs match; only the pre-existing unstaged protected-file change may remain.

---

### Task 6: Build and publish Android to Play closed alpha

**Files:**
- Artifact: `build/app/outputs/bundle/release/app-release.aab`

**Interfaces:**
- Consumes: pushed `main`, `2.3.6+114`, release signing, service-account credential, top bilingual notes.
- Produces: release-signed AAB and Play alpha versionCode 114 with exact localized notes.

- [ ] **Step 1: Build and verify the AAB**

Run:

```bash
bash scripts/build-aab.sh
```

Require version `2.3.6`, versionCode `114`, a fresh AAB, and a non-debug signer.

- [ ] **Step 2: Publish to the hard-pinned closed alpha track**

Run:

```bash
bash scripts/upload-aab-to-play.sh --yes
```

Require the script to commit alpha versionCode 114, read it back as served, and report no active `internal` release that shadows alpha.

- [ ] **Step 3: Read back the raw release form**

Run:

```bash
bash scripts/upload-aab-to-play.sh --audit-tracks --raw
```

Inspect the fresh `alpha` release carrying versionCode `114`. Require its `releaseNotes` array to contain exact `en-GB` and `da-DK` strings equal to the top `release.md` blocks.

---

### Task 7: Build and upload iOS to App Store Connect/TestFlight

**Files:**
- Artifact: `build/ios/ipa/twelvestepsapp.ipa`

**Interfaces:**
- Consumes: pushed `main`, `2.3.6+114`, Apple Distribution signing, app-specific password, App Store Connect API key, top bilingual notes.
- Produces: TestFlight build 114 with en-GB and Danish “What to Test” notes.

- [ ] **Step 1: Confirm macOS and credentials through script preflight**

Run:

```bash
uname -s
bash scripts/upload-ipa-to-testflight.sh --build
```

Require `Darwin`, version `2.3.6`, build `114`, Apple Distribution signing, `UPLOAD SUCCEEDED`, and successful automatic note updates for `en-GB` and `da`/`da-DK`.

- [ ] **Step 2: Verify App Store Connect state**

Use the upload helper output and a fresh App Store Connect read-back to require build 114 for bundle ID `dk.stormstyrken.twelvestepsapp`, successful processing, and the same localized TestFlight notes. Do not submit an App Store version for public review; that is a separate owner action.

- [ ] **Step 3: Record the actual store outcomes and push the closeout**

Update Phase 24 with the Play track/status/versionCode/notes read-back and TestFlight build/processing/notes read-back. Mark the completed plan boxes, stage only the documentation plan/history files, commit with:

```text
docs: record 2.3.6 store delivery
```

Push `main`, then require local `HEAD`, `origin/main`, and `git ls-remote origin refs/heads/main` to match.
