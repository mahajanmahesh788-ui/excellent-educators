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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[month - 1]} $year';
  }
}
