import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentScaffold extends ConsumerWidget {
  const StudentScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.backTo,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? backTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(studentAssessmentProvider);
    final pending = assessment.maybeWhen(
      data: (payload) => payload.available && payload.assessment != null,
      orElse: () => false,
    );
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: Academy.canvas,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F3EA), Color(0xFFF1EEE6), Color(0xFFECE7DC)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AcademyNav(
              location: location,
              pending: pending,
              extraActions: actions,
            ),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brand.navy),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final insets = Academy.pageInsets(constraints.maxWidth);
                    return Padding(
                      padding: EdgeInsets.fromLTRB(insets.left, insets.top, insets.right, 0),
                      child: SizedBox(
                        width: constraints.maxWidth - insets.left - insets.right,
                        height: constraints.maxHeight - insets.top,
                        child: body,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademyNav extends ConsumerWidget {
  const _AcademyNav({
    required this.location,
    required this.pending,
    this.extraActions,
  });

  final String location;
  final bool pending;
  final List<Widget>? extraActions;

  static const _links = [
    (label: 'Dashboard', icon: Icons.home_outlined, path: RoutePaths.studentDashboard),
    (label: 'My Sessions', icon: Icons.event_available_outlined, path: RoutePaths.studentBookings),
    (label: 'Journey', icon: Icons.explore_outlined, path: RoutePaths.studentJournal),
    (label: 'Feedback', icon: Icons.forum_outlined, path: RoutePaths.studentFeedback),
    (label: 'Requests', icon: Icons.support_agent_outlined, path: RoutePaths.studentRequests),
    (label: 'Profile', icon: Icons.person_outline, path: RoutePaths.studentProfile),
  ];

  bool _selected(String path) {
    if (path == RoutePaths.studentDashboard) {
      return location == path;
    }
    return location == path || location.startsWith('$path/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        final isTight = constraints.maxWidth < 1120;

        return Material(
          color: const Color(0xF20B1F36),
          elevation: 0,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 10, compact ? 12 : 20, 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Brand.gold.withValues(alpha: 0.28)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Brand: Logo + Title
                InkWell(
                  onTap: () {
                    dismissOverlayRoutes(context);
                    context.go(RoutePaths.studentDashboard);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(height: 32),
                        if (constraints.maxWidth >= 480) ...[
                          const SizedBox(width: 10),
                          const Text(
                            'Excellent Educators',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Desktop Navigation Items
                if (!compact) ...[
                  const SizedBox(width: 16),
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 12),
                  for (final link in _links)
                    Padding(
                      padding: EdgeInsets.only(left: isTight ? 2 : 4),
                      child: _NavItem(
                        label: link.label,
                        icon: link.icon,
                        selected: _selected(link.path),
                        disabled: pending && link.path == RoutePaths.studentFeedback,
                        tight: isTight,
                        onTap: () {
                          dismissOverlayRoutes(context);
                          context.go(link.path);
                        },
                      ),
                    ),
                ],

                // Push actions to the far right
                const Spacer(),

                // Divider before actions on desktop
                if (!compact) ...[
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(width: 6),
                ],

                // Action buttons
                ...?extraActions,
                const NotificationBellButton(),
                IconButton(
                  tooltip: 'Sign out',
                  iconSize: 20,
                  onPressed: () => confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                ),

                // Menu button in compact mode
                if (compact) ...[
                  const SizedBox(width: 2),
                  PopupMenuButton<String>(
                    tooltip: 'Menu',
                    color: const Color(0xFF10263D),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Brand.gold.withValues(alpha: 0.28)),
                    ),
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onSelected: (path) {
                      dismissOverlayRoutes(context);
                      context.go(path);
                    },
                    itemBuilder: (context) => [
                      for (final link in _links)
                        PopupMenuItem(
                          value: link.path,
                          enabled: !(pending && link.path == RoutePaths.studentFeedback),
                          child: Row(
                            children: [
                              Icon(
                                link.icon,
                                size: 18,
                                color: _selected(link.path) ? Brand.gold : Colors.white70,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                link.label,
                                style: TextStyle(
                                  color: _selected(link.path) ? Brand.gold : Colors.white,
                                  fontWeight: _selected(link.path) ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.disabled = false,
    this.tight = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;
  final bool tight;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final hPad = widget.tight ? 8.0 : 11.0;
    final vPad = widget.tight ? 6.0 : 7.0;
    final iconSize = widget.tight ? 14.0 : 15.0;
    final fontSize = widget.tight ? 12.0 : 13.0;

    return MouseRegion(
      cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Opacity(
        opacity: widget.disabled ? 0.38 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.disabled ? null : widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: active
                    ? Brand.gold.withValues(alpha: 0.16)
                    : _hover
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.transparent,
                border: Border.all(
                  color: active ? Brand.gold.withValues(alpha: 0.75) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: iconSize,
                    color: active
                        ? Brand.gold
                        : _hover
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.85),
                  ),
                  SizedBox(width: widget.tight ? 4 : 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: active
                          ? Brand.gold
                          : _hover
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.9),
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      fontSize: fontSize,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
