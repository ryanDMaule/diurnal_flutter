/// Calendar calculations for Diurnus's authoritative Europe/London
/// publication day.
///
/// The current UK rules change to summer time at 01:00 UTC on the last Sunday
/// in March and return to GMT at 01:00 UTC on the last Sunday in October.
abstract final class PublicationClock {
  static DateTime londonDate(DateTime instant) {
    final utc = instant.toUtc();
    final london = utc.add(
      isBritishSummerTime(utc) ? const Duration(hours: 1) : Duration.zero,
    );
    return DateTime.utc(london.year, london.month, london.day);
  }

  static bool isBritishSummerTime(DateTime instant) {
    final utc = instant.toUtc();
    final start = _lastSundayAtOneUtc(utc.year, DateTime.march);
    final end = _lastSundayAtOneUtc(utc.year, DateTime.october);
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  static DateTime nextLondonMidnight(DateTime instant) {
    final utc = instant.toUtc();
    final today = londonDate(utc);
    final nextDate = DateTime.utc(today.year, today.month, today.day + 1);
    final nominalMidnight = DateTime.utc(
      nextDate.year,
      nextDate.month,
      nextDate.day,
    );
    return isBritishSummerTime(nominalMidnight)
        ? nominalMidnight.subtract(const Duration(hours: 1))
        : nominalMidnight;
  }

  static Duration untilNextLondonMidnight(DateTime instant) {
    final duration = nextLondonMidnight(instant).difference(instant.toUtc());
    return duration.isNegative ? Duration.zero : duration;
  }

  static DateTime _lastSundayAtOneUtc(int year, int month) {
    final finalDay = DateTime.utc(year, month + 1, 0);
    final lastSundayDay = finalDay.day - (finalDay.weekday % DateTime.daysPerWeek);
    return DateTime.utc(year, month, lastSundayDay, 1);
  }
}
