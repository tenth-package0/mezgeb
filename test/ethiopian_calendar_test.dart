import 'package:flutter_test/flutter_test.dart';
import 'package:mezgeb/calendar/ethiopian_calendar.dart';

void main() {
  test('Gregorian new year 2024 maps to Ethiopian 2017', () {
    expect(
      EthiopianCalendar.fromGregorian(DateTime(2024, 9, 11)),
      const EthiopianDate(2017, 1, 1),
    );
  });

  test('Gregorian Christmas 2024 maps to Tahsas', () {
    expect(
      EthiopianCalendar.fromGregorian(DateTime(2024, 12, 25)),
      const EthiopianDate(2017, 4, 16),
    );
  });

  test('Ethiopian leap year has Pagume sixth day', () {
    expect(
      EthiopianCalendar.fromGregorian(DateTime(2019, 9, 11)),
      const EthiopianDate(2011, 13, 6),
    );
  });

  test('month names reject values outside the Ethiopian calendar', () {
    expect(() => EthiopianCalendar.monthName(0), throwsRangeError);
    expect(() => EthiopianCalendar.monthName(14), throwsRangeError);
  });

  test('date-time formatting pads clock values', () {
    expect(
      EthiopianCalendar.formatDateTime(DateTime(2024, 9, 11, 7, 5)),
      'መስከረም 1, 2017 at 07:05',
    );
  });
}
