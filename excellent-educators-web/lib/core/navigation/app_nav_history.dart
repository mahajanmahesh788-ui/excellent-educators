import 'package:excellent_educators_web/app/router/route_paths.dart';

/// In-app navigation stack so Back walks A ← B ← C even when routes use `go()`.
///
/// Shell/tab destinations reset the stack. Detail routes append.
class AppNavHistory {
  AppNavHistory._();

  static final AppNavHistory instance = AppNavHistory._();

  final List<String> _stack = <String>[];

  /// Top-level sidebar / bottom-nav destinations (replace history).
  static const Set<String> shellDestinations = {
    RoutePaths.login,
    RoutePaths.forgotPassword,
    RoutePaths.resetPassword,
    RoutePaths.session,
    RoutePaths.adminDashboard,
    RoutePaths.adminAgentDashboard,
    RoutePaths.adminStudents,
    RoutePaths.adminTeachers,
    RoutePaths.adminBatches,
    RoutePaths.adminAttendance,
    RoutePaths.adminLeaves,
    RoutePaths.adminAssessments,
    RoutePaths.adminPayments,
    RoutePaths.adminSettings,
    RoutePaths.adminRequests,
    RoutePaths.adminSubAdmins,
    RoutePaths.adminNotifications,
    RoutePaths.adminSchedule,
    RoutePaths.adminLoginPage,
    RoutePaths.masterTeacherDashboard,
    RoutePaths.masterTeacherStudents,
    RoutePaths.teacherBatches,
    RoutePaths.teacherSchedule,
    RoutePaths.teacherDaySchedule,
    RoutePaths.teacherProfile,
    RoutePaths.teacherRequests,
    RoutePaths.teacherNotifications,
    RoutePaths.studentDashboard,
    RoutePaths.studentAcceptTerms,
    RoutePaths.studentBookings,
    RoutePaths.studentJournal,
    RoutePaths.studentFeedback,
    RoutePaths.studentRequests,
    RoutePaths.studentProfile,
    RoutePaths.studentPayments,
    RoutePaths.studentNotifications,
  };

  List<String> get stack => List.unmodifiable(_stack);

  bool get canGoBack => _stack.length > 1;

  String? get current => _stack.isEmpty ? null : _stack.last;

  String? get previous => canGoBack ? _stack[_stack.length - 2] : null;

  static String normalize(String location) {
    final uri = Uri.parse(location);
    final path = uri.path.isEmpty ? '/' : uri.path;
    if (uri.hasQuery && uri.query.isNotEmpty) {
      return '$path?${uri.query}';
    }
    return path;
  }

  static bool isShellDestination(String location) {
    return shellDestinations.contains(normalize(location).split('?').first);
  }

  /// Keep the stack aligned with the current router location.
  void track(String location) {
    final normalized = normalize(location);
    if (normalized.isEmpty || normalized == '/') {
      return;
    }

    if (_stack.isNotEmpty && _stack.last == normalized) {
      return;
    }

    // Menu / shell screens always become the sole root — never keep details
    // (or prior menus) behind them for Back.
    if (isShellDestination(normalized)) {
      _stack
        ..clear()
        ..add(normalized);
      return;
    }

    // Returning to an earlier detail screen — truncate forward entries.
    final existing = _stack.lastIndexOf(normalized);
    if (existing >= 0) {
      _stack.removeRange(existing + 1, _stack.length);
      return;
    }

    if (_stack.isEmpty) {
      _stack.add(normalized);
      return;
    }

    _stack.add(normalized);
  }

  /// Removes the current screen and returns the previous location to open.
  String? takeBackTarget() {
    if (!canGoBack) {
      return null;
    }
    _stack.removeLast();
    return _stack.last;
  }

  /// Drop the current entry without navigating (used when returning to a parent
  /// after submit when the route was not opened via push).
  void discardCurrent() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  void clear() => _stack.clear();
}
