import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/assessment_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/content/presentation/providers/site_page_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/requests/presentation/providers/request_feature_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/settings/presentation/providers/settings_providers.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Host that collects per-screen refresh handlers (e.g. from [AsyncBody]).
class AppRefreshHost extends StatefulWidget {
  const AppRefreshHost({super.key, required this.child});

  final Widget child;

  static AppRefreshHostState of(BuildContext context) {
    final state = context.findAncestorStateOfType<AppRefreshHostState>();
    assert(state != null, 'AppRefreshHost not found in the widget tree');
    return state!;
  }

  static AppRefreshHostState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AppRefreshHostState>();
  }

  @override
  State<AppRefreshHost> createState() => AppRefreshHostState();
}

class AppRefreshHostState extends State<AppRefreshHost> {
  final _handlers = <Object, Future<void> Function()>{};

  void register(Object key, Future<void> Function() handler) {
    _handlers[key] = handler;
  }

  void unregister(Object key) {
    _handlers.remove(key);
  }

  Future<void> refresh({Future<void> Function()? fallback}) async {
    final handlers = _handlers.values.toList(growable: false);
    if (handlers.isNotEmpty) {
      await Future.wait(handlers.map((handler) => handler()));
      return;
    }
    if (fallback != null) {
      await fallback();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Registers a refresh callback with the nearest [AppRefreshHost].
class AppRefreshRegistrar extends StatefulWidget {
  const AppRefreshRegistrar({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<AppRefreshRegistrar> createState() => _AppRefreshRegistrarState();
}

class _AppRefreshRegistrarState extends State<AppRefreshRegistrar> {
  final _key = Object();
  AppRefreshHostState? _host;

  void _sync() {
    _host?.unregister(_key);
    _host = AppRefreshHost.maybeOf(context);
    _host?.register(_key, widget.onRefresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant AppRefreshRegistrar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _host?.unregister(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pull / swipe-down to reload. Works with nested scrollables and on web/desktop.
class AppPullToRefresh extends StatelessWidget {
  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double edgeOffset;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _AppRefreshScrollBehavior(),
      child: RefreshIndicator(
        edgeOffset: edgeOffset,
        displacement: 48,
        // depth == 0 only — accepting every nested scroll notification
        // caused an infinite notification loop (Stack Overflow).
        onRefresh: onRefresh,
        child: child,
      ),
    );
  }
}

class _AppRefreshScrollBehavior extends MaterialScrollBehavior {
  const _AppRefreshScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        // Mouse drag enables pull-to-refresh in Flutter web / desktop.
        if (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)
          PointerDeviceKind.mouse,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Keep platform physics; only ensure short lists can still overscroll to refresh.
    return AlwaysScrollableScrollPhysics(
      parent: super.getScrollPhysics(context),
    );
  }
}

/// Path-based provider invalidation when a screen has no registered handlers.
abstract final class ScreenRefresh {
  static Future<void> refresh(WidgetRef ref, String path) async {
    final uri = Uri.tryParse(path);
    final location = uri?.path ?? path;

    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);

    if (location.startsWith('/student')) {
      _refreshStudent(ref, location);
    } else if (location.startsWith('/teacher') ||
        location.startsWith('/master-teacher')) {
      _refreshTeacher(ref, location);
    } else if (location.startsWith('/admin')) {
      _refreshAdmin(ref, location);
    }

    // Give FutureProviders a moment to start reloading so the indicator feels real.
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  static void _refreshStudent(WidgetRef ref, String path) {
    ref.invalidate(studentProfileProvider);
    ref.invalidate(studentAssessmentProvider);
    ref.invalidate(studentEligibilityProvider);
    ref.invalidate(studentBookingsProvider);
    ref.invalidate(studentBookingTeachersProvider);
    ref.invalidate(studentLearningDashboardProvider);
    ref.invalidate(studentLearningJournalProvider);
    ref.invalidate(studentOwnPaymentsProvider);
    ref.invalidate(studentRequestsProvider);
    ref.invalidate(studentFeedbackProvider);
    ref.invalidate(studentFeedbackSummaryProvider);
    ref.invalidate(studentAvailabilityProvider);

    if (path.contains('/journal')) {
      ref.invalidate(studentLearningWeekProvider);
    }
    if (path.contains('/mentors/') || path.contains('/teachers')) {
      ref.invalidate(studentBookingTeachersProvider);
    }
  }

  static void _refreshTeacher(WidgetRef ref, String path) {
    ref.invalidate(teacherProfileProvider);
    ref.invalidate(teacherBatchesProvider);
    ref.invalidate(teacherBatchStudentsProvider);
    ref.invalidate(teacherDayProvider);
    ref.invalidate(teacherDayScheduleProvider);
    ref.invalidate(teacherBookingsHistoryProvider);
    ref.invalidate(teacherLeavesProvider);
    ref.invalidate(teacherRequestsProvider);
    ref.invalidate(masterTeacherStudentsProvider);
    ref.invalidate(masterTeacherDashboardProvider);
    ref.invalidate(teacherBatchAssessmentsProvider);
    ref.invalidate(teacherAssessmentProvider);
    ref.invalidate(teacherAssessmentScoresProvider);
    ref.invalidate(teacherLearningJournalProvider);
    ref.invalidate(masterTeacherLearningJournalProvider);
    ref.invalidate(teacherStudentProvider);
    ref.invalidate(teacherStudentFeedbackProvider);
    ref.invalidate(teacherStudentFeedbackSummaryProvider);
    ref.invalidate(teacherStudentResultsProvider);
    ref.invalidate(masterTeacherStudentProvider);
    ref.invalidate(masterTeacherStudentFeedbackProvider);
    ref.invalidate(masterTeacherStudentFeedbackSummaryProvider);
    ref.invalidate(masterTeacherStudentResultsProvider);
    ref.invalidate(masterTeacherFeedbackCatalogProvider);
  }

  static void _refreshAdmin(WidgetRef ref, String path) {
    ref.invalidate(adminPendingConflictsCountProvider);
    ref.invalidate(adminDashboardProvider);
    ref.invalidate(agentDashboardProvider);
    ref.invalidate(adminStudentsProvider);
    ref.invalidate(adminTeachersProvider);
    ref.invalidate(adminLevelsProvider);
    ref.invalidate(adminLevelProvider);
    ref.invalidate(adminBatchProvider);
    ref.invalidate(adminBatchStudentsProvider);
    ref.invalidate(adminStudentProvider);
    ref.invalidate(adminStudentHistoryProvider);
    ref.invalidate(adminTeacherProvider);
    ref.invalidate(adminTeacherDashboardProvider);
    ref.invalidate(adminTeacherHistoryProvider);
    ref.invalidate(adminTeacherPromotedProvider);
    ref.invalidate(adminSubAdminsProvider);
    ref.invalidate(adminSubAdminProvider);
    ref.invalidate(adminSubAdminHistoryProvider);
    ref.invalidate(subAdminPermissionCatalogProvider);
    ref.invalidate(adminScheduleTeachersProvider);
    ref.invalidate(adminScheduleDayProvider);
    ref.invalidate(adminScheduleLeavesProvider);
    ref.invalidate(adminAllLeavesProvider);
    ref.invalidate(adminTeacherLeavesProvider);
    ref.invalidate(adminLeaveRequestProvider);
    ref.invalidate(adminScheduleBookingsProvider);
    ref.invalidate(adminGoogleMeetProvider);
    ref.invalidate(adminTeacherAvailabilityProvider);
    ref.invalidate(adminAttendanceProvider);
    ref.invalidate(adminAssessmentsProvider);
    ref.invalidate(adminAssessmentProvider);
    ref.invalidate(adminAssessmentAttemptsProvider);
    ref.invalidate(adminStudentResultsProvider);
    ref.invalidate(adminStudentFeedbackProvider);
    ref.invalidate(adminStudentFeedbackSummaryProvider);
    ref.invalidate(adminFeedbackCatalogProvider);
    ref.invalidate(adminRequestsProvider);
    ref.invalidate(adminRequestDetailProvider);
    ref.invalidate(paymentListProvider);
    ref.invalidate(adminStudentPaymentPlanProvider);
    ref.invalidate(adminSettingsProvider);
    ref.invalidate(adminSitePagesProvider);
    ref.invalidate(adminLoginPageContentProvider);
    ref.invalidate(adminWeeklyLearningsProvider);
    ref.invalidate(adminLearningJournalProvider);
    ref.invalidate(adminLearningWeekProvider);

    if (path.contains('/weekly-learning') || path.contains('/levels')) {
      ref.invalidate(adminLevelsProvider);
    }
  }
}
