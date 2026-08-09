# Morning Ritual Just for Today Choice

**Date:** 2026-08-09
**Status:** Implemented and released in 2.3.6+114

## Problem

The Morning Ritual runner, randomized reading catalog, history snapshots, and
cross-application backup contract already support the `just_for_today` source.
The item editor does not present that capability as an item type. It exposes
only Timer and Prayer, then hides Just for Today behind a switch that appears
after Prayer is selected. This makes the feature absent from the workflow the
user sees.

Emotional Sobriety presents Just for Today as a first-class editor choice while
persisting it as an ordinary reading plus a randomizer source ID. It already
draws one entry when a ritual starts and displays that entry in the runner.
No Emotional Sobriety implementation task is required.

## Goals

- Show `Just for Today` directly beside Timer and Prayer in the type dropdown.
- Use the exact English product name `Just for Today` in both English and Danish
  UI.
- Auto-fill an empty item name with `Just for Today` when that type is selected,
  without overwriting a custom name.
- Continue drawing one of the ten bundled entries when the morning ritual
  starts and display the held selection while that item is used.
- Retain backup and restore compatibility with Emotional Sobriety in both
  directions.
- Continue allowing at most one Just for Today definition.

## Non-goals

- Do not add another randomized reading source.
- Do not change the ten reading entries or their stable IDs.
- Do not change runner, resume, previous, start-over, history, or localization
  behavior that is already implemented and tested.
- Do not change the backup schema version or any Hive schema.

## Design

### Presentation kind

Introduce a presentation-only Morning Ritual definition kind with three values:
Timer, Prayer, and Just for Today. It maps to the existing persisted contract:

| Editor choice | Persisted `RitualItemType` | `randomizerSourceId` |
| --- | --- | --- |
| Timer | `timer` | `null` |
| Prayer | `prayer` | `null` |
| Just for Today | `prayer` | `just_for_today` |

The persisted `RitualItemType` enum remains exactly `timer=0, prayer=1`. The
new kind exists only in presentation code and must never be serialized.

### Item editor

Replace the two-value persisted-type dropdown with the three-value presentation
dropdown. Just for Today uses the existing book icon and localization key.

When Just for Today is selected:

- fill the name with `Just for Today` only if the name is currently blank;
- show the existing explanation of the daily random draw;
- hide timer controls and the fixed prayer-text field;
- clear `prayerText` to `null`, matching Emotional Sobriety and preventing stale
  fixed text from travelling beside a randomized definition;
- save the persisted type as `prayer` and source ID as `just_for_today`.

Add a non-serialized `clearPrayerText` option to `RitualItem.copyWith`, parallel
to its existing `clearRandomizerSourceId` option. This changes no Hive field,
adapter, JSON key, or cross-app value; it only lets the editor explicitly clear
field 4 when converting an existing Prayer into Just for Today.

When an existing Just for Today item is edited, the dropdown opens on Just for
Today. Switching it to Timer or Prayer clears the randomizer source through the
existing `copyWith(clearRandomizerSourceId: true)` path.

If another active or inactive Just for Today definition already exists, the
choice remains visible but unavailable and the existing singleton explanation
is shown. The service-level validation remains the final guard.

### Runner and daily selection

No runner change is required. `MorningRandomizerSource` already supplies the
ten generated entries. The runner draws a missing selection when the daily
ritual starts, holds it in `morning_ritual_progress`, displays the selected text,
and snapshots the selected ID and text into the finished record. Resume,
previous, and start over continue using the same daily selection.

## Cross-application compatibility

This change must not alter any portable representation:

- Hive type IDs and field indices stay unchanged.
- `RitualItemType` ordinals stay `timer=0, prayer=1`.
- JSON keys, schema version `8.0`, and box names stay unchanged.
- The source ID remains exactly `just_for_today`.
- The generated catalog and stable option IDs stay unchanged.
- Completed/skipped records continue carrying both `selectedContentId` and
  `selectedContentText`; static and missed records carry neither.
- Definition sort orders remain unique and contiguous, and only one randomized
  definition is permitted.

Compatibility will be verified with the repository's bidirectional
`scripts/verify-cross-app-recovery.sh` gate, which feeds live payloads through
both applications' production validators.

## Error handling

- A duplicate Just for Today choice is prevented in the editor and still
  rejected by the existing service/import rules.
- Unknown imported randomizer source IDs retain the existing fallback behavior;
  this UI recognizes only the shipped `just_for_today` source.
- No catalog or source-loading error behavior changes.

## Testing

1. Add a widget regression test proving the editor dropdown directly contains
   Timer, Prayer, and `Just for Today`.
2. Run the widget in both `en` and `da` and assert the exact English name is
   visible in both.
3. Select Just for Today from a blank item, verify the name is filled, the fixed
   prayer-text field is hidden, and saving creates a `prayer` item with
   `prayerText: null` and `randomizerSourceId: just_for_today`.
4. Verify an existing Just for Today item opens with that presentation kind and
   retains its portable fields after saving.
5. Keep the existing runner tests that prove one random selection is displayed,
   held across navigation/restart actions, and snapshotted into history.
6. Run focused tests, `flutter analyze`, the full `flutter test` suite, and
   `bash scripts/verify-cross-app-recovery.sh`.

## Success criteria

- The dropdown in the reported add-item workflow visibly offers Just for Today.
- The label is exactly `Just for Today` in English and Danish.
- Starting a ritual containing that item displays one of the ten bundled daily
  entries and does not redraw it during the same ritual.
- Bidirectional cross-app backup verification exits successfully.
- No persisted schema or generated adapter changes are present.
