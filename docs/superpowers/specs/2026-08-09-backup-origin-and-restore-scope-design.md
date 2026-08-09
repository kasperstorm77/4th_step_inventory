# Backup origin and restore scope design

**Date:** 2026-08-09
**Status:** Implemented in Twelve Steps; peer release blocker pending
**Owner:** Backup and cross-application recovery

## Outcome

Every newly generated Twelve Steps JSON payload identifies its origin as
`twelve-steps`. Restore scope is selected from a validated origin before any
safety backup or data mutation begins:

- a current or provably legacy Twelve Steps backup may perform a native full
  restore;
- an Emotional Sobriety backup may replace only the five shared recovery
  datasets through explicit manual JSON import;
- an unknown, malformed, or ambiguous origin is rejected without mutation.

After a successful compatibility import, the normal backup scheduler writes a
new Twelve Steps backup. That backup contains the imported shared records and
the retained Twelve Steps-only records under the `twelve-steps` product
identifier.

## Root cause

Before this change, `SyncPayloadBuilder` wrote no `product` field and
`BackupRestoreService.foreignProductOf` interpreted a missing, blank, or
non-string product as native. That collapses two separate decisions into one:

1. which application wrote the file; and
2. whether the operation is a native full restore or a cross-application
   compatibility import.

The current Emotional Sobriety importer depends on that ambiguity: it treats a
product-less `8.0` payload as the Twelve Steps compatibility format. The two
apps therefore cannot distinguish a real native restore from a compatibility
restore using positive origin evidence.

The existing compatibility apply is already correctly scoped. Its translator
keeps only I-Am definitions, Fourth Step entries, Agnosticism pairs, Morning
definitions, and Morning history. Twelve Steps-only sections stay absent, so
their boxes remain unchanged. The design retains that whitelist and makes the
origin decision strict.

## Product identifiers and supported envelopes

| Origin | Required marker | Supported version | Restore scope |
| --- | --- | --- | --- |
| Current Twelve Steps | `product: twelve-steps` | `8.0` | Native full restore |
| Legacy Twelve Steps | No `product`; positive legacy-native fingerprint | Version remains informational | Native full restore |
| Emotional Sobriety | `product: emotional-sobriety` | `1.0` | Five shared datasets only |
| Missing and ambiguous | No `product`; no native fingerprint | Any | Reject |
| Unknown or malformed | Any other, blank, or non-string `product` | Any | Reject |

The stable product identifier is independent of the store title, package ID,
filename, schema version, and localization.

## Origin classification

Replace the nullable `foreignProductOf` decision and the
`allowForeignProduct` escape hatch with explicit concepts:

- `BackupOrigin`: current Twelve Steps, legacy Twelve Steps, Emotional
  Sobriety, or unsupported;
- `RestoreIntent`: native restore or manual JSON import;
- `RestoreScope`: full native or shared compatibility.

Classification runs before structural validation, safety backup creation, or
box access. Scope selection follows these rules:

1. Accept `product: twelve-steps` with version `8.0` as full native scope.
2. Accept a product-less payload as legacy native only when it contains a
   positive Twelve Steps-only fingerprint from a historically emitted
   envelope. Supported fingerprint keys include `people`, `reflections`,
   `gratitude`, `gratitudeEntries`, `notifications`, or `appSettings`. Keep the
   legacy `version` field informational, including when it is absent, because
   structural section decoders—not a version switch—own the existing
   pre-`8.0` compatibility behavior.
3. Reject a product-less payload that contains only shared keys. Do not infer
   full native scope from schema version alone.
4. Accept `product: emotional-sobriety` with version `1.0` only for manual JSON
   import and only after the existing dataset-specific confirmation.
5. Reject Emotional Sobriety payloads on local-backup, Drive-fetch, startup,
   or other automatic native restore paths.
6. Reject unknown, blank, non-string, mismatched-version, and otherwise
   unsupported origins before creating a safety backup or mutating a box.

The legacy fingerprint exists only in Twelve Steps. It preserves native
backups produced before origin tagging, including the supported
`gratitudeEntries` and `agnosticismPapers` aliases, without classifying an
ambiguous shared-only document as a full restore.

## Native restore behavior

The native scope keeps the existing section-replacement semantics and legacy
decoders:

- decode each present section before clearing its box;
- import I-Am definitions before entries;
- restore every native section present in the payload;
- leave an absent section unchanged;
- preserve legacy aliases and tolerant historical record decoding;
- report skipped unreadable records with the existing count;
- create the pre-restore safety backup only after origin and payload
  validation succeed.

New JSON export, local backup, safety backup, and Drive backup paths all use
`SyncPayloadBuilder`, so every newly written native payload carries
`product: twelve-steps`.

## Compatibility import behavior

The Emotional Sobriety path remains manual and transactional. Validate the
exact product and version, then require the five compatibility sections to be
lists before confirmation or mutation:

| Emotional Sobriety key | Twelve Steps destination |
| --- | --- |
| `iAmDefinitions` | `iAmDefinitions` |
| `entries` | `entries` |
| `agnosticismPairs` | `agnosticism` |
| `morningRitualItems` | `morningRitualItems` |
| `morningRitualEntries` | `morningRitualEntries` |

Ignore `workshopProgress`, `morningRitualDraft`, and
`emotionalSobrietySettings`. Keep `people`, `reflections`, `gratitude`,
`notifications`, and `appSettings` absent from the translated payload so their
local data cannot be cleared.

The confirmation dialog continues to name the five replacement datasets,
their record counts, and the ignored foreign sections. The apply path retains
the existing pair-cap and randomized-reading normalization rules.

## Canonical backup after compatibility import

After the shared compatibility transaction commits:

1. notify the UI through the existing data-refresh mechanism;
2. let `BackupRestoreService` schedule
   `AllAppsDriveService.scheduleUploadFromBox()` exactly once after a committed
   shared compatibility import, covering both mobile and desktop callers;
3. let that scheduler always create a debounced local backup and create a
   Drive backup only when sync state permits it;
4. rebuild the payload from every current Hive box rather than reusing or
   relabeling the foreign JSON.

This produces a native `twelve-steps` backup containing both the newly imported
shared data and all retained Twelve Steps-only data. A blocked or unavailable
Drive upload does not prevent the local canonical backup.

## Emotional Sobriety implementation task

Add an accepted task to Emotional Sobriety's
`docs/implementation_plan.md` with this strict gate:

- accept Twelve Steps compatibility input only when
  `product == twelve-steps` and `version == 8.0`;
- route that origin only to the existing five-dataset shared transaction;
- reject product-less Twelve Steps payloads rather than adding a legacy
  heuristic, because Emotional Sobriety is still pre-release;
- reject unknown, blank, malformed, or mismatched identifiers before safety
  backup creation or mutation;
- keep automatic Emotional restore and Drive discovery restricted to exact
  `product == emotional-sobriety` complete backups;
- update the peer validator, real-output fixture, documentation, and cross-app
  gate before either app ships a release.

Until that peer task lands, Twelve Steps' live labeled export is expected to
fail Emotional Sobriety's current product-less compatibility validator. Record
that as a release blocker; never weaken or bypass the cross-app release gate.

## Tests and verification

Implement the behavior test-first and prove:

- every current payload source writes `product: twelve-steps`;
- a labeled `8.0` Twelve Steps payload performs a full native restore;
- supported product-less legacy payloads still perform native restores;
- product-less shared-only, blank-product, non-string-product, unknown-product,
  and mismatched-version payloads fail without changing data;
- Drive and local restore paths reject Emotional Sobriety payloads;
- manual Emotional Sobriety import replaces exactly the five shared datasets;
- Twelve Steps-only data survives compatibility import;
- the next canonical payload contains imported shared data, retained native
  data, and `product: twelve-steps`;
- the centralized compatibility commit schedules canonical backup exactly
  once, independent of its mobile or desktop caller;
- focused backup, round-trip, randomizer, UI, and parity tests pass;
- `flutter analyze` and `flutter test` pass.

Run `bash scripts/verify-cross-app-recovery.sh` after the Emotional Sobriety
task lands. Before then, preserve its failure as an explicit release blocker
rather than claiming cross-application verification passed.

## Documentation impact

Update these canonical owners in the implementation change:

- `lib/shared/CLAUDE.md` for scoped restore and origin rules;
- `docs/architecture.md` for current envelope, classifier, and restore flows;
- `docs/implementation_plan.md` for the standing cross-app contract and peer
  release blocker;
- `docs/historic_implementation.md` for the completed origin-gate decision and
  verification evidence;
- Emotional Sobriety `docs/implementation_plan.md` for the exact peer task.

Keep schema version `8.0`, shared entity shapes, Hive models, box names, Drive
scope, and the five-dataset compatibility boundary unchanged.
