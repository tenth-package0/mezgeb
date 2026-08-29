class EthiopianDate {
  const EthiopianDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  String get monthName => EthiopianCalendar.monthName(month);
  String get label => '$monthName $day, $year';

  @override
  bool operator ==(Object other) {
    return other is EthiopianDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => label;
}

class EthiopianCalendar {
  static const int _ethiopicEpoch = 1723856;

  static const List<String> monthNames = [
    'መስከረም',
    'ጥቅምት',
    'ኅዳር',
    'ታኅሳስ',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዝያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'ጳጉሜ',
  ];

  static String monthName(int month) {
    if (month < 1 || month > monthNames.length) {
      throw RangeError.range(month, 1, monthNames.length, 'month');
    }
    return monthNames[month - 1];
  }

  static EthiopianDate fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    return _fromJdn(jdn);
  }

  static String formatDate(DateTime date) => fromGregorian(date).label;

  static String formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${formatDate(date)} at $hour:$minute';
  }

  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  static EthiopianDate _fromJdn(int jdn) {
    final eraDay = jdn - _ethiopicEpoch;
    final fourYearRemainder = eraDay % 1461;
    final dayOfYear =
        (fourYearRemainder % 365) + 365 * (fourYearRemainder ~/ 1460);
    final year =
        4 * (eraDay ~/ 1461) +
        (fourYearRemainder ~/ 365) -
        (fourYearRemainder ~/ 1460);
    final month = dayOfYear ~/ 30 + 1;
    final day = dayOfYear % 30 + 1;
    return EthiopianDate(year, month, day);
  }
}
