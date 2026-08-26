import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:twelvestepsapp/agnosticism/models/barrier_power_pair.dart';
import 'package:twelvestepsapp/eighth_step/models/person.dart';
import 'package:twelvestepsapp/evening_ritual/models/reflection_entry.dart';
import 'package:twelvestepsapp/fourth_step/models/i_am_definition.dart';
import 'package:twelvestepsapp/fourth_step/models/inventory_entry.dart';
import 'package:twelvestepsapp/gratitude/models/gratitude_entry.dart';
import 'package:twelvestepsapp/morning_ritual/models/morning_ritual_entry.dart';
import 'package:twelvestepsapp/notifications/models/app_notification.dart';
import 'package:twelvestepsapp/shared/services/backup_restore_service.dart';
import 'package:twelvestepsapp/shared/services/sync_payload_builder.dart';

import 'support/hive_test_harness.dart';

/// Data safety around the Emotional Sobriety compatibility import.
///
/// Twelve Steps is the released app; the other side is pre-release. So the
/// question these tests answer is not "does the import work" (that is
/// [emotional_sobriety_import_test.dart]) but "what happens to the data that
/// was already here" — before, during and after a foreign import, and whether
/// the app's own backups still restore once one has run.
void main() {
  setUp(openAllBoxes);
  tearDown(closeAllBoxes);

  Map<String, dynamic> esFixture() =>
      jsonDecode(
            File(
              'test/fixtures/emotional_sobriety_export_1_0.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  /// The sections this app owns and the other product has no concept of.
  const twelveStepsOnlySections = <String>[
    'people',
    'reflections',
    'gratitude',
    'notifications',
    'appSettings',
  ];

  /// The five sections that cross the app boundary.
  const sharedSections = <String>[
    'iAmDefinitions',
    'entries',
    'agnosticism',
    'morningRitualItems',
    'morningRitualEntries',
  ];

  /// Fill every box this app owns, so an import has something to damage.
  Future<void> seedEveryBox() async {
    await Hive.box<IAmDefinition>('i_am_definitions').add(
      IAmDefinition(
        id: 'native-def',
        name: 'A native definition',
        reasonToExist: 'Mine, from before the import',
      ),
    );
    await Hive.box<InventoryEntry>('entries').add(
      InventoryEntry(
        'An old resentment',
        'It was mine',
        'Self-esteem',
        'My part',
        'Pride',
        id: 'native-entry',
        order: 1,
        iAmIds: <String>['native-def'],
      ),
    );
    await Hive.box<Person>('people_box').put(
      'native-person',
      Person(
        internalId: 'native-person',
        name: 'Someone I owe',
        amends: 'Return what I took',
        column: ColumnType.maybe,
        amendsDone: true,
        sortOrder: 2000,
      ),
    );
    await Hive.box<ReflectionEntry>('reflections_box').put(
      'native-reflection',
      ReflectionEntry(
        internalId: 'native-reflection',
        date: DateTime(2026, 8, 6),
        type: ReflectionType.afraid,
        detail: 'Money again',
      ),
    );
    await Hive.box<GratitudeEntry>('gratitude_box').add(
      GratitudeEntry(
        date: DateTime(2026, 8, 5),
        gratitudeTowards: 'A quiet morning',
        gratefulFor: 'No phone',
        createdAt: DateTime(2026, 8, 5, 6),
      ),
    );
    await Hive.box<BarrierPowerPair>('agnosticism_pairs').put(
      'native-pair',
      BarrierPowerPair(
        id: 'native-pair',
        barrier: 'I have to be right',
        power: 'I can be wrong and still be loved',
        connectedFear: 'Being dismissed',
        createdAt: DateTime(2026, 8, 5),
      ),
    );
    await Hive.box<AppNotification>('notifications_box').put(
      'native-notification',
      AppNotification(
        id: 'native-notification',
        notificationId: 4242,
        title: 'Evening reflection',
        body: 'Time to look back at the day',
        enabled: true,
        scheduleType: NotificationScheduleType.daily,
        timeMinutes: 21 * 60 + 30,
      ),
    );
    await Hive.box('settings').put('language', 'da');
    await Hive.box('settings').put('onboardingCompleted', true);
  }

  /// A stable, comparable snapshot of the named sections of a live payload.
  String snapshotOf(Iterable<String> sections, Map<String, dynamic> payload) {
    return jsonEncode(<String, dynamic>{
      for (final key in sections)
        if (payload.containsKey(key)) key: payload[key],
    });
  }

  Future<RestoreResult> importEmotionalSobriety({
    Map<String, dynamic>? data,
    void Function()? scheduleCanonicalBackup,
  }) => BackupRestoreService.restoreFromPayload(
    data ?? esFixture(),
    createSafetyBackup: false,
    intent: RestoreIntent.manualJsonImport,
    scheduleCanonicalBackup: scheduleCanonicalBackup ?? () {},
  );

  // ---------------------------------------------------------------------------
  // 1. No corruption of existing data
  // ---------------------------------------------------------------------------

  group('a compatibility import leaves this app\'s own data alone', () {
    test('people, reflections, gratitude, notifications and appSettings are '
        'byte-for-byte unchanged', () async {
      await seedEveryBox();
      final before = snapshotOf(
        twelveStepsOnlySections,
        SyncPayloadBuilder.buildPayload(),
      );

      final result = await importEmotionalSobriety();
      expect(result.success, isTrue, reason: result.error);

      final after = snapshotOf(
        twelveStepsOnlySections,
        SyncPayloadBuilder.buildPayload(),
      );
      expect(
        after,
        before,
        reason:
            'the five sections the other product does not own must survive '
            'an import of it untouched',
      );
    });

    test('the five shared sections equal the incoming data', () async {
      await seedEveryBox();
      final incoming = esFixture();

      final result = await importEmotionalSobriety(data: incoming);
      expect(result.success, isTrue, reason: result.error);

      // Counts first: the native rows are replaced, not merged into.
      expect(
        result.counts.iAmDefinitions,
        (incoming['iAmDefinitions'] as List).length,
      );
      expect(result.counts.entries, (incoming['entries'] as List).length);
      expect(
        result.counts.agnosticism,
        (incoming['agnosticismPairs'] as List).length,
      );
      expect(
        result.counts.morningRitualItems,
        (incoming['morningRitualItems'] as List).length,
      );
      expect(
        result.counts.morningRitualEntries,
        (incoming['morningRitualEntries'] as List).length,
      );
      expect(result.counts.skippedRecords, 0);

      // And the rows on disk are the incoming ones, not the seeded ones.
      expect(
        Hive.box<IAmDefinition>('i_am_definitions').values.single.id,
        'source-definition',
      );
      expect(
        Hive.box<InventoryEntry>('entries').values.single.id,
        'source-inventory',
      );
      expect(
        Hive.box<BarrierPowerPair>(
          'agnosticism_pairs',
        ).values.map((p) => p.id).toSet(),
        isNot(contains('native-pair')),
      );
    });

    test('the sections it drops never reach a box', () async {
      await seedEveryBox();
      final settingsBefore = Hive.box('settings').get('language');

      await importEmotionalSobriety();

      // workshopProgress / morningRitualDraft / emotionalSobrietySettings are
      // ignored. The foreign settings block in particular must not overwrite
      // this app's own language or onboarding state.
      expect(Hive.box('settings').get('language'), settingsBefore);
      expect(Hive.box('settings').get('onboardingCompleted'), isTrue);
    });

    test('an unreadable record inside a shared section is skipped, not fatal, '
        'and damages no other box', () async {
      await seedEveryBox();
      final before = snapshotOf(
        twelveStepsOnlySections,
        SyncPayloadBuilder.buildPayload(),
      );

      final corrupted = esFixture();
      (corrupted['agnosticismPairs'] as List).add(<String, dynamic>{
        'id': 'broken',
        // `barrier` and `power` are required; this row cannot be decoded.
      });
      (corrupted['entries'] as List).add('not even a map');

      final result = await importEmotionalSobriety(data: corrupted);

      expect(result.success, isTrue, reason: result.error);
      expect(
        result.counts.skippedRecords,
        2,
        reason: 'both unreadable rows are counted, not silently dropped',
      );
      expect(
        snapshotOf(twelveStepsOnlySections, SyncPayloadBuilder.buildPayload()),
        before,
      );
    });

    /// Every section the payload builder writes — the whole data surface.
    const allSections = <String>[...sharedSections, ...twelveStepsOnlySections];

    String fullSnapshot() =>
        snapshotOf(allSections, SyncPayloadBuilder.buildPayload());

    tearDown(() => BackupRestoreService.afterSectionWriteForTest = null);

    test(
      'a failure late in the apply rolls EVERY box back to the pre-import '
      'snapshot, automatically',
      () async {
        await seedEveryBox();
        final before = fullSnapshot();

        // Fail after the eighth of nine section writes: by then every shared
        // box has already been cleared and rewritten with the foreign rows.
        BackupRestoreService.afterSectionWriteForTest = (section) async {
          if (section == 'morningRitualEntries') {
            throw StateError('injected failure after $section');
          }
        };

        final result = await importEmotionalSobriety();

        expect(result.success, isFalse);
        expect(result.rollbackFailed, isFalse);
        expect(result.error, contains('rolled back'));
        expect(
          fullSnapshot(),
          before,
          reason: 'every box must be byte-identical to before the import',
        );
        // The specific row the import had already overwritten is back.
        expect(
          Hive.box<IAmDefinition>('i_am_definitions').values.single.id,
          'native-def',
        );
        expect(
          Hive.box<InventoryEntry>('entries').values.single.id,
          'native-entry',
        );
      },
    );

    test(
      'a failure late in a NATIVE twelve-steps/8.0 restore rolls every box '
      'back too',
      () async {
        await seedEveryBox();
        final before = fullSnapshot();

        // A native file that would replace every section, failing on the very
        // last write. All ten boxes are already overwritten at that point.
        final incoming = SyncPayloadBuilder.buildPayload();
        (incoming['people'] as List).clear();
        (incoming['gratitude'] as List).clear();
        (incoming['iAmDefinitions'] as List)[0]['id'] = 'replacement-def';

        BackupRestoreService.afterSectionWriteForTest = (section) async {
          if (section == 'appSettings') {
            throw StateError('injected failure after $section');
          }
        };

        final result = await BackupRestoreService.restoreFromPayload(
          incoming,
          createSafetyBackup: false,
        );

        expect(result.success, isFalse);
        expect(result.rollbackFailed, isFalse);
        expect(fullSnapshot(), before);
        expect(Hive.box<Person>('people_box').length, 1);
        expect(Hive.box<GratitudeEntry>('gratitude_box').length, 1);
        expect(
          Hive.box<IAmDefinition>('i_am_definitions').values.single.id,
          'native-def',
        );
        expect(Hive.box('settings').get('language'), 'da');
      },
    );

    test(
      'a box that is not open is refused by pre-flight before the first '
      'clear()',
      () async {
        await seedEveryBox();
        final before = fullSnapshot();
        final iAmBefore = Hive.box<IAmDefinition>(
          'i_am_definitions',
        ).values.single.id;

        await Hive.box<MorningRitualEntry>('morning_ritual_entries').close();
        final result = await importEmotionalSobriety();
        await Hive.openBox<MorningRitualEntry>('morning_ritual_entries');

        expect(result.success, isFalse);
        expect(result.rollbackFailed, isFalse);
        expect(result.error, contains('pre-flight'));
        expect(result.error, contains('morning_ritual_entries'));
        expect(
          Hive.box<IAmDefinition>('i_am_definitions').values.single.id,
          iAmBefore,
          reason: 'the first section must not have been written',
        );
        expect(fullSnapshot(), before);
      },
    );

    test(
      'a rollback that itself fails is reported distinctly, never as success',
      () async {
        await seedEveryBox();

        // Fail late AND sabotage the rollback: closing a box that was already
        // rewritten makes the journal's clear()/putAll() throw.
        BackupRestoreService.afterSectionWriteForTest = (section) async {
          if (section == 'morningRitualEntries') {
            await Hive.box<IAmDefinition>('i_am_definitions').close();
            throw StateError('injected failure after $section');
          }
        };

        final result = await importEmotionalSobriety();
        await Hive.openBox<IAmDefinition>('i_am_definitions');

        expect(result.success, isFalse);
        expect(
          result.rollbackFailed,
          isTrue,
          reason: 'the one outcome the caller must treat differently',
        );
        expect(result.error, contains('rollback also failed'));
        expect(result.error, contains('safety backup'));
      },
    );

    test('the canonical backup is only scheduled when the import committed', () async {
      await seedEveryBox();
      var scheduled = 0;

      BackupRestoreService.afterSectionWriteForTest = (section) async {
        if (section == 'morningRitualEntries') {
          throw StateError('injected failure after $section');
        }
      };
      final failed = await importEmotionalSobriety(
        scheduleCanonicalBackup: () => scheduled++,
      );
      expect(failed.success, isFalse);
      expect(
        scheduled,
        0,
        reason: 'a failed import must not queue a backup of a half state',
      );

      BackupRestoreService.afterSectionWriteForTest = null;
      final ok = await importEmotionalSobriety(
        scheduleCanonicalBackup: () => scheduled++,
      );
      expect(ok.success, isTrue, reason: ok.error);
      expect(scheduled, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Backwards compatibility of this app's own restore, after an import
  // ---------------------------------------------------------------------------

  group('this app\'s own backups still restore after a foreign import', () {
    /// A payload shaped like one the released build writes.
    ///
    /// Built from a LIVE [SyncPayloadBuilder] run over seeded boxes, never
    /// hand-authored: the last cross-app defect survived both apps' suites
    /// precisely because every fixture carried values no device produces (a
    /// hand-written `'column': 0` here decoded to nothing, because the real
    /// encoder writes that field as a string).
    Future<Map<String, dynamic>> releasedNativeBackup() async {
      await clearAllDataBoxes();
      await Hive.box('settings').clear();
      await Hive.box<IAmDefinition>('i_am_definitions').add(
        IAmDefinition(id: 'released-def', name: 'From the store build'),
      );
      await Hive.box<Person>('people_box').put(
        'released-person',
        Person(
          internalId: 'released-person',
          name: 'From the store build',
          column: ColumnType.yes,
          sortOrder: 1000,
        ),
      );
      await Hive.box<GratitudeEntry>('gratitude_box').add(
        GratitudeEntry(
          date: DateTime(2026, 8, 1),
          gratitudeTowards: 'Released build',
          gratefulFor: 'Still restoring',
          createdAt: DateTime(2026, 8, 1),
        ),
      );
      await Hive.box<BarrierPowerPair>('agnosticism_pairs').put(
        'released-pair',
        BarrierPowerPair(
          id: 'released-pair',
          barrier: 'Nothing will change',
          power: 'Something already has',
          connectedFear: 'Wasting more years',
          createdAt: DateTime(2026, 8, 1),
        ),
      );
      final payload = SyncPayloadBuilder.buildPayload();
      await clearAllDataBoxes();
      await Hive.box('settings').clear();
      return payload;
    }

    /// A pre-v6.0 backup: no `product` marker, the old section aliases.
    ///
    /// Derived from a live payload too, then renamed — so the ROWS are real
    /// and only the envelope is legacy.
    Future<Map<String, dynamic>> legacyAliasBackup() async {
      final native = await releasedNativeBackup();
      final legacy = <String, dynamic>{'version': '5.0'};
      legacy['gratitudeEntries'] = native['gratitude'];
      legacy['agnosticismPapers'] = native['agnosticism'];
      legacy['people'] = native['people'];
      return legacy;
    }

    test(
      'a released twelve-steps/8.0 file restores after an import has run',
      () async {
        final native = await releasedNativeBackup();
        await seedEveryBox();
        final imported = await importEmotionalSobriety();
        expect(imported.success, isTrue, reason: imported.error);

        // The user now restores their own Drive backup, the automatic way.
        final result = await BackupRestoreService.restoreFromPayload(
          native,
          createSafetyBackup: false,
        );

        expect(result.success, isTrue, reason: result.error);
        expect(
          Hive.box<IAmDefinition>('i_am_definitions').values.single.id,
          'released-def',
          reason: 'the foreign rows must be replaced by the native backup',
        );
        expect(
          Hive.box<Person>('people_box').values.single.internalId,
          'released-person',
        );
        expect(
          Hive.box<GratitudeEntry>('gratitude_box').values.single.gratefulFor,
          'Still restoring',
        );
      },
    );

    test('a legacy product-less backup with the old aliases restores after an '
        'import has run', () async {
      final legacy = await legacyAliasBackup();
      await seedEveryBox();
      final imported = await importEmotionalSobriety();
      expect(imported.success, isTrue, reason: imported.error);

      final result = await BackupRestoreService.restoreFromPayload(
        legacy,
        createSafetyBackup: false,
      );

      expect(result.success, isTrue, reason: result.error);
      expect(
        BackupRestoreService.originOf(legacy),
        BackupOrigin.legacyTwelveSteps,
        reason: 'a product-less native file must classify as legacy native',
      );
      expect(
        Hive.box<GratitudeEntry>('gratitude_box').values.single.gratefulFor,
        'Still restoring',
        reason: 'the gratitudeEntries alias must still land in the box',
      );
      expect(
        Hive.box<BarrierPowerPair>('agnosticism_pairs').values.single.id,
        'released-pair',
        reason: 'the agnosticismPapers alias must still land in the box',
      );
    });

    test('the file this app exports after an import is native, complete, and '
        'restores onto a pristine install', () async {
      await seedEveryBox();
      final imported = await importEmotionalSobriety();
      expect(imported.success, isTrue, reason: imported.error);

      // Step 6 of the import queues exactly this: a fresh payload built from
      // the boxes, combining the imported sections with the untouched ones.
      final rebuilt = SyncPayloadBuilder.buildPayload();
      expect(rebuilt['product'], SyncPayloadBuilder.productId);
      expect(rebuilt['version'], SyncPayloadBuilder.schemaVersion);
      expect(
        BackupRestoreService.originOf(rebuilt),
        BackupOrigin.twelveSteps,
        reason: 'the rebuilt file must classify as this app\'s own',
      );
      for (final key in [...sharedSections, ...twelveStepsOnlySections]) {
        expect(
          rebuilt.containsKey(key),
          isTrue,
          reason: '$key must be present in the rebuilt canonical file',
        );
      }
      // It must round-trip as bytes, too — UTF-8, not code units.
      final encoded = utf8.encode(jsonEncode(rebuilt));
      final decoded = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;

      // A pristine install of the released schema: every box empty.
      await clearAllDataBoxes();
      await Hive.box('settings').clear();

      final result = await BackupRestoreService.restoreFromPayload(
        decoded,
        createSafetyBackup: false,
      );

      expect(result.success, isTrue, reason: result.error);
      expect(result.counts.skippedRecords, 0);
      // Both halves survive the trip: the imported rows...
      expect(
        Hive.box<IAmDefinition>('i_am_definitions').values.single.id,
        'source-definition',
      );
      // ...and this app's own rows that the import left alone.
      expect(
        Hive.box<Person>('people_box').values.single.internalId,
        'native-person',
      );
      expect(
        Hive.box<ReflectionEntry>('reflections_box').values.single.detail,
        'Money again',
      );
      expect(Hive.box<GratitudeEntry>('gratitude_box').length, 1);
      expect(Hive.box<AppNotification>('notifications_box').length, 1);
    });
  });
}
