import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/notification_icons.dart';
import 'package:excellent_educators_web/features/notifications/presentation/notification_navigation.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _NotificationFilter { all, unread }

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};
  bool _bulkBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _enterSelectionMode({String? initialId}) {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      if (initialId != null) {
        _selectedIds.add(initialId);
      }
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<UserNotificationDto> items) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(items.map((n) => n.id));
    });
  }

  void _unselectAll() {
    setState(_selectedIds.clear);
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
        final visibleIds = filteredItems.map((n) => n.id).toSet();
        final selectedVisible =
            _selectedIds.where(visibleIds.contains).toSet();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 24,
                      vertical: isMobile ? 12 : 18,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildToolbar(
                        totalCount: items.length,
                        unreadCount: unreadCount,
                        filteredItems: filteredItems,
                        canBroadcast: (user?.isAdmin ?? false) &&
                            !user!.isAgent &&
                            user.canAdmin(AdminPermission.settingsManage),
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 12),
                      if (filteredItems.isEmpty)
                        _buildAllCaughtUpState()
                      else
                        Container(
                          width: double.infinity,
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
                                  selectionMode: _selectionMode,
                                  selected:
                                      selectedVisible.contains(filteredItems[i].id),
                                  isMobile: isMobile,
                                  onTap: () {
                                    if (_selectionMode) {
                                      _toggleSelected(filteredItems[i].id);
                                      return;
                                    }
                                    _openNotification(
                                      context,
                                      ref,
                                      filteredItems[i],
                                    );
                                  },
                                  onLongPress: () {
                                    if (_selectionMode) {
                                      _toggleSelected(filteredItems[i].id);
                                    } else {
                                      _enterSelectionMode(
                                        initialId: filteredItems[i].id,
                                      );
                                    }
                                  },
                                  onToggleSelect: () =>
                                      _toggleSelected(filteredItems[i].id),
                                  onDelete: _selectionMode
                                      ? null
                                      : () => _deleteNotification(
                                            context,
                                            ref,
                                            filteredItems[i],
                                          ),
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
                if (_selectionMode)
                  _SelectionActionBar(
                    selectedCount: selectedVisible.length,
                    busy: _bulkBusy,
                    onMarkUnread: selectedVisible.isEmpty || _bulkBusy
                        ? null
                        : () => _markSelectedUnread(
                              context,
                              ref,
                              filteredItems,
                              selectedVisible,
                            ),
                    onDelete: selectedVisible.isEmpty || _bulkBusy
                        ? null
                        : () => _deleteSelected(
                              context,
                              ref,
                              filteredItems,
                              selectedVisible,
                            ),
                  ),
              ],
            );
          },
        );
      },
    );

    final actions = <Widget>[
      if (!_selectionMode &&
          (user?.isAdmin ?? false) &&
          !user!.isAgent &&
          user.canAdmin(AdminPermission.settingsManage))
        TextButton(
          onPressed: () => _composeBroadcast(context, ref),
          child: Text(
            AppStrings.broadcastAnnouncement,
            style: TextStyle(
              color: (user.isStudent) ? StudentColors.indigoPrimary : Colors.white,
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
    required List<UserNotificationDto> filteredItems,
    required bool canBroadcast,
    required bool isMobile,
  }) {
    if (_selectionMode) {
      final selectedVisibleCount =
          _selectedIds.where((id) => filteredItems.any((n) => n.id == id)).length;
      final allSelected =
          filteredItems.isNotEmpty && selectedVisibleCount == filteredItems.length;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$selectedVisibleCount ${AppStrings.selectedCountLabel}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          TextButton(
            onPressed: filteredItems.isEmpty
                ? null
                : () {
                    if (allSelected) {
                      _unselectAll();
                    } else {
                      _selectAll(filteredItems);
                    }
                  },
            style: TextButton.styleFrom(
              foregroundColor: Brand.navy,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              allSelected ? AppStrings.unselectAll : AppStrings.selectAll,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _exitSelectionMode,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
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
                onTap: () =>
                    setState(() => _selectedFilter = _NotificationFilter.all),
              ),
              const SizedBox(width: 2),
              _FilterTab(
                label: 'Unread',
                count: unreadCount,
                hasHighlight: unreadCount > 0,
                isSelected: _selectedFilter == _NotificationFilter.unread,
                onTap: () => setState(
                  () => _selectedFilter = _NotificationFilter.unread,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unreadCount > 0)
              TextButton.icon(
                onPressed: () => _markAllRead(context, ref),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: Text(
                  isMobile ? 'Read all' : AppStrings.markAllRead,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Brand.navy,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            if (totalCount > 0)
              TextButton.icon(
                onPressed: () => _enterSelectionMode(),
                icon: const Icon(Icons.checklist_rounded, size: 16),
                label: const Text(
                  AppStrings.select,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            if (canBroadcast && !isMobile) ...[
              const SizedBox(width: 4),
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
        ),
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
            onPressed: () =>
                setState(() => _selectedFilter = _NotificationFilter.all),
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

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    UserNotificationDto notification,
  ) async {
    if (!notification.isUnread) return;
    try {
      await ref.read(notificationRepositoryProvider).markRead(notification.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (error) {
      if (context.mounted) showFailure(context, error);
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (error) {
      if (context.mounted) showFailure(context, error);
    }
  }

  Future<void> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    UserNotificationDto notification,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: AppStrings.deleteNotificationQuestion,
      message: AppStrings.deleteNotificationMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(notificationRepositoryProvider).delete(notification.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (error) {
      if (context.mounted) showFailure(context, error);
    }
  }

  Future<void> _markSelectedUnread(
    BuildContext context,
    WidgetRef ref,
    List<UserNotificationDto> visible,
    Set<String> selectedIds,
  ) async {
    final ids = selectedIds.toList();
    if (ids.isEmpty) return;

    setState(() => _bulkBusy = true);
    try {
      final repo = ref.read(notificationRepositoryProvider);
      for (final id in ids) {
        UserNotificationDto? item;
        for (final n in visible) {
          if (n.id == id) {
            item = n;
            break;
          }
        }
        if (item == null || item.isUnread) continue;
        await repo.markUnread(id);
      }
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
      if (mounted) _exitSelectionMode();
    } catch (error) {
      if (context.mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _deleteSelected(
    BuildContext context,
    WidgetRef ref,
    List<UserNotificationDto> visible,
    Set<String> selectedIds,
  ) async {
    final ids = selectedIds.toList();
    if (ids.isEmpty) return;

    final confirmed = await showAppConfirmDialog(
      context,
      title: AppStrings.deleteSelectedNotificationsQuestion,
      message: AppStrings.deleteSelectedNotificationsMessage(ids.length),
      confirmLabel: AppStrings.deleteSelected,
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _bulkBusy = true);
    try {
      final repo = ref.read(notificationRepositoryProvider);
      for (final id in ids) {
        if (!visible.any((n) => n.id == id)) continue;
        await repo.delete(id);
      }
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
      if (mounted) _exitSelectionMode();
    } catch (error) {
      if (context.mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
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
                  decoration:
                      const InputDecoration(labelText: AppStrings.description),
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
    if (sent != true) return;
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
      if (context.mounted) showFailure(context, error);
    }
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedCount,
    required this.busy,
    required this.onMarkUnread,
    required this.onDelete,
  });

  final int selectedCount;
  final bool busy;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Text(
                '$selectedCount ${AppStrings.selectedCountLabel}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const Spacer(),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              TextButton(
                onPressed: onMarkUnread,
                style: TextButton.styleFrom(
                  foregroundColor: Brand.navy,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  AppStrings.markAsUnread,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text(
                  AppStrings.deleteSelected,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    ? Brand.navy
                    : (isSelected
                        ? (hasHighlight
                            ? Brand.navy.withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9))
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
                          ? Brand.navy
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
    required this.selectionMode,
    required this.selected,
    required this.isMobile,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
    this.onDelete,
  });

  final UserNotificationDto notification;
  final bool selectionMode;
  final bool selected;
  final bool isMobile;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;
  final VoidCallback? onDelete;

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
    final timeStr = _formatNotificationTime(n.createdAt, compact: widget.isMobile);

    final bgColor = widget.selected
        ? Brand.navy.withValues(alpha: 0.06)
        : isUnread
            ? (_isHovered
                ? Brand.navy.withValues(alpha: 0.05)
                : Brand.navy.withValues(alpha: 0.025))
            : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(
                color: isUnread ? Brand.navy : Colors.transparent,
                width: 3.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            widget.selectionMode ? 10 : 14,
            12,
            12,
            12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectionMode) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: widget.selected,
                      onChanged: (_) => widget.onToggleSelect(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                      activeColor: Brand.navy,
                    ),
                  ),
                ),
              ],
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: visuals.bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: visuals.borderColor),
                ),
                child: Center(
                  child: Icon(visuals.icon, color: visuals.iconColor, size: 19),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: widget.isMobile ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w500,
                              color: isUnread
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF475569),
                              letterSpacing: -0.15,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (!widget.selectionMode) ...[
                          const SizedBox(width: 8),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                color: Brand.navy,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(width: 8),
                          if (widget.onDelete != null) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: AppStrings.delete,
                              child: InkWell(
                                onTap: widget.onDelete,
                                borderRadius: BorderRadius.circular(16),
                                hoverColor: const Color(0xFFFEE2E2),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      maxLines: widget.isMobile ? 3 : 2,
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
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                          color: isUnread
                              ? Brand.navy.withValues(alpha: 0.75)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({IconData icon, Color iconColor, Color bgColor, Color borderColor})
    _getNotificationVisuals(String type, bool isUnread) {
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
      iconColor: const Color(0xFF4F46E5),
      bgColor: const Color(0xFFEEF2FF),
      borderColor: const Color(0xFFC7D2FE),
    ),
    'student_enrolled_in_batch' || 'student_unenrolled_from_batch' => (
      icon: iconData,
      iconColor: const Color(0xFF0D9488),
      bgColor: const Color(0xFFCCFBF1),
      borderColor: const Color(0xFF99F6E4),
    ),
    'agent_registered_student' => (
      icon: iconData,
      iconColor: Brand.navy,
      bgColor: const Color(0xFFF1F5F9),
      borderColor: const Color(0xFFE2E8F0),
    ),
    'admin_request_submitted' ||
    'admin_request_approved' ||
    'admin_request_rejected' => (
      icon: iconData,
      iconColor: const Color(0xFF0284C7),
      bgColor: const Color(0xFFE0F2FE),
      borderColor: const Color(0xFFBAE6FD),
    ),
    'student_booking_failed' ||
    'attendance_conflict_reported' ||
    'attendance_conflict_resolved' => (
      icon: iconData,
      iconColor: const Color(0xFFDC2626),
      bgColor: const Color(0xFFFEF2F2),
      borderColor: const Color(0xFFFECACA),
    ),
    'session_booked' ||
    'session_rescheduled' ||
    'session_mentor_updated' => (
      icon: iconData,
      iconColor: const Color(0xFF7C3AED),
      bgColor: const Color(0xFFF5F3FF),
      borderColor: const Color(0xFFDDD6FE),
    ),
    'session_cancelled' ||
    'teacher_leave_submitted' ||
    'teacher_leave_approved' ||
    'teacher_leave_rejected' ||
    'teacher_leave_cancelled' => (
      icon: iconData,
      iconColor: const Color(0xFFEA580C),
      bgColor: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFFFEDD5),
    ),
    'payment_recorded' || 'payment_voided' => (
      icon: iconData,
      iconColor: const Color(0xFF16A34A),
      bgColor: const Color(0xFFDCFCE7),
      borderColor: const Color(0xFFBBF7D0),
    ),
    'student_promoted' || 'aptitude_assessment_available' => (
      icon: iconData,
      iconColor: const Color(0xFFD97706),
      bgColor: const Color(0xFFFEF3C7),
      borderColor: const Color(0xFFFDE68A),
    ),
    'admin_announcement' => (
      icon: iconData,
      iconColor: Brand.navy,
      bgColor: const Color(0xFFF1F5F9),
      borderColor: const Color(0xFFE2E8F0),
    ),
    _ => (
      icon: iconData,
      iconColor: Brand.navy,
      bgColor: const Color(0xFFF1F5F9),
      borderColor: const Color(0xFFE2E8F0),
    ),
  };
}

String _formatNotificationTime(String? raw, {required bool compact}) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw;
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 &&
      dt.day == now.day &&
      dt.month == now.month &&
      dt.year == now.year) {
    return '${diff.inHours}h ago';
  }

  final yesterday = now.subtract(const Duration(days: 1));
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  final minute = dt.minute.toString().padLeft(2, '0');
  final timePart = '$hour12:$minute $period';

  if (dt.day == yesterday.day &&
      dt.month == yesterday.month &&
      dt.year == yesterday.year) {
    return 'Yesterday, $timePart';
  }

  if (compact) {
    final day = dt.day.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[dt.month - 1];
    if (dt.year == now.year) {
      return '$day $month · $timePart';
    }
    return '$day $month ${dt.year} · $timePart';
  }

  return formatDisplayDateTime(raw, fallback: '');
}
