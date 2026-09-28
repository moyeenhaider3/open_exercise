// SPDX-License-Identifier: AGPL-3.0-or-later

/// Formatting and date helpers ported from openGym format.js.
///
/// Display and presentation only — no domain math. JS-04 does not apply.
library;

import 'dart:math';

import '../i18n/t.dart';
import '../models/gym_state.dart';

// Ported from ../openGym/frontend/src/lib/format.js:todayISO
String todayIso() {
  final DateTime now = DateTime.now();
  final String y = now.year.toString().padLeft(4, '0');
  final String m = now.month.toString().padLeft(2, '0');
  final String d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

// Ported from ../openGym/frontend/src/lib/format.js:isoOf
String isoOf(DateTime d) {
  final String y = d.year.toString().padLeft(4, '0');
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

// Ported from ../openGym/frontend/src/lib/format.js:DAYN
const List<String> kDayNames = <String>[
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

// Ported from ../openGym/frontend/src/lib/format.js:DAYS
const List<String> kDayShort = <String>[
  'Su',
  'Mo',
  'Tu',
  'We',
  'Th',
  'Fr',
  'Sa',
];

// Ported from ../openGym/frontend/src/lib/format.js:MONTHS
const List<String> kMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// Ported from ../openGym/frontend/src/lib/format.js:MONTHS_LONG
const List<String> kMonthsLong = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _kEnGbMonthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sept',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _kEnGbWeekdaysShort = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

// Ported from ../openGym/frontend/src/lib/format.js:fmtDate
String fmtDate(String iso, {bool long = false, bool withYear = false}) {
  final DateTime d = DateTime.parse('${iso}T12:00:00');
  final String day = d.day.toString();
  final String month = _kEnGbMonthsShort[d.month - 1];
  final String weekday = _kEnGbWeekdaysShort[d.weekday - 1];
  final String year = d.year.toString();

  if (long && withYear) {
    return '$weekday, $day $month $year';
  } else if (long) {
    return '$weekday $day $month';
  } else if (withYear) {
    return '$day $month $year';
  } else {
    return '$day $month';
  }
}

// Ported from ../openGym/frontend/src/lib/format.js:fmtDur
String fmtDur(int ms) {
  final int m = ms ~/ 60000;
  return m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '$m min';
}

// Ported from ../openGym/frontend/src/lib/format.js:durPart
List<String> durPart(int ms) =>
    ms >= 60000 ? <String>[fmtDur(ms)] : const <String>[];

// Ported from ../openGym/frontend/src/lib/format.js:capWords
String capWords(String? s) {
  if (s == null || s.isEmpty) return '';
  return s.replaceAllMapped(
    RegExp(r'(^|[\s(\-\/])(\p{Ll})', unicode: true),
    (Match m) => '${m[1]}${m[2]!.toUpperCase()}',
  );
}

int _decimals = 1;

// Ported from ../openGym/frontend/src/lib/format.js:setWeightDecimals
void setWeightDecimals(int n) {
  _decimals = n == 2 ? 2 : 1;
}

// Ported from ../openGym/frontend/src/lib/format.js:weightDecimals
int weightDecimals() => _decimals;

String _addCommas(String intStr) {
  final bool isNeg = intStr.startsWith('-');
  final String digits = isNeg ? intStr.substring(1) : intStr;
  final StringBuffer sb = StringBuffer();
  final int len = digits.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) {
      sb.write(',');
    }
    sb.write(digits[i]);
  }
  return isNeg ? '-$sb' : sb.toString();
}

// Ported from ../openGym/frontend/src/lib/format.js:fmtNum
String fmtNum(num n) {
  if (n.isNaN) return 'NaN';
  if (n == double.infinity) return '∞';
  if (n == double.negativeInfinity) return '-∞';

  final int p = _decimals == 2 ? 100 : 10;
  // JavaScript Math.round semantics: Math.floor(n * p + 0.5) / p
  final double scaled = n.toDouble() * p;
  final double rounded = (scaled + 0.5).floorToDouble();
  final double val = rounded / p;

  final bool isNegZero = (n < 0 || (n == 0 && 1 / n < 0)) && val == 0.0;
  if (isNegZero) return '-0';

  final bool isNegative = val < 0;
  final double absVal = val.abs();

  final String fixed = absVal.toStringAsFixed(_decimals);
  final List<String> parts = fixed.split('.');
  final String intPart = _addCommas(parts[0]);

  if (parts.length > 1) {
    String fracPart = parts[1];
    while (fracPart.endsWith('0')) {
      fracPart = fracPart.substring(0, fracPart.length - 1);
    }
    final String sign = isNegative ? '-' : '';
    if (fracPart.isEmpty) {
      return '$sign$intPart';
    }
    return '$sign$intPart.$fracPart';
  }

  return isNegative ? '-$intPart' : intPart;
}

// Ported from ../openGym/frontend/src/lib/format.js:fmtVol
String fmtVol(num v, String unit) => '${fmtNum(v)} $unit';

// Ported from ../openGym/frontend/src/lib/format.js:exCount
String exCount(int n) =>
    t(n == 1 ? '{0} exercise' : '{0} exercises', <Object?>[n]);

// Ported from ../openGym/frontend/src/lib/format.js:routineCount
String routineCount(int n) =>
    t(n == 1 ? '{0} routine' : '{0} routines', <Object?>[n]);

// Ported from ../openGym/frontend/src/lib/format.js:MONDAY
const int kMonday = 1;

// Ported from ../openGym/frontend/src/lib/format.js:SUNDAY
const int kSunday = 0;

// Ported from ../openGym/frontend/src/lib/format.js:weekStartOf
int weekStartOf(GymState? s) => s?.weekStart == kSunday ? kSunday : kMonday;

// Ported from ../openGym/frontend/src/lib/format.js:weekOrder
List<int> weekOrder([int ws = kMonday]) =>
    List<int>.generate(7, (int i) => (ws + i) % 7);

// Ported from ../openGym/frontend/src/lib/format.js:weekDayOffset
int weekDayOffset(int day, [int ws = kMonday]) => (day - ws + 7) % 7;

// Ported from ../openGym/frontend/src/lib/format.js:startOfWeek
DateTime startOfWeek(String iso, [int ws = kMonday]) {
  final DateTime d = DateTime.parse('${iso}T12:00:00');
  final int jsDay = d.weekday % 7;
  final int offset = weekDayOffset(jsDay, ws);
  return DateTime(d.year, d.month, d.day - offset, 12);
}

// Ported from ../openGym/frontend/src/lib/format.js:weekKey
String weekKey(String iso, [int ws = kMonday]) => isoOf(startOfWeek(iso, ws));

final Random _rnd = Random();

// Ported from ../openGym/frontend/src/lib/format.js:uid
String uid() {
  final int now = DateTime.now().millisecondsSinceEpoch;
  final String timePart = now.toRadixString(36);
  const String chars = '0123456789abcdefghijklmnopqrstuvwxyz';
  final StringBuffer buf = StringBuffer(timePart);
  for (int i = 0; i < 5; i++) {
    buf.write(chars[_rnd.nextInt(36)]);
  }
  return buf.toString();
}

// Ported from ../openGym/frontend/src/lib/format.js:ACCENTS
const Map<String, String> kAccents = <String, String>{
  'lime': '#30d158',
  'sky': '#0a84ff',
  'orange': '#ff9f0a',
  'violet': '#bf5af2',
  'pink': '#ff375f',
  'red': '#ff453a',
  'teal': '#40c8e0',
  'gold': '#ffd60a',
};
