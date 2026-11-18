/// Calendar labels built with intl DateFormat, so month names and weekdays
/// follow the locale instead of living in ARB messages.
///
/// Unsupported locales fall back to English, matching the app's locale
/// resolution (see lib/l10n/locale_resolution.dart).
library;

import 'dart:async' show unawaited;
import 'dart:ui' show Locale;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const Set<String> _supportedLanguageCodes = {'ko', 'en', 'ja'};

bool _symbolsLoaded = false;

void _loadDateSymbols() {
  if (_symbolsLoaded) {
    return;
  }
  // The local date symbol table fills in synchronously, so the returned
  // future is already complete when this call returns.
  unawaited(initializeDateFormatting());
  _symbolsLoaded = true;
}

String _code(Locale locale) {
  final code = locale.languageCode;
  return _supportedLanguageCodes.contains(code) ? code : 'en';
}

/// Month title for the calendar header, one label per month page.
String monthTitle(Locale locale, DateTime month) {
  final code = _code(locale);
  _loadDateSymbols();
  final skeleton = code == 'en' ? 'yMMMM' : 'yMMM';
  return DateFormat(skeleton, code).format(month);
}

/// Short weekday labels for the calendar, Sunday first.
List<String> weekdayLabels(Locale locale) {
  final code = _code(locale);
  _loadDateSymbols();
  // 2026-11-01 is a Sunday.
  final sunday = DateTime(2026, 11, 1);
  return List.generate(
    7,
    (i) => DateFormat.E(code).format(sunday.add(Duration(days: i))),
  );
}

/// Date title for the tapped day in the calendar.
String dayTitle(Locale locale, DateTime day) {
  final code = _code(locale);
  _loadDateSymbols();
  return DateFormat.MMMd(code).format(day);
}
