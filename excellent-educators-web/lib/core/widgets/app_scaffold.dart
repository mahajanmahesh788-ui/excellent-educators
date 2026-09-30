import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_info.dart';
import 'package:excellent_educators_web/core/navigation/app_nav_history.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

void dismissOverlayRoutes(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  navigator.popUntil((route) => route is! PopupRoute);
}

/// Returns true if at least one dialog/bottom-sheet/popup was closed.
bool dismissOverlayRoutesIfAny(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  var closed = false;
  navigator.popUntil((route) {
    if (route is PopupRoute) {
      closed = true;
      return false;
    }
    return true;
  });
  return closed;
}

void navigateBack(BuildContext context, String? backTo) {
  // Back should close an open dialog first, then leave the page on the next press.
  if (dismissOverlayRoutesIfAny(context)) {
    return;
  }

  // Prefer real stack pop when routes were pushed (A→B→C then C→B→A).
  if (context.canPop()) {
    context.pop();
    return;
  }

  // With `go()` navigations there is often no Navigator stack — walk our history.
  final previous = AppNavHistory.instance.takeBackTarget();
  if (previous != null) {
    context.go(previous);
    return;
  }

  if (backTo != null && backTo.isNotEmpty) {
    context.go(backTo);
  }
}

class _NavBrandFooter extends StatelessWidget {
  const _NavBrandFooter({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 8, 8, compact ? 16 : 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 10),
          AppLogo(height: compact ? 52 : 44),
          const SizedBox(height: 6),
          Text(
            'v${AppInfo.version}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: compact ? 12 : 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.disabledNavPaths = const [],
    this.backTo,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final List<String> disabledNavPaths;
  /// When set, shows a back arrow in the app bar that navigates to this route.
  final String? backTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final pendingConflicts = user?.isAdmin == true && (user?.canAnyAdmin(const [AdminPermission.queriesView, AdminPermission.queriesResolve]) ?? false)
        ? ref.watch(adminPendingConflictsCountProvider).valueOrNull ?? 0
        : 0;
    final destinations = _destinations(user, pendingConflicts);
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedNavIndex(destinations, location);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.mobile;
    final isTeacher =
        user?.isMasterTeacher == true || user?.isCommonTeacher == true;
    final useBottomNav = !wide && isTeacher && destinations.isNotEmpty;
    final useDrawer = !wide && !useBottomNav && destinations.isNotEmpty;

    final portal = isTeacher;
    // Extra top inset so the first outlined field's floating label isn't clipped.
    Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? 16 : 10,
        wide ? 16 : 12,
        wide ? 16 : 10,
        useBottomNav ? 4 : (wide ? 12 : 8),
      ),
      child: body,
    );
    if (portal) {
      content = AnimatedPortalBackdrop(child: content);
    }

    return PopScope(
      // Let the navigator pop when it has a stack (push). Otherwise intercept
      // system/browser back and walk AppNavHistory / backTo (C→B→A).
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        navigateBack(context, backTo);
      },
      child: Scaffold(
      appBar: AppBar(
        leading: (backTo != null ||
                context.canPop() ||
                AppNavHistory.instance.canGoBack)
            ? IconButton(
                tooltip: AppStrings.back,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => navigateBack(context, backTo),
              )
            : null,
        automaticallyImplyLeading: backTo == null &&
            !context.canPop() &&
            !AppNavHistory.instance.canGoBack &&
            useDrawer,
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          ...?actions,
          if (_showNotifications(user)) const NotificationBellButton(),
          if (wide)
            TextButton(
              onPressed: () => confirmSignOut(context, ref),
              child: const Text(AppStrings.signOut, style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              tooltip: AppStrings.signOut,
              onPressed: () => confirmSignOut(context, ref),
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
        ],
      ),
      drawer: useDrawer
          ? Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Brand.navy),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final item in destinations)
                          ListTile(
                            leading: Badge(
                              isLabelVisible: item.badgeCount != null && item.badgeCount! > 0,
                              label: Text('${item.badgeCount ?? 0}'),
                              child: Icon(item.icon),
                            ),
                            title: Text(item.label),
                            selected: selected >= 0 && destinations[selected].path == item.path,
                            enabled: !disabledNavPaths.contains(item.path),
                            onTap: disabledNavPaths.contains(item.path)
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    dismissOverlayRoutes(context);
                                    context.go(item.path);
                                  },
                          ),
                      ],
                    ),
                  ),
                  _NavBrandFooter(compact: true),
                ],
              ),
            )
          : null,
      bottomNavigationBar: useBottomNav && backTo == null
          ? NavigationBar(
              height: 64,
              selectedIndex: selected < 0 ? 0 : selected,
              labelBehavior: destinations.length > 4
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                final item = destinations[index];
                if (disabledNavPaths.contains(item.path)) {
                  return;
                }
                dismissOverlayRoutes(context);
                context.go(item.path);
              },
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible:
                          item.badgeCount != null && item.badgeCount! > 0,
                      label: Text('${item.badgeCount ?? 0}'),
                      child: Icon(item.icon),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible:
                          item.badgeCount != null && item.badgeCount! > 0,
                      label: Text('${item.badgeCount ?? 0}'),
                      child: Icon(item.icon),
                    ),
                    label: item.label,
                  ),
              ],
            )
          : null,
      floatingActionButton: floatingActionButton,
      body: destinations.isEmpty || !wide
          ? SelectionArea(child: content)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SideNav(
                  destinations: destinations,
                  selectedIndex: selected,
                  disabledPaths: disabledNavPaths,
                  onSelect: (index) {
                    dismissOverlayRoutes(context);
                    context.go(destinations[index].path);
                  },
                ),
                const VerticalDivider(width: 1, color: Color(0x33000000)),
                Expanded(child: SelectionArea(child: content)),
              ],
            ),
    ),
    );
  }

  List<_NavItem> _destinations(AppUser? user, int pendingConflicts) {
    if (user == null) {
      return const [];
    }
    return [
      if (user.isAdmin) ...[
        if (!user.isAgent)
          const _NavItem(AppStrings.dashboard, Icons.dashboard_outlined, RoutePaths.adminDashboard),
        if (user.canAnyAdmin(const [
          AdminPermission.studentsView,
          AdminPermission.studentsCreate,
          AdminPermission.studentsEdit,
          AdminPermission.studentsDelete,
          AdminPermission.studentsPromote,
          AdminPermission.studentsRating,
        ]))
          const _NavItem(AppStrings.students, Icons.school_outlined, RoutePaths.adminStudents),
        if (!user.isAgent && user.canAnyAdmin(const [
          AdminPermission.teachersView,
          AdminPermission.teachersCreate,
          AdminPermission.teachersEdit,
          AdminPermission.teachersDelete,
          AdminPermission.teachersSchedule,
          AdminPermission.teachersLeaves,
        ]))
          const _NavItem(AppStrings.teachers, Icons.badge_outlined, RoutePaths.adminTeachers),
        if (!user.isAgent && user.canAnyAdmin(const [AdminPermission.levelsView, AdminPermission.levelsManage]))
          const _NavItem(AppStrings.levels, Icons.layers_outlined, RoutePaths.adminBatches),
        if (!user.isAgent && user.canAnyAdmin(const [AdminPermission.queriesView, AdminPermission.queriesResolve]))
          _NavItem(
            AppStrings.attendance,
            Icons.report_outlined,
            RoutePaths.adminAttendance,
            badgeCount: pendingConflicts > 0 ? pendingConflicts : null,
          ),
        if (!user.isAgent && user.canAnyAdmin(const [
          AdminPermission.teachersLeaves,
          AdminPermission.teachersSchedule,
        ]))
          const _NavItem(AppStrings.leaves, Icons.event_busy_outlined, RoutePaths.adminLeaves),
        if (!user.isAgent && user.canAnyAdmin(const [AdminPermission.assessmentsView, AdminPermission.assessmentsManage]))
          const _NavItem(AppStrings.assessments, Icons.quiz_outlined, RoutePaths.adminAssessments),
        if (user.canAnyAdmin(const [
          AdminPermission.paymentsView,
          AdminPermission.paymentsManage,
          AdminPermission.paymentsRecord,
        ]))
          const _NavItem(AppStrings.payments, Icons.payments_outlined, RoutePaths.adminPayments),
        if (!user.isAgent && user.canAdmin(AdminPermission.settingsManage))
          const _NavItem(AppStrings.settings, Icons.settings_outlined, RoutePaths.adminSettings),
        if (!user.isAgent && user.canAnyAdmin(const [AdminPermission.requestsView, AdminPermission.requestsResolve]))
          const _NavItem(AppStrings.requests, Icons.support_agent_outlined, RoutePaths.adminRequests),
        if (!user.isAgent && user.canAdmin(AdminPermission.subAdminsManage))
          const _NavItem(AppStrings.subAdmins, Icons.admin_panel_settings_outlined, RoutePaths.adminSubAdmins),
      ],
      if (user.isMasterTeacher)
        const _NavItem(AppStrings.dashboard, Icons.dashboard_outlined, RoutePaths.masterTeacherDashboard),
      if (user.isMasterTeacher)
        const _NavItem(AppStrings.myStudents, Icons.psychology_outlined, RoutePaths.masterTeacherStudents),
      if (user.isMasterTeacher || user.isCommonTeacher) ...[
        const _NavItem(AppStrings.todaySchedule, Icons.today_outlined, RoutePaths.teacherDaySchedule),
        const _NavItem(AppStrings.takeLeave, Icons.event_busy_outlined, RoutePaths.teacherSchedule),
        const _NavItem(AppStrings.requestAdmin, Icons.support_agent_outlined, RoutePaths.teacherRequests),
        const _NavItem(AppStrings.profile, Icons.person_outline, RoutePaths.teacherProfile),
      ],
      if (user.isStudent) ...[]
    ];
  }

  static bool _navItemSelected(String location, String path) {
    return location == path || location.startsWith('$path/');
  }

  static int _selectedNavIndex(List<_NavItem> destinations, String location) {
    var best = -1;
    var bestLength = -1;
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (_navItemSelected(location, path) && path.length > bestLength) {
        best = i;
        bestLength = path.length;
      }
    }
    return best;
  }

  bool _showNotifications(AppUser? user) {
    if (user == null) {
      return false;
    }
    return user.isAdmin ||
        user.isStudent ||
        user.isCommonTeacher ||
        user.isMasterTeacher;
  }
}

Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: AppStrings.signOut2,
    message: AppStrings.youWillNeedToSignInAgainToAccessYour,
    confirmLabel: AppStrings.signOut,
    cancelLabel: AppStrings.cancel,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  await ref.read(authControllerProvider.notifier).logout();
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.path, {this.badgeCount});

  final String label;
  final IconData icon;
  final String path;
  final int? badgeCount;
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    this.disabledPaths = const [],
  });

  final List<_NavItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<String> disabledPaths;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Brand.navyDeep,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  final selected = index == selectedIndex;
                  final disabled = disabledPaths.contains(item.path);
                  final color = selected ? Brand.gold : const Color(0xB3FFFFFF);
                  return Opacity(
                    opacity: disabled ? 0.45 : 1,
                    child: InkWell(
                      onTap: disabled ? null : () => onSelect(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Column(
                          children: [
                            Badge(
                              isLabelVisible: item.badgeCount != null && item.badgeCount! > 0,
                              label: Text(
                                '${item.badgeCount ?? 0}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                              child: Icon(item.icon, color: color, size: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _NavBrandFooter(compact: false),
          ],
        ),
      ),
    );
  }
}

void showFailure(BuildContext context, Object error) {
  final message = error.toString();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
