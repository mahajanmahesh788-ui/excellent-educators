/// Formats API date strings for display as `dd-mm-yyyy`.
String formatDisplayDate(String? raw, {String fallback = '—'}) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }

  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day-$month-$year';
}

/// Formats API timestamps for display as `dd-mm-yyyy hh:mm AM/PM`.
String formatDisplayDateTime(String? raw, {String fallback = '—'}) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }

  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final minute = local.minute.toString().padLeft(2, '0');
  final hour24 = local.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final hour = hour12.toString().padLeft(2, '0');

  return '$day-$month-$year $hour:$minute $period';
}
