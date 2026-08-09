import '../models/ritual_item.dart';
import '../services/morning_randomizer_source.dart';

/// Presentation-only choices shown by the Morning Ritual item editor.
///
/// Just for Today remains a persisted prayer with a randomizer source ID. This
/// enum must never replace or extend the frozen Hive-backed [RitualItemType].
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

  String get labelKey => switch (this) {
    MorningRitualDefinitionKind.timer => 'morning_ritual_type_timer',
    MorningRitualDefinitionKind.prayer => 'morning_ritual_type_prayer',
    MorningRitualDefinitionKind.justForToday => 'morning_ritual_just_for_today',
  };
}
