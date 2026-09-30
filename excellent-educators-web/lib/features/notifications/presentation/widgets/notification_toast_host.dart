import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/notification_navigation.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_toast_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationToastHost extends ConsumerWidget {
  const NotificationToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(notificationToastControllerProvider).toasts;

    return Stack(
      children: [
        child,
        if (toasts.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final toast in toasts) ...[
                      _NotificationToastCard(
                        notification: toast.notification,
                        onClose: () => ref
                            .read(notificationToastControllerProvider)
                            .dismiss(toast.id),
                        onOpen: () async {
                          final controller =
                              ref.read(notificationToastControllerProvider);
                          final user = ref.read(authControllerProvider).user;
                          final notification = toast.notification;
                          controller.dismiss(toast.id);
                          if (notification.isUnread) {
                            try {
                              await ref
                                  .read(notificationRepositoryProvider)
                                  .markRead(notification.id);
                              ref.invalidate(unreadNotificationCountProvider);
                              ref.invalidate(notificationsProvider);
                            } catch (_) {
                              // Navigation still proceeds.
                            }
                          }
                          if (!context.mounted) {
                            return;
                          }
                          openNotificationDeepLink(
                            context,
                            notification,
                            user: user,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationToastCard extends StatelessWidget {
  const _NotificationToastCard({
    required this.notification,
    required this.onClose,
    required this.onOpen,
  });

  final UserNotificationDto notification;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 360,
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Brand.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconFor(notification.type),
                  color: Brand.goldDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Brand.muted,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18, color: Brand.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'master_teacher_assigned' ||
      'master_teacher_changed' ||
      'master_teacher_removed' =>
        Icons.psychology_alt_rounded,
      'common_teacher_assigned' ||
      'common_teacher_changed' ||
      'common_teacher_removed' =>
        Icons.person_outline,
      'student_enrolled_in_batch' || 'student_unenrolled_from_batch' =>
        Icons.groups_rounded,
      'student_booking_failed' => Icons.warning_amber_rounded,
      'session_booked' => Icons.event_available_rounded,
      'session_rescheduled' || 'session_mentor_updated' =>
        Icons.event_repeat_rounded,
      'session_cancelled' => Icons.event_busy_rounded,
      'teacher_leave_submitted' ||
      'teacher_leave_approved' ||
      'teacher_leave_rejected' ||
      'teacher_leave_cancelled' =>
        Icons.event_busy_rounded,
      'payment_recorded' || 'payment_voided' => Icons.payments_outlined,
      'attendance_conflict_reported' || 'attendance_conflict_resolved' =>
        Icons.report_outlined,
      'student_promoted' => Icons.school_outlined,
      'aptitude_assessment_available' => Icons.quiz_outlined,
      'admin_announcement' => Icons.campaign_outlined,
      _ => Icons.notifications_outlined,
    };
  }
}
