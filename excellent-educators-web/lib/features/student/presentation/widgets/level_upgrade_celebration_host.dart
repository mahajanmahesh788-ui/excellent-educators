import 'dart:async';

import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_toast_controller.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/data/level_upgrade_celebration_store.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/level_upgrade_celebration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final levelUpgradeCelebrationStoreProvider =
    Provider<LevelUpgradeCelebrationStore>((ref) {
  return LevelUpgradeCelebrationStore();
});

/// Shows the level-upgrade celebration once per `student_promoted` notification.
class LevelUpgradeCelebrationHost extends ConsumerStatefulWidget {
  const LevelUpgradeCelebrationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LevelUpgradeCelebrationHost> createState() =>
      _LevelUpgradeCelebrationHostState();
}

class _LevelUpgradeCelebrationHostState
    extends ConsumerState<LevelUpgradeCelebrationHost> {
  var _showing = false;
  final _handledIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = ref.read(notificationsProvider).asData?.value;
      if (items != null) {
        unawaited(_considerNotifications(items));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<UserNotificationDto>>>(
      notificationsProvider,
      (previous, next) {
        next.whenData((items) => unawaited(_considerNotifications(items)));
      },
    );

    ref.listen<NotificationToastController>(
      notificationToastControllerProvider,
      (previous, next) {
        final promoted = next.toasts
            .map((item) => item.notification)
            .where((n) => n.type == 'student_promoted')
            .toList();
        if (promoted.isNotEmpty) {
          unawaited(_considerNotifications(promoted));
        }
      },
    );

    return widget.child;
  }

  Future<void> _considerNotifications(
    List<UserNotificationDto> notifications,
  ) async {
    if (!mounted || _showing) {
      return;
    }

    UserNotificationDto? candidate;
    for (final item in notifications) {
      if (item.type != 'student_promoted') {
        continue;
      }
      if (!item.isUnread) {
        continue;
      }
      if (_handledIds.contains(item.id)) {
        continue;
      }
      candidate = item;
      break;
    }
    if (candidate == null) {
      return;
    }

    final store = ref.read(levelUpgradeCelebrationStoreProvider);
    if (await store.hasSeen(candidate.id)) {
      _handledIds.add(candidate.id);
      return;
    }

    _handledIds.add(candidate.id);
    _showing = true;

    // Drop matching toast so the celebration owns the moment.
    ref.read(notificationToastControllerProvider).dismiss(candidate.id);

    final toLevel = _stringData(candidate, 'to_level');
    final fromLevel = _stringData(candidate, 'from_level');
    final resolvedTo =
        (toLevel == null || toLevel.isEmpty) ? AppStrings.yourNextLevel : toLevel;

    if (!mounted) {
      _showing = false;
      return;
    }

    try {
      await LevelUpgradeCelebrationDialog.show(
        context,
        toLevel: resolvedTo,
        fromLevel: fromLevel,
      );
    } finally {
      await _markConsumed(candidate.id);
      if (mounted) {
        _showing = false;
      }
    }
  }

  Future<void> _markConsumed(String notificationId) async {
    final store = ref.read(levelUpgradeCelebrationStoreProvider);
    await store.markSeen(notificationId);
    try {
      await ref.read(notificationRepositoryProvider).markRead(notificationId);
    } catch (_) {
      // Local markSeen already prevents repeat popups.
    }
    // Refresh dashboard so the new level/journey shows without a manual reload.
    _refreshStudentDashboard();
  }

  void _refreshStudentDashboard() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(studentProfileProvider);
    ref.invalidate(studentLearningDashboardProvider);
    ref.invalidate(studentLearningJournalProvider);
    ref.invalidate(studentAssessmentProvider);
    ref.invalidate(studentEligibilityProvider);
    ref.invalidate(studentBookingsProvider);
  }

  String? _stringData(UserNotificationDto notification, String key) {
    final raw = notification.data?[key];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return null;
  }
}
