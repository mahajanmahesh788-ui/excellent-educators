import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/fresh_student_onboarding.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';

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
    final journeyWaiting = ref.watch(studentProfileProvider).maybeWhen(
          data: (student) => student.isBatchWaitingToStart,
          orElse: () => false,
        );
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: StudentColors.canvas,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: StudentColors.canvasGradient,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AcademyNav(
              location: location,
              pending: pending,
              journeyWaiting: journeyWaiting,
              extraActions: actions,
            ),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  progressIndicatorTheme: const ProgressIndicatorThemeData(
                    color: StudentColors.indigoPrimary,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final insets = Academy.pageInsets(constraints.maxWidth);
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        insets.left,
                        insets.top,
                        insets.right,
                        0,
                      ),
                      child: SizedBox(
                        width:
                            constraints.maxWidth - insets.left - insets.right,
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
    required this.journeyWaiting,
    this.extraActions,
  });

  final String location;
  final bool pending;
  final bool journeyWaiting;
  final List<Widget>? extraActions;

  static const _links = [
    (
      label: AppStrings.dashboard,
      icon: Icons.dashboard_outlined,
      path: RoutePaths.studentDashboard,
    ),
    (
      label: AppStrings.mySessions,
      icon: Icons.event_available_outlined,
      path: RoutePaths.studentBookings,
    ),
    (
      label: AppStrings.journey,
      icon: Icons.explore_outlined,
      path: RoutePaths.studentJournal,
    ),
    (
      label: AppStrings.feedback,
      icon: Icons.forum_outlined,
      path: RoutePaths.studentFeedback,
    ),
    (
      label: AppStrings.requests,
      icon: Icons.support_agent_outlined,
      path: RoutePaths.studentRequests,
    ),
    (
      label: AppStrings.profile,
      icon: Icons.person_outline,
      path: RoutePaths.studentProfile,
    ),
  ];

  static bool _isLockedLink(String path) {
    return path != RoutePaths.studentDashboard &&
        path != RoutePaths.studentProfile &&
        path != RoutePaths.studentRequests;
  }

  bool _blocksLink(String path) {
    if (!_isLockedLink(path)) {
      return false;
    }
    return pending || journeyWaiting;
  }

  void _onNavTap(BuildContext context, String path, String label) {
    dismissOverlayRoutes(context);
    if (!_isLockedLink(path)) {
      context.go(path);
      return;
    }
    if (journeyWaiting) {
      JourneyNotStartedDialog.show(context);
      return;
    }
    if (pending) {
      LockedFeatureNoticeDialog.show(context, featureName: label);
      return;
    }
    context.go(path);
  }

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
        final compact = constraints.maxWidth < 960;
        final isTight = constraints.maxWidth < 1140;

        return Material(
          color: Colors.white,
          elevation: 0,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 24,
              compact ? 8 : 10,
              compact ? 8 : 20,
              compact ? 8 : 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: StudentColors.border, width: 1.2),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(height: 26),
                        if (constraints.maxWidth >= 480) ...[
                          const SizedBox(width: 10),
                          const Text(
                            AppStrings.excellentEducators,
                            style: TextStyle(
                              color: StudentColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.2,
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
                  Container(height: 20, width: 1, color: StudentColors.border),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final link in _links)
                            Padding(
                              padding: EdgeInsets.only(left: isTight ? 2 : 4),
                              child: _NavItem(
                                label: link.label,
                                icon: link.icon,
                                selected: _selected(link.path),
                                disabled: false,
                                isLocked: _blocksLink(link.path),
                                tight: isTight,
                                onTap: () => _onNavTap(context, link.path, link.label),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Push actions to the far right on compact screens
                if (compact) const Spacer(),

                // Divider before actions on desktop
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Container(height: 20, width: 1, color: StudentColors.border),
                  const SizedBox(width: 6),
                ],

                // Action buttons
                ...?extraActions,
                const NotificationBellButton(
                  color: StudentColors.textSecondary,
                ),
                IconButton(
                  tooltip: AppStrings.signOut,
                  iconSize: 20,
                  onPressed: () => confirmSignOut(context, ref),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: StudentColors.textSecondary,
                  ),
                ),

                // Menu button in compact mode
                if (compact) ...[
                  const SizedBox(width: 2),
                  PopupMenuButton<String>(
                    tooltip: AppStrings.menu,
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: StudentColors.border),
                    ),
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: StudentColors.textSecondary,
                    ),
                    onSelected: (path) {
                      final link = _links.firstWhere(
                        (l) => l.path == path,
                        orElse: () => _links.first,
                      );
                      _onNavTap(context, path, link.label);
                    },
                    itemBuilder: (context) => [
                      for (final link in _links)
                        PopupMenuItem(
                          value: link.path,
                          child: Row(
                            children: [
                              Icon(
                                link.icon,
                                size: 18,
                                color: _selected(link.path)
                                    ? StudentColors.indigoPrimary
                                    : StudentColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  link.label,
                                  style: TextStyle(
                                    color: _selected(link.path)
                                        ? StudentColors.indigoPrimary
                                        : StudentColors.textPrimary,
                                    fontWeight: _selected(link.path)
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_blocksLink(link.path)) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: StudentColors.textMuted,
                                ),
                              ],
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
    this.isLocked = false,
    this.tight = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;
  final bool isLocked;
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
      cursor: widget.disabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
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
                    ? StudentColors.indigoLight
                    : _hover
                    ? StudentColors.surfaceMuted
                    : Colors.transparent,
                border: Border.all(
                  color: active
                      ? StudentColors.emeraldBorder
                      : Colors.transparent,
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
                        ? StudentColors.indigoPrimary
                        : _hover
                        ? StudentColors.textPrimary
                        : StudentColors.textMuted,
                  ),
                  SizedBox(width: widget.tight ? 4 : 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: active
                          ? StudentColors.indigoPrimary
                          : _hover
                          ? StudentColors.textPrimary
                          : StudentColors.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      fontSize: fontSize,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (widget.isLocked) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.lock_rounded,
                      size: 11,
                      color: StudentColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
