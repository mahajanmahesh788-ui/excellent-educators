import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            onTap: () => _markRead(context, ref, items[index]),
          ),
        );
      },
    );

    final actions = [
      TextButton(
        onPressed: () => _markAllRead(context, ref),
        child: const Text(AppStrings.markAllRead, style: TextStyle(color: Colors.white)),
      ),
    ];

    if (user?.isStudent ?? false) {
      return StudentScaffold(title: AppStrings.notifications, body: body, actions: actions);
    }

    return AppScaffold(title: AppStrings.notifications, body: body, actions: actions);
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
      'master_teacher_assigned' || 'master_teacher_changed' => Icons.psychology_alt_rounded,
      'common_teacher_assigned' || 'common_teacher_changed' => Icons.person_outline,
      'student_enrolled_in_batch' || 'student_unenrolled_from_batch' => Icons.groups_rounded,
      'student_booking_failed' => Icons.warning_amber_rounded,
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

