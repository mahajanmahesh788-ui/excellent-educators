import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/notification_icons.dart';
import 'package:excellent_educators_web/features/notifications/presentation/notification_navigation.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
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
    openNotificationDeepLink(
      context,
      notification,
      user: ref.read(authControllerProvider).user,
    );
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
    final formatted = formatDisplayDateTime(notification.createdAt, fallback: '');

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: notification.isUnread ? Brand.gold.withValues(alpha: 0.18) : const Color(0xFFECEFF3),
        child: Icon(
          notificationIconFor(notification.type),
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
}
