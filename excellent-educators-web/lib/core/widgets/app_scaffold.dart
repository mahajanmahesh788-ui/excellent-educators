import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_info.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void dismissOverlayRoutes(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  navigator.popUntil((route) => route is! PopupRoute);
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
    final destinations = _destinations(user);
    final location = GoRouterState.of(context).uri.path;
    final selected = destinations.indexWhere((item) => location.startsWith(item.path));
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.mobile;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(wide ? 16 : 12, 12, wide ? 16 : 12, 12),
      child: body,
    );

    return Scaffold(
      appBar: AppBar(
        leading: backTo == null
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  dismissOverlayRoutes(context);
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(backTo!);
                },
              ),
        automaticallyImplyLeading: backTo == null,
        title: Text(title),
        actions: [
          ...?actions,
          TextButton(
            onPressed: () => confirmSignOut(context, ref),
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      drawer: wide || destinations.isEmpty
          ? null
          : Drawer(
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
                            leading: Icon(item.icon),
                            title: Text(item.label),
                            selected: location.startsWith(item.path),
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
            ),
      floatingActionButton: floatingActionButton,
      body: destinations.isEmpty || !wide
          ? SelectionArea(child: content)
          : Row(
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
    );
  }

  List<_NavItem> _destinations(AppUser? user) {
    if (user == null) {
      return const [];
    }
    return [
      if (user.isAdmin) ...[
        const _NavItem('Dashboard', Icons.dashboard_outlined, RoutePaths.adminDashboard),
        const _NavItem('Students', Icons.school_outlined, RoutePaths.adminStudents),
        const _NavItem('Teachers', Icons.badge_outlined, RoutePaths.adminTeachers),
        const _NavItem('Batches', Icons.groups_outlined, RoutePaths.adminBatches),
        const _NavItem('Assessments', Icons.quiz_outlined, RoutePaths.adminAssessments),
        const _NavItem('Content', Icons.web_outlined, RoutePaths.adminLoginPage),
        const _NavItem('Requests', Icons.support_agent_outlined, RoutePaths.adminRequests),
      ],
      if (user.isCommonTeacher)
        const _NavItem('My batches', Icons.groups_outlined, RoutePaths.teacherBatches),
      if (user.isMasterTeacher)
        const _NavItem('Dashboard', Icons.dashboard_outlined, RoutePaths.masterTeacherDashboard),
      if (user.isMasterTeacher)
        const _NavItem('My students', Icons.psychology_outlined, RoutePaths.masterTeacherStudents),
      if (user.isCommonTeacher || user.isMasterTeacher) ...[
        const _NavItem('Request admin', Icons.support_agent_outlined, RoutePaths.teacherRequests),
        const _NavItem('Profile', Icons.person_outline, RoutePaths.teacherProfile),
      ],
      if (user.isStudent) ...[
        const _NavItem('Dashboard', Icons.dashboard_rounded, RoutePaths.studentDashboard),
        const _NavItem('Feedback', Icons.forum_outlined, RoutePaths.studentFeedback),
        const _NavItem('Request admin', Icons.support_agent_outlined, RoutePaths.studentRequests),
        const _NavItem('Profile', Icons.person_outline, RoutePaths.studentProfile),
      ],
    ];
  }
}

Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: 'Sign out?',
    message: 'You will need to sign in again to access your account.',
    confirmLabel: 'Sign out',
    cancelLabel: 'Cancel',
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  await ref.read(authControllerProvider.notifier).logout();
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
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
                            Icon(item.icon, color: color, size: 22),
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
