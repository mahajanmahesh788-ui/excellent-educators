import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats ISO dates as dd-Mon-yyyy', () {
    expect(formatDisplayDate('2026-01-28'), '28-Jan-2026');
    expect(formatDisplayDate('2026-09-02'), '02-Sep-2026');
  });

  test('formats ISO timestamps as dd-Mon-yyyy hh:mm AM/PM', () {
    expect(
      formatDisplayDateTime('2026-09-02T06:33:25.000000Z'),
      matches(RegExp(r'^\d{2}-[A-Z][a-z]{2}-\d{4} \d{2}:\d{2} (AM|PM)$')),
    );
    expect(
      formatDisplayDate('2026-09-02T06:33:25.000000Z'),
      matches(RegExp(r'^\d{2}-[A-Z][a-z]{2}-\d{4} \d{2}:\d{2} (AM|PM)$')),
    );
  });

  test('returns fallback for empty values', () {
    expect(formatDisplayDateTime(null), '—');
    expect(formatDisplayDateTime(''), '—');
    expect(formatDisplayDate(null), '—');
  });
}
