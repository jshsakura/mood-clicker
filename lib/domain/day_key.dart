/// A calendar day in the device time zone. It changes at local midnight.
class DayKey implements Comparable<DayKey> {
  const DayKey._(this.year, this.month, this.day);

  factory DayKey.of(DateTime instant) {
    final local = instant.isUtc ? instant.toLocal() : instant;
    return DayKey._(local.year, local.month, local.day);
  }

  final int year;
  final int month;
  final int day;

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Null unless the text is a real date written as `YYYY-MM-DD`.
  static DayKey? tryParse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final y = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    final d = int.parse(match[3]!);
    // A calendar check in UTC, which has no gaps. Local midnight may not exist on a day a time
    // zone skipped, and that must not make a real calendar date look impossible.
    final check = DateTime.utc(y, m, d);
    if (check.year != y || check.month != m || check.day != d) return null;
    return DayKey._(y, m, d);
  }

  @override
  int compareTo(DayKey other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator <(DayKey other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is DayKey &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
