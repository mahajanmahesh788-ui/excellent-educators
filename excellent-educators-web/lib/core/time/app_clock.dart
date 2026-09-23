import 'package:excellent_educators_web/core/constants/app_strings.dart';
/// App-wide calendar helpers using Asia/Kolkata (IST).
class AppClock {
  AppClock._();

  static const _istOffset = Duration(hours: 5, minutes: 30);

  static DateTime now() => DateTime.now().toUtc().add(_istOffset);

  static ({int year, int month}) currentYearMonth() {
    final ist = now();
    return (year: ist.year, month: ist.month);
  }

  static String todayString() {
    final ist = now();
    return '${ist.year.toString().padLeft(4, '0')}-'
        '${ist.month.toString().padLeft(2, '0')}-'
        '${ist.day.toString().padLeft(2, '0')}';
  }

  static String monthLabel(int year, int month) {
    const names = [
      AppStrings.january, AppStrings.february, AppStrings.march, AppStrings.april, AppStrings.may2, AppStrings.june,
      AppStrings.july, AppStrings.august, AppStrings.september, AppStrings.october, AppStrings.november, AppStrings.december,
    ];
    return '${names[month - 1]} $year';
  }
}
