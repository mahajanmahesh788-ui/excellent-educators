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

enum _NotificationFilter { all, unread }

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 30,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final unreadCount = items.where((n) => n.isUnread).length;
        final filteredItems = _selectedFilter == _NotificationFilter.unread
            ? items.where((n) => n.isUnread).toList()
            : items;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 20,
                    vertical: isMobile ? 14 : 20,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Toolbar: Filter Segment + Mark All Read + Admin Broadcast
                    _buildToolbar(
                      totalCount: items.length,
                      unreadCount: unreadCount,
                      canBroadcast: (user?.isAdmin ?? false) &&
                          !user!.isAgent &&
                          user.canAdmin(AdminPermission.settingsManage),
                    ),
                    const SizedBox(height: 12),

                    // Card container with notifications
                    if (filteredItems.isEmpty)
                      _buildAllCaughtUpState()
                    else
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < filteredItems.length; i++) ...[
                              _NotificationTile(
                                key: ValueKey(filteredItems[i].id),
                                notification: filteredItems[i],
                                onTap: () => _openNotification(context, ref, filteredItems[i]),
                                onMarkRead: filteredItems[i].isUnread
                                    ? () => _markRead(context, ref, filteredItems[i])
                                    : null,
                              ),
                              if (i < filteredItems.length - 1)
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
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

  Widget _buildToolbar({
    required int totalCount,
    required int unreadCount,
    required bool canBroadcast,
  }) {
    return Row(
      children: [
        // Filter tabs (All | Unread)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterTab(
                label: 'All',
                count: totalCount,
                isSelected: _selectedFilter == _NotificationFilter.all,
                onTap: () => setState(() => _selectedFilter = _NotificationFilter.all),
              ),
              const SizedBox(width: 2),
              _FilterTab(
                label: 'Unread',
                count: unreadCount,
                hasHighlight: unreadCount > 0,
                isSelected: _selectedFilter == _NotificationFilter.unread,
                onTap: () => setState(() => _selectedFilter = _NotificationFilter.unread),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Quick "Mark all as read"
        if (unreadCount > 0)
          TextButton.icon(
            onPressed: () => _markAllRead(context, ref),
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text(
              AppStrings.markAllRead,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        if (canBroadcast) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _composeBroadcast(context, ref),
            icon: const Icon(Icons.campaign_outlined, size: 16),
            label: const Text(
              AppStrings.broadcastAnnouncement,
              style: TextStyle(fontSize: 12.5),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF03162B),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAllCaughtUpState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_all_rounded,
              size: 24,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You have no unread notifications.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => setState(() => _selectedFilter = _NotificationFilter.all),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            child: const Text('View all notifications'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    UserNotificationDto notification,
  ) async {
    if (notification.isUnread) {
      await _markRead(context, ref, notification);
    }
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

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.hasHighlight = false,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasHighlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: hasHighlight && !isSelected
                    ? const Color(0xFF2563EB)
                    : (isSelected
                        ? (hasHighlight ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9))
                        : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasHighlight && !isSelected
                      ? Colors.white
                      : (hasHighlight && isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkRead,
  });

  final UserNotificationDto notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isUnread = n.isUnread;
    final visuals = _getNotificationVisuals(n.type, isUnread);
    final timeStr = _formatNotificationTime(n.createdAt);

    final bgColor = isUnread
        ? (_isHovered ? const Color(0xFFE5F0FF) : const Color(0xFFEFF6FF))
        : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(
                color: isUnread ? const Color(0xFF2563EB) : Colors.transparent,
                width: 3.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual Icon Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: visuals.bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: visuals.borderColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    visuals.icon,
                    color: visuals.iconColor,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 13),

              // Title, body and timestamp
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Title + Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                              color: isUnread
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF475569),
                              letterSpacing: -0.15,
                            ),
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                              color: isUnread
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Bottom line: Body
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                        color: isUnread
                            ? const Color(0xFF334155)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Right indicator / Mark as read quick action
              if (isUnread) ...[
                if (widget.onMarkRead != null)
                  Tooltip(
                    message: 'Mark as read',
                    child: InkWell(
                      onTap: widget.onMarkRead,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.done_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ] else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

({IconData icon, Color iconColor, Color bgColor, Color borderColor}) _getNotificationVisuals(
  String type,
  bool isUnread,
) {
  final iconData = notificationIconFor(type);
  if (!isUnread) {
    return (
      icon: iconData,
      iconColor: const Color(0xFF94A3B8),
      bgColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
    );
  }

  return switch (type) {
    'master_teacher_assigned' ||
    'master_teacher_changed' ||
    'master_teacher_removed' ||
    'common_teacher_assigned' ||
    'common_teacher_changed' ||
    'common_teacher_removed' => (
      icon: iconData,
      iconColor: const Color(0xFF4F46E5), // Indigo
      bgColor: const Color(0xFFEEF2FF),
      borderColor: const Color(0xFFC7D2FE),
    ),
    'student_enrolled_in_batch' || 'student_unenrolled_from_batch' => (
      icon: iconData,
      iconColor: const Color(0xFF0D9488), // Teal
      bgColor: const Color(0xFFCCFBF1),
      borderColor: const Color(0xFF99F6E4),
    ),
    'agent_registered_student' => (
      icon: iconData,
      iconColor: const Color(0xFF2563EB), // Blue
      bgColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
    ),
    'admin_request_submitted' ||
    'admin_request_approved' ||
    'admin_request_rejected' => (
      icon: iconData,
      iconColor: const Color(0xFF0284C7), // Sky Blue
      bgColor: const Color(0xFFE0F2FE),
      borderColor: const Color(0xFFBAE6FD),
    ),
    'student_booking_failed' ||
    'attendance_conflict_reported' ||
    'attendance_conflict_resolved' => (
      icon: iconData,
      iconColor: const Color(0xFFDC2626), // Red
      bgColor: const Color(0xFFFEF2F2),
      borderColor: const Color(0xFFFECACA),
    ),
    'session_booked' ||
    'session_rescheduled' ||
    'session_mentor_updated' => (
      icon: iconData,
      iconColor: const Color(0xFF7C3AED), // Violet
      bgColor: const Color(0xFFF5F3FF),
      borderColor: const Color(0xFFDDD6FE),
    ),
    'session_cancelled' ||
    'teacher_leave_submitted' ||
    'teacher_leave_approved' ||
    'teacher_leave_rejected' ||
    'teacher_leave_cancelled' => (
      icon: iconData,
      iconColor: const Color(0xFFEA580C), // Orange
      bgColor: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFFFEDD5),
    ),
    'payment_recorded' || 'payment_voided' => (
      icon: iconData,
      iconColor: const Color(0xFF16A34A), // Green
      bgColor: const Color(0xFFDCFCE7),
      borderColor: const Color(0xFFBBF7D0),
    ),
    'student_promoted' || 'aptitude_assessment_available' => (
      icon: iconData,
      iconColor: const Color(0xFFD97706), // Amber
      bgColor: const Color(0xFFFEF3C7),
      borderColor: const Color(0xFFFDE68A),
    ),
    'admin_announcement' => (
      icon: iconData,
      iconColor: const Color(0xFF2563EB), // Blue
      bgColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
    ),
    _ => (
      icon: iconData,
      iconColor: const Color(0xFF2563EB),
      bgColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
    ),
  };
}

String _formatNotificationTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw;
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.isNegative || diff.inSeconds < 60) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24 && dt.day == now.day && dt.month == now.month && dt.year == now.year) {
    return '${diff.inHours}h ago';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (dt.day == yesterday.day && dt.month == yesterday.month && dt.year == yesterday.year) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return 'Yesterday, $hour12:$minute $period';
  }
  return formatDisplayDateTime(raw, fallback: '');
}
