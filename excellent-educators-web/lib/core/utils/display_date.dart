import 'package:excellent_educators_web/core/constants/app_strings.dart';

const _monthLabels = <String>[
  AppStrings.jan2,
  AppStrings.feb2,
  AppStrings.mar2,
  AppStrings.apr2,
  AppStrings.may2,
  AppStrings.jun2,
  AppStrings.jul2,
  AppStrings.aug2,
  AppStrings.sep2,
  AppStrings.oct2,
  AppStrings.nov2,
  AppStrings.dec2,
];

String _monthLabel(int month) {
  if (month < 1 || month > 12) {
    return month.toString().padLeft(2, '0');
  }
  return _monthLabels[month - 1];
}

/// Formats API date strings for display as `dd-Mon-yyyy` or `dd-Mon-yyyy hh:mm AM/PM` if time is present.
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
  final month = _monthLabel(local.month);
  final year = local.year.toString();

  final hasTime = raw.contains('T') ||
      raw.contains(':') ||
      local.hour != 0 ||
      local.minute != 0;
  if (!hasTime) {
    return '$day-$month-$year';
  }

  final minute = local.minute.toString().padLeft(2, '0');
  final hour24 = local.hour;
  final period = hour24 >= 12 ? AppStrings.pm : AppStrings.am;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final hour = hour12.toString().padLeft(2, '0');

  return '$day-$month-$year $hour:$minute $period';
}

/// Formats API timestamps for display as `dd-Mon-yyyy hh:mm AM/PM`.
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
  final month = _monthLabel(local.month);
  final year = local.year.toString();
  final minute = local.minute.toString().padLeft(2, '0');
  final hour24 = local.hour;
  final period = hour24 >= 12 ? AppStrings.pm : AppStrings.am;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final hour = hour12.toString().padLeft(2, '0');

  return '$day-$month-$year $hour:$minute $period';
}
