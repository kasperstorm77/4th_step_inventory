/// Decides whether the Today tab's calendar selection should follow the
/// clock onto a new calendar day.
///
/// `MorningRitualHome` seeds its selection from `DateTime.now()` once and
/// then lives for as long as the app does — the router keys it by app id, not
/// by date. Left on the screen overnight, or resumed from the background the
/// next morning, it would otherwise keep yesterday selected, and the Today
/// tab hides Start for anything but today.
///
/// Returns the new day to select, or `null` to leave the selection alone:
/// - `selected` differs from `autoSelected`: the user picked a day by hand —
///   never override that.
/// - the calendar day has not changed: nothing to do.
/// - a ritual is running: changing the date resets the runner mid-flow.
DateTime? rolledOverSelectedDay({
  required DateTime selected,
  required DateTime autoSelected,
  required DateTime now,
  required bool ritualInProgress,
}) {
  if (ritualInProgress) return null;
  if (!_sameDay(selected, autoSelected)) return null;
  if (_sameDay(autoSelected, now)) return null;
  return now;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
