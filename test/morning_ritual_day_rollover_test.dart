import 'package:flutter_test/flutter_test.dart';
import 'package:twelvestepsapp/morning_ritual/services/selected_day_rollover.dart';

/// The Today tab's calendar selection is seeded once from `DateTime.now()`
/// and the page stays alive across backgrounding. Without a rollover rule a
/// phone left on Morning Ritual overnight still shows yesterday selected the
/// next morning — and `_isToday` then hides the Start button.
void main() {
  final yesterday = DateTime(2026, 8, 26, 7, 30);
  final today = DateTime(2026, 8, 27, 6, 45);

  test('moves an untouched selection forward when the day has changed', () {
    expect(
      rolledOverSelectedDay(
        selected: yesterday,
        autoSelected: yesterday,
        now: today,
        ritualInProgress: false,
      ),
      today,
    );
  });

  test('keeps the selection when it is still the same calendar day', () {
    expect(
      rolledOverSelectedDay(
        selected: yesterday,
        autoSelected: yesterday,
        now: DateTime(2026, 8, 26, 23, 59),
        ritualInProgress: false,
      ),
      isNull,
    );
  });

  test('does not override a day the user picked by hand', () {
    final picked = DateTime(2026, 8, 20);
    expect(
      rolledOverSelectedDay(
        selected: picked,
        autoSelected: yesterday,
        now: today,
        ritualInProgress: false,
      ),
      isNull,
    );
  });

  test('never changes the day under a running ritual', () {
    expect(
      rolledOverSelectedDay(
        selected: yesterday,
        autoSelected: yesterday,
        now: today,
        ritualInProgress: true,
      ),
      isNull,
    );
  });
}
