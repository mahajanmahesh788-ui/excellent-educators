import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats ISO timestamps as dd-mm-yyyy hh:mm AM/PM', () {
    expect(
      formatDisplayDateTime('2026-09-02T06:33:25.000000Z'),
      matches(RegExp(r'^\d{2}-\d{2}-\d{4} \d{2}:\d{2} (AM|PM)$')),
    );
  });

  test('returns fallback for empty values', () {
    expect(formatDisplayDateTime(null), '—');
    expect(formatDisplayDateTime(''), '—');
  });
}
