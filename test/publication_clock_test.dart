import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/services/publication_clock.dart';

void main() {
  test('London publication date is independent of the device offset', () {
    final instant = DateTime.parse('2026-10-16T00:30:00+09:00');

    expect(PublicationClock.londonDate(instant), DateTime.utc(2026, 10, 15));
  });

  test('London date changes at midnight during British Summer Time', () {
    expect(
      PublicationClock.londonDate(DateTime.utc(2026, 10, 15, 22, 59, 59)),
      DateTime.utc(2026, 10, 15),
    );
    expect(
      PublicationClock.londonDate(DateTime.utc(2026, 10, 15, 23)),
      DateTime.utc(2026, 10, 16),
    );
  });

  test('BST boundaries switch at 01:00 UTC', () {
    expect(
      PublicationClock.isBritishSummerTime(DateTime.utc(2026, 3, 29, 0, 59)),
      isFalse,
    );
    expect(
      PublicationClock.isBritishSummerTime(DateTime.utc(2026, 3, 29, 1)),
      isTrue,
    );
    expect(
      PublicationClock.isBritishSummerTime(DateTime.utc(2026, 10, 25, 0, 59)),
      isTrue,
    );
    expect(
      PublicationClock.isBritishSummerTime(DateTime.utc(2026, 10, 25, 1)),
      isFalse,
    );
  });

  test('next London midnight accounts for 23 and 25 hour DST days', () {
    expect(
      PublicationClock.untilNextLondonMidnight(DateTime.utc(2026, 3, 29)),
      const Duration(hours: 23),
    );
    expect(
      PublicationClock.untilNextLondonMidnight(DateTime.utc(2026, 10, 24, 23)),
      const Duration(hours: 25),
    );
  });
}
