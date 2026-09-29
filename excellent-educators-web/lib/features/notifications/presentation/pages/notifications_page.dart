import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final user = ref.watch(authControllerProvider).user;
    final body = AsyncBody(
      value: notifications,
      onRetry: () => ref.invalidate(notificationsProvider),
      builder: (items) {
        if (items.isEmpty) {
          final emptyMessage = (user?.isAdmin ?? false)
              ? 'No notifications yet. Booking and system alerts will show up here.'
              : AppStrings.noNotificationsYetUpdatesAboutYourTeachersAndBatchWill;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Brand.muted, height: 1.45),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: user?.isStudent ?? false,
          physics: (user?.isStudent ?? false) ? const NeverScrollableScrollPhysics() : null,
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _NotificationTile(
            notification: items[index],
            onTap: () => _openNotification(context, ref, items[index]),
          ),
        );
      },
    );

    final actions = [
      if ((user?.isAdmin ?? false) &&
          !user!.isAgent &&
          user.canAdmin(AdminPermission.settingsManage))
        TextButton(
          onPressed: () => _composeBroadcast(context, ref),
          child: Text(
            AppStrings.broadcastAnnouncement,
            style: TextStyle(
              color: (user.isStudent)
                  ? StudentColors.indigoPrimary
                  : Colors.white,
            ),
          ),
        ),
      TextButton(
        onPressed: () => _markAllRead(context, ref),
        child: Text(
          AppStrings.markAllRead,
          style: TextStyle(
            color: (user?.isStudent ?? false)
                ? StudentColors.indigoPrimary
                : Colors.white,
          ),
        ),
      ),
    ];

    if (user?.isStudent ?? false) {
      return StudentScaffold(
        title: AppStrings.notifications,
        body: body,
        actions: actions,
        backTo: RoutePaths.studentDashboard,
      );
    }

    final backTo = (user?.isMasterTeacher ?? false)
        ? RoutePaths.masterTeacherDashboard
        : (user?.isCommonTeacher ?? false)
            ? RoutePaths.teacherDaySchedule
            : RoutePaths.adminDashboard;

    return AppScaffold(
      title: AppStrings.notifications,
      body: body,
      actions: actions,
      backTo: backTo,
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    UserNotificationDto notification,
  ) async {
    await _markRead(context, ref, notification);
    if (!context.mounted) return;

    final groupId = notification.data?['leave_request_group_id'] as String?;
    if ((notification.type == 'teacher_leave_submitted' ||
            notification.type == 'teacher_leave_cancelled') &&
        groupId != null &&
        groupId.isNotEmpty) {
      context.go(RoutePaths.adminLeaveRequest(groupId));
      return;
    }

    final link = notification.data?['link'] as String?;
    if (link != null && link.isNotEmpty) {
      if (link.startsWith('/admin/leaves/') ||
          link.startsWith('/admin/schedule/leave-requests/')) {
        final leaveGroupId = link.split('/').last;
        if (leaveGroupId.isNotEmpty) {
          context.go(RoutePaths.adminLeaveRequest(leaveGroupId));
        }
        return;
      }
      if (link.startsWith('/admin/attendance/')) {
        final issueId = link.split('/').last;
        if (issueId.isNotEmpty) {
          context.go(RoutePaths.adminAttendanceIssue(issueId));
        } else {
          context.go(RoutePaths.adminAttendance);
        }
        return;
      }
      if (link == '/student/payments') {
        context.go(RoutePaths.studentPayments);
        return;
      }
      if (link == '/student/bookings') {
        context.go(RoutePaths.studentBookings);
        return;
      }
      if (link == '/student/dashboard') {
        context.go(RoutePaths.studentDashboard);
        return;
      }
      if (link.startsWith('/teacher/schedule')) {
        context.go(RoutePaths.teacherDaySchedule);
        return;
      }
    }

    if (notification.type == 'session_booked' ||
        notification.type == 'session_rescheduled' ||
        notification.type == 'session_cancelled' ||
        notification.type == 'teacher_leave_approved' ||
        notification.type == 'teacher_leave_rejected' ||
        notification.type == 'teacher_leave_cancelled') {
      final user = ref.read(authControllerProvider).user;
      if ((user?.isCommonTeacher ?? false) || (user?.isMasterTeacher ?? false)) {
        context.go(RoutePaths.teacherDaySchedule);
      } else if (user?.isStudent ?? false) {
        context.go(RoutePaths.studentBookings);
      }
      return;
    }

    if (notification.type == 'payment_recorded' ||
        notification.type == 'payment_voided') {
      context.go(RoutePaths.studentPayments);
      return;
    }

    if (notification.type == 'attendance_conflict_reported') {
      final issueId = notification.data?['issue_id'] as String?;
      if (issueId != null && issueId.isNotEmpty) {
        context.go(RoutePaths.adminAttendanceIssue(issueId));
      } else {
        context.go(RoutePaths.adminAttendance);
      }
      return;
    }

    if (notification.type == 'attendance_conflict_resolved') {
      final user = ref.read(authControllerProvider).user;
      if (user?.isStudent ?? false) {
        context.go(RoutePaths.studentBookings);
      } else if ((user?.isCommonTeacher ?? false) ||
          (user?.isMasterTeacher ?? false)) {
        context.go(RoutePaths.teacherDaySchedule);
      }
      return;
    }

    if (notification.type == 'student_promoted' ||
        notification.type == 'aptitude_assessment_available') {
      context.go(RoutePaths.studentDashboard);
    }
  }

  Future<void> _markRead(BuildContext context, WidgetRef ref, UserNotificationDto notification) async {
    if (!notification.isUnread) {
      return;
    }
    try {
      await ref.read(notificationRepositoryProvider).markRead(notification.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _composeBroadcast(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    var audience = 'students';
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(AppStrings.broadcastAnnouncement),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: AppStrings.title),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: AppStrings.description),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(
                    labelText: AppStrings.announcementAudience,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'students',
                      child: Text(AppStrings.audienceStudents),
                    ),
                    DropdownMenuItem(
                      value: 'teachers',
                      child: Text(AppStrings.audienceTeachers),
                    ),
                    DropdownMenuItem(
                      value: 'all_users',
                      child: Text(AppStrings.audienceAllUsers),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => audience = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.sendAnnouncement),
            ),
          ],
        ),
      ),
    );
    if (sent != true) {
      return;
    }
    try {
      final count = await ref.read(notificationRepositoryProvider).broadcast(
            title: titleCtrl.text.trim(),
            body: bodyCtrl.text.trim(),
            audience: audience,
          );
      ref.invalidate(notificationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent to $count recipient(s).')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final UserNotificationDto notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatDateTime(notification.createdAt);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: notification.isUnread ? Brand.gold.withValues(alpha: 0.18) : const Color(0xFFECEFF3),
        child: Icon(
          _iconFor(notification.type),
          color: notification.isUnread ? Brand.goldDark : Brand.muted,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(notification.body, style: const TextStyle(height: 1.4)),
          if (formatted.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(formatted, style: const TextStyle(fontSize: 12, color: Brand.muted)),
          ],
        ],
      ),
      isThreeLine: true,
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

String _formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) {
    return '';
  }
  final dt = DateTime.parse(iso).toLocal();
  const months = [AppStrings.jan2, AppStrings.feb2, AppStrings.mar2, AppStrings.apr2, AppStrings.may2, AppStrings.jun2, AppStrings.jul2, AppStrings.aug2, AppStrings.sep2, AppStrings.oct2, AppStrings.nov2, AppStrings.dec2];
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final amPm = dt.hour >= 12 ? AppStrings.pm : AppStrings.am;
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $amPm';
}

