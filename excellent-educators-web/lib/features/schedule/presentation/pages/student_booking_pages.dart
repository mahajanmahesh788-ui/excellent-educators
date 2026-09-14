import 'dart:math' as math;
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/attendance_report_dialog.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/schedule_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_dashboard.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentBookingsPage extends ConsumerStatefulWidget {
  const StudentBookingsPage({super.key});

  @override
  ConsumerState<StudentBookingsPage> createState() => _StudentBookingsPageState();
}

class _StudentBookingsPageState extends ConsumerState<StudentBookingsPage> {
  int _selectedTab = 0; // 0: Upcoming, 1: Past Sessions

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(studentBookingsProvider);
    final eligibility = ref.watch(studentEligibilityProvider);
    final now = DateTime.now();
    final type = eligibility.maybeWhen(
      data: (value) => value.canBookIntroduction
          ? 'introduction_call'
          : value.canBookMasterClass
              ? 'master_class'
              : null,
      orElse: () => null,
    );

    return StudentScaffold(
      title: 'My Sessions',
      body: AnimatedPortalBackdrop(
        child: bookings.when(
          skipLoadingOnReload: true,
          loading: () => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: const [
              AcademySkeleton(height: 120),
              SizedBox(height: 16),
              AcademySkeleton(height: 84),
              SizedBox(height: 18),
              AcademySkeleton(height: 130),
              SizedBox(height: 12),
              AcademySkeleton(height: 130),
            ],
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: AcademyError(
              message: 'Something went wrong while loading your sessions.',
              onRetry: () => ref.invalidate(studentBookingsProvider),
            ),
          ),
          data: (items) {
            final upcoming = items.where((item) {
              if (item.isCancelled || item.isCompleted) return false;
              return item.isScheduled && !item.hasEndedAt(now);
            }).toList()
              ..sort((a, b) => a.start.compareTo(b.start));

            final past = items.where((item) {
              if (item.isCancelled || item.isCompleted) return true;
              return item.hasEndedAt(now);
            }).toList()
              ..sort((a, b) => b.start.compareTo(a.start));

            final activeList = _selectedTab == 0 ? upcoming : past;
            final completedCount = items.where((b) => b.isCompleted).length;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. Hero Sessions Header
                _StudentSessionsHero(
                  type: type,
                  onBook: () => context.go(
                    type == null ? RoutePaths.studentBookNew : '${RoutePaths.studentBookNew}?type=$type',
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Quick KPI Overview Strip
                _StudentOverviewStats(
                  upcomingCount: upcoming.length,
                  completedCount: completedCount,
                ),

                const SizedBox(height: 22),

                // 3. Section Title & Segmented Switcher
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 620;

                    final sectionTitle = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Brand.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTab == 0 ? 'Upcoming Sessions' : 'Session History',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Brand.navy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${activeList.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Brand.navy,
                            ),
                          ),
                        ),
                      ],
                    );

                    final switcher = _SegmentedPillSwitcher(
                      selectedIndex: _selectedTab,
                      upcomingCount: upcoming.length,
                      pastCount: past.length,
                      onTap: (index) => setState(() => _selectedTab = index),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle,
                          const SizedBox(height: 12),
                          switcher,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        sectionTitle,
                        const Spacer(),
                        switcher,
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 4. Active List of Sessions or Empty State
                if (activeList.isEmpty)
                  _EmptySessionCard(
                    isPast: _selectedTab == 1,
                    bookType: type,
                    onBook: () => context.go(
                      type == null ? RoutePaths.studentBookNew : '${RoutePaths.studentBookNew}?type=$type',
                    ),
                  )
                else
                  for (int i = 0; i < activeList.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ExecutiveStudentSessionCard(
                        booking: activeList[i],
                        isPast: _selectedTab == 1,
                        index: i,
                      ),
                    ),

                const SizedBox(height: 36),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Hero Header Banner
/// ---------------------------------------------------------------------------
class _StudentSessionsHero extends StatelessWidget {
  const _StudentSessionsHero({
    required this.type,
    required this.onBook,
  });

  final String? type;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 14 : 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isNarrow ? 14 : 20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1E34),
                Color(0xFF0E2A4A),
                Color(0xFF143B66),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.navy.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Brand.gold.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Builder(
            builder: (context) {
              final titleContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isNarrow ? 26 : 32,
                        height: isNarrow ? 26 : 32,
                        decoration: BoxDecoration(
                          color: Brand.gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
                        ),
                        child: Icon(Icons.stars_rounded, size: isNarrow ? 15 : 18, color: Brand.gold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Brand.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Brand.gold.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'ACADEMY CALENDAR',
                          style: TextStyle(
                            color: Brand.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isNarrow ? 8 : 12),
                  Text(
                    'My Sessions',
                    style: TextStyle(
                      fontSize: isNarrow ? 20 : 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Track upcoming live classes, 1-on-1 mentorship, and schedule history.',
                    style: TextStyle(
                      fontSize: isNarrow ? 12 : 14,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.35,
                    ),
                  ),
                ],
              );

              final bookButton = type == null
                  ? null
                  : ElevatedButton.icon(
                      onPressed: onBook,
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: Brand.navy),
                      label: Text(
                        bookingActionLabel(type),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Brand.navy,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Brand.gold,
                        foregroundColor: Brand.navy,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleContent,
                    if (bookButton != null) ...[
                      const SizedBox(height: 12),
                      bookButton,
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleContent),
                  if (bookButton != null) ...[
                    const SizedBox(width: 20),
                    bookButton,
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Overview KPI Metrics Strip
/// ---------------------------------------------------------------------------
class _StudentOverviewStats extends StatelessWidget {
  const _StudentOverviewStats({
    required this.upcomingCount,
    required this.completedCount,
  });

  final int upcomingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StudentMetricCard(
            title: 'Upcoming',
            value: '$upcomingCount',
            subtitle: upcomingCount == 0 ? 'None' : 'Ready',
            icon: Icons.event_available_rounded,
            accentColor: Brand.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StudentMetricCard(
            title: 'Completed',
            value: '$completedCount',
            subtitle: 'Attended',
            icon: Icons.verified_rounded,
            accentColor: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _StudentMetricCard extends StatefulWidget {
  const _StudentMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  State<_StudentMetricCard> createState() => _StudentMetricCardState();
}

class _StudentMetricCardState extends State<_StudentMetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : Brand.gold.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.accentColor.withValues(alpha: 0.15)
                    : Brand.navy.withValues(alpha: 0.05),
                blurRadius: _hovered ? 14 : 8,
                offset: _hovered ? const Offset(0, 5) : const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(widget.icon, size: 20, color: widget.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Academy.muted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Brand.navy,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.onTap != null ? Brand.navy : Academy.muted,
                        fontWeight: widget.onTap != null ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
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

/// ---------------------------------------------------------------------------
/// Segmented Pill Switcher
/// ---------------------------------------------------------------------------
const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class _SegmentedPillSwitcher extends StatelessWidget {
  const _SegmentedPillSwitcher({
    required this.selectedIndex,
    required this.upcomingCount,
    required this.pastCount,
    required this.onTap,
  });

  final int selectedIndex;
  final int upcomingCount;
  final int pastCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE6D9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillItem(
            label: 'Upcoming',
            count: upcomingCount,
            icon: Icons.calendar_today_rounded,
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(width: 4),
          _PillItem(
            label: 'Past Sessions',
            count: pastCount,
            icon: Icons.history_rounded,
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Brand.gold.withValues(alpha: 0.6) : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Brand.navy.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Brand.navy : Academy.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Brand.navy : Academy.muted,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: selected
                    ? Brand.gold.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? const Color(0xFF6B4D00) : Academy.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Executive Animated Student Session Card
/// ---------------------------------------------------------------------------
class _ExecutiveStudentSessionCard extends ConsumerStatefulWidget {
  const _ExecutiveStudentSessionCard({
    required this.booking,
    required this.isPast,
    required this.index,
  });

  final SessionBookingDto booking;
  final bool isPast;
  final int index;

  @override
  ConsumerState<_ExecutiveStudentSessionCard> createState() => _ExecutiveStudentSessionCardState();
}

class _ExecutiveStudentSessionCardState extends ConsumerState<_ExecutiveStudentSessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPast = widget.isPast;

    final dt = DateTime.tryParse(booking.date);
    final month = dt != null && dt.month >= 1 && dt.month <= 12 ? _months[dt.month - 1] : '—';
    final day = dt != null ? '${dt.day}' : '—';
    final weekday = dt != null && dt.weekday >= 1 && dt.weekday <= 7 ? _weekdays[dt.weekday - 1] : '';

    final now = DateTime.now();
    final ongoing = !isPast && booking.isOngoingAt(now);
    final isMasterClass = booking.type == 'master_class';
    final att = booking.attendance;
    final canJoin = att?.canJoin == true;

    final teacherDisplayName = booking.teacherName != null && booking.teacherName!.isNotEmpty
        ? booking.teacherName!
        : 'Master Teacher';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;

        // 1. Two-Tone Date Badge
            final dateBadge = Container(
              width: isNarrow ? 56 : 68,
              height: isNarrow ? 62 : 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isNarrow ? 12 : 16),
                border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Brand.navy.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: isNarrow ? 2.5 : 4),
                    decoration: BoxDecoration(
                      color: Brand.navy,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(isNarrow ? 11 : 15)),
                    ),
                    child: Center(
                      child: Text(
                        month,
                        style: TextStyle(
                          color: Brand.gold,
                          fontSize: isNarrow ? 9.5 : 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(isNarrow ? 11 : 15)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day,
                            style: TextStyle(
                              color: Academy.ink,
                              fontSize: isNarrow ? 18 : 22,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          if (weekday.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              weekday,
                              style: TextStyle(
                                color: Academy.muted,
                                fontSize: isNarrow ? 8.5 : 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            // 2. Info Details Section
            final infoSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill Badges Row: Type Badge + Live/Status Badge
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMasterClass
                              ? const [Color(0xFF0F263D), Color(0xFF1B3D5C)]
                              : const [Color(0xFF0D4354), Color(0xFF145E75)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMasterClass ? Icons.stars_rounded : Icons.handshake_outlined,
                            size: 13,
                            color: Brand.gold,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            booking.typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Indicator Badge
                    if (canJoin || ongoing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _PulsingLiveDot(),
                            const SizedBox(width: 6),
                            Text(
                              ongoing ? 'CLASS IN PROGRESS' : 'READY TO JOIN',
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (booking.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF2E7D32)),
                            SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (booking.isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Cancelled',
                          style: TextStyle(
                            color: Academy.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else if (!isPast && booking.isScheduled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Confirmed',
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Time details row
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Brand.navy),
                    const SizedBox(width: 6),
                    Text(
                      '${formatHm(booking.start)} — ${formatHm(booking.end)}',
                      style: const TextStyle(
                        color: Academy.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${formatPrettyDate(booking.date)})',
                      style: const TextStyle(
                        color: Academy.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Teacher profile info
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Brand.gold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Brand.gold.withValues(alpha: 0.6)),
                      ),
                      child: Center(
                        child: Text(
                          teacherDisplayName.isNotEmpty ? teacherDisplayName[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      teacherDisplayName,
                      style: const TextStyle(
                        color: Academy.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Brand.navy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Faculty Mentor',
                        style: TextStyle(
                          color: Brand.navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Last Chance Alert
                if (att?.isLastChance == true && (att?.lastChanceMessage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFB45309)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            att!.lastChanceMessage!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );

            // 3. Command Center & Action Buttons
            final actionsSection = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (canJoin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded, size: 17, color: Colors.white),
                    label: Text(
                      ongoing ? 'Kindly join Meet' : (isMasterClass ? 'Join Class' : 'Join Call'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await ref.read(scheduleRepositoryProvider).studentJoinClass(booking.id);
                      ref.invalidate(studentBookingsProvider);
                      final url = booking.meetingUrl;
                      if (url != null && url.isNotEmpty) {
                        await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
                      }
                    },
                  )
                else if (!isPast && booking.isScheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Brand.navy.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: Academy.muted),
                        const SizedBox(width: 5),
                        Text(
                          isMasterClass
                              ? 'Join opens 2 min before class'
                              : 'Join opens 2 min before call',
                          style: const TextStyle(color: Academy.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                if (!isPast && booking.isScheduled && !canJoin)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_calendar_outlined, size: 14, color: Brand.navy),
                    label: const Text(
                      'Reschedule',
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Brand.navy.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => context.go(
                      '${RoutePaths.studentBookNew}?type=${booking.type}&bookingId=${booking.id}',
                    ),
                  ),

                if (att?.canReportTeacherDidNotJoin == true)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.report_problem_outlined, size: 14, color: Color(0xFFD97706)),
                    label: const Text(
                      "Teacher didn't join",
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final session = isMasterClass ? 'class' : 'Introduction Call';
                      final message = await showAttendanceReportDialog(
                        context,
                        title: "Teacher didn't join",
                        hint: 'Tell Admin what happened on this $session:',
                      );
                      if (message == null) return;
                      await ref.read(scheduleRepositoryProvider).studentReportTeacher(booking.id, message);
                      ref.invalidate(studentBookingsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report sent to Admin')),
                        );
                      }
                    },
                  ),

                if (att?.reportSubmitted == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Report sent to Admin',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF92400E)),
                    ),
                  ),

                if (att?.classCompleted == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Class Completed',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF065F46)),
                    ),
                  ),

                if (att?.rebookingAvailable == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Rebooking available: 1',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF78350F)),
                    ),
                  ),
              ],
            );

        final content = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dateBadge,
                      const SizedBox(width: 12),
                      Expanded(child: infoSection),
                    ],
                  ),
                  const SizedBox(height: 10),
                  actionsSection,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dateBadge,
                  const SizedBox(width: 18),
                  Expanded(child: infoSection),
                  const SizedBox(width: 16),
                  actionsSection,
                ],
              );

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: _hovered ? Matrix4.translationValues(0, -3, 0) : Matrix4.identity(),
            padding: EdgeInsets.all(isNarrow ? 12 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isNarrow ? 14 : 18),
              border: Border.all(
                color: _hovered
                    ? Brand.gold.withValues(alpha: 0.6)
                    : Brand.gold.withValues(alpha: 0.22),
                width: _hovered ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? Brand.gold.withValues(alpha: 0.2)
                      : Brand.navy.withValues(alpha: 0.06),
                  blurRadius: _hovered ? 20 : 10,
                  offset: _hovered ? const Offset(0, 7) : const Offset(0, 3),
                ),
              ],
            ),
            child: content,
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Pulsing Live Dot Animation
/// ---------------------------------------------------------------------------
class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1400),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final val = (math.sin(_controller.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4 + 0.5 * val),
                blurRadius: 4 + 4 * val,
                spreadRadius: 1 + 2 * val,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Empty Schedule State
/// ---------------------------------------------------------------------------
class _EmptySessionCard extends StatelessWidget {
  const _EmptySessionCard({
    required this.isPast,
    this.bookType,
    this.onBook,
  });

  final bool isPast;
  final String? bookType;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Brand.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
            ),
            child: Icon(
              isPast ? Icons.history_toggle_off_rounded : Icons.calendar_month_outlined,
              size: 26,
              color: Brand.goldDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPast ? 'No past sessions yet' : 'Your calendar is clear',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Brand.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPast
                ? 'Completed and recorded sessions will be archived here.'
                : 'Book your next live session to keep your learning journey moving forward.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Academy.muted,
              height: 1.4,
            ),
          ),
          if (!isPast && onBook != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBook,
              icon: const Icon(Icons.add_circle_outline, size: 16, color: Brand.navy),
              label: Text(
                bookingActionLabel(bookType),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Brand.navy),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Brand.gold,
                foregroundColor: Brand.navy,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StudentBookingWizardPage extends ConsumerStatefulWidget {
  const StudentBookingWizardPage({super.key, this.type, this.bookingId});

  final String? type;
  final String? bookingId;

  @override
  ConsumerState<StudentBookingWizardPage> createState() => _StudentBookingWizardPageState();
}

class _StudentBookingWizardPageState extends ConsumerState<StudentBookingWizardPage> {
  String? _type;
  TeacherDto? _teacher;
  DateTime? _date;
  String? _start;
  bool _saving = false;
  bool _typeLocked = false;

  bool get _reschedule => widget.bookingId != null;

  @override
  void initState() {
    super.initState();
    final incoming = widget.type;
    _type = incoming == null || incoming.isEmpty ? null : incoming;
    _typeLocked = _reschedule || _type != null;
  }

  String _resolvedType(BookingEligibilityDto eligibility) {
    if (_reschedule && _type != null) {
      return _type!;
    }
    if (eligibility.canBookIntroduction && !eligibility.canBookMasterClass) {
      return 'introduction_call';
    }
    if (eligibility.canBookMasterClass && !eligibility.canBookIntroduction) {
      return 'master_class';
    }
    if (_type == 'master_class' && !eligibility.canBookMasterClass && eligibility.canBookIntroduction) {
      return 'introduction_call';
    }
    if (_type == 'introduction_call' && !eligibility.canBookIntroduction && eligibility.canBookMasterClass) {
      return 'master_class';
    }
    return _type ?? (eligibility.canBookIntroduction ? 'introduction_call' : 'master_class');
  }

  @override
  Widget build(BuildContext context) {
    final eligibility = ref.watch(studentEligibilityProvider);
    final teachers = ref.watch(studentBookingTeachersProvider);
    final bookings = ref.watch(studentBookingsProvider);
    SessionBookingDto? current;
    if (widget.bookingId != null) {
      final items = bookings.asData?.value ?? const <SessionBookingDto>[];
      for (final item in items) {
        if (item.id == widget.bookingId) {
          current = item;
          break;
        }
      }
    }

    return StudentScaffold(
      title: _reschedule ? 'Reschedule' : 'Book session',
      body: eligibility.when(
        skipLoadingOnReload: true,
        loading: () => const AcademySkeleton(height: 220),
        error: (_, _) => AcademyError(onRetry: () => ref.invalidate(studentEligibilityProvider)),
        data: (state) {
          final type = _resolvedType(state);
          final canChooseType = !_reschedule && state.canBookIntroduction && state.canBookMasterClass && !_typeLocked;
          final isMobile = MediaQuery.sizeOf(context).width < 768;
          return ListView(
            padding: EdgeInsets.only(bottom: isMobile ? 24 : 48),
            children: [
              Text(
                _reschedule ? 'Reschedule your session' : bookingActionLabel(type),
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.w800,
                  color: Academy.ink,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                type == 'introduction_call'
                    ? (state.introductionLastChance
                        ? 'This is your last chance to complete the Introduction Call. Please be available at the booked time. If this slot is missed, another interview cannot be booked.'
                        : 'Choose a teacher, then pick one available time for your Introduction Call.')
                    : 'Choose a teacher, then pick one available time for your Master Class.',
                style: TextStyle(
                  color: Academy.muted,
                  height: 1.4,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
              if (_reschedule && current != null) ...[
                SizedBox(height: isMobile ? 12 : 20),
                AcademySurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AcademyLabel('Current booking'),
                      const SizedBox(height: 8),
                      Text(current.teacherName ?? 'Teacher', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(formatPrettyDate(current.date)),
                      Text(formatHm(current.start)),
                    ],
                  ),
                ),
              ],
              if (canChooseType) ...[
                SizedBox(height: isMobile ? 14 : 24),
                _TypeStep(
                  canIntro: state.canBookIntroduction,
                  canMaster: state.canBookMasterClass,
                  introLastChance: state.introductionLastChance,
                  selected: type,
                  onSelect: (value) => setState(() {
                    _type = value;
                    _start = null;
                  }),
                ),
              ],
              SizedBox(height: isMobile ? 14 : 24),
              const AcademyLabel('Your faculty'),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                'Tap a teacher to continue. Their available times will appear below.',
                style: TextStyle(
                  color: Academy.muted,
                  height: 1.4,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 16),
              teachers.when(
                skipLoadingOnReload: true,
                loading: () => AcademySkeleton(height: isMobile ? 120 : 220),
                error: (_, _) => AcademyError(onRetry: () => ref.invalidate(studentBookingTeachersProvider)),
                data: (items) => TeacherPicker(
                  teachers: items,
                  levelLabel: items.isEmpty
                      ? 'Your level'
                      : (items.first.assignedLevels.isEmpty ? 'Your level' : items.first.assignedLevels.first),
                  selectedTeacherId: _teacher?.id,
                  onSelect: (teacher) => setState(() {
                    _teacher = teacher;
                    _date ??= DateTime.now();
                    _start = null;
                  }),
                ),
              ),
              if (_teacher != null) ...[
                SizedBox(height: isMobile ? 16 : 28),
                _TimeStep(
                  teacherName: _teacher!.fullName,
                  teacherId: _teacher!.id,
                  date: formatScheduleDate(_date ?? DateTime.now()),
                  selected: _start,
                  onSelect: (start) => setState(() => _start = start),
                  onChangeDate: () async {
                    final today = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date ?? today,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 120)),
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                        _start = null;
                      });
                    }
                  },
                ),
              ],
              if (_teacher != null && _date != null && _start != null) ...[
                const SizedBox(height: 16),
                _SummaryStep(
                  type: type,
                  lastChance: type == 'introduction_call' && state.introductionLastChance,
                  teacher: _teacher,
                  date: _date,
                  start: _start,
                  busy: _saving,
                  onBack: () => setState(() => _start = null),
                  onConfirm: () {
                    _type = type;
                    _confirm();
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirm() async {
    if (_teacher == null || _date == null || _start == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(scheduleRepositoryProvider);
      final date = formatScheduleDate(_date!);
      SessionBookingDto? confirmed;
      if (widget.bookingId == null) {
        confirmed = await repo.createStudentBooking(
          teacherId: _teacher!.id,
          type: _type ?? 'introduction_call',
          date: date,
          start: _start!,
        );
      } else {
        confirmed = await repo.rescheduleStudentBooking(
          bookingId: widget.bookingId!,
          teacherId: _teacher!.id,
          date: date,
          start: _start!,
        );
      }
      ref.invalidate(studentBookingsProvider);
      ref.invalidate(studentEligibilityProvider);
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      final type = _type ?? 'introduction_call';
      final booking = confirmed;
      Future<void> Function()? onJoin;
      if (booking != null) {
        final confirmedBooking = booking;
        onJoin = () async {
          await ref.read(scheduleRepositoryProvider).studentJoinClass(confirmedBooking.id);
          ref.invalidate(studentBookingsProvider);
          final url = confirmedBooking.meetingUrl;
          if (url != null && url.isNotEmpty) {
            await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
          }
        };
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _BookingConfirmedDialog(
          reschedule: _reschedule,
          type: type,
          teacherName: _teacher!.fullName,
          date: date,
          start: _start!,
          meetingUrl: booking?.meetingUrl,
          canJoin: booking?.attendance?.canJoin == true,
          onJoin: onJoin,
          onContinue: () => Navigator.of(dialogContext).pop(),
        ),
      );
      if (mounted) {
        context.go(RoutePaths.studentBookings);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showFailure(context, error);
      }
    }
  }
}

class _TypeStep extends StatelessWidget {
  const _TypeStep({
    required this.canIntro,
    required this.canMaster,
    required this.onSelect,
    this.introLastChance = false,
    this.selected,
  });

  final bool canIntro;
  final bool canMaster;
  final bool introLastChance;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AcademyLabel('What would you like to book?'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 720;
            final cards = <Widget>[
              if (canIntro)
                _ChoiceCard(
                  title: 'Introduction Call',
                  body: introLastChance
                      ? 'Last chance: please be available for this interview. A missed slot cannot be booked again.'
                      : 'Meet your Master Teacher. If this call is missed, you get one last chance to reschedule.',
                  selected: selected == 'introduction_call',
                  onTap: () => onSelect('introduction_call'),
                ),
              if (canMaster)
                _ChoiceCard(
                  title: 'Master Class',
                  body: 'Your focused monthly session.',
                  selected: selected == 'master_class',
                  onTap: () => onSelect('master_class'),
                ),
            ];
            if (stacked) {
              return Column(
                children: [
                  for (final card in cards) ...[card, const SizedBox(height: 12)],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.body,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return AcademySurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: Academy.ink,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            body,
            style: TextStyle(
              color: Academy.muted,
              height: 1.4,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          if (selected) ...[
            SizedBox(height: isMobile ? 6 : 8),
            const Text('Selected', style: TextStyle(color: Brand.goldDark, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _TimeStep extends ConsumerWidget {
  const _TimeStep({
    required this.teacherName,
    required this.teacherId,
    required this.date,
    required this.selected,
    required this.onSelect,
    required this.onChangeDate,
  });

  final String teacherName;
  final String teacherId;
  final String date;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onChangeDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(studentAvailabilityProvider((teacherId: teacherId, date: date)));
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Available slots · $date',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Brand.navy),
              ),
              AcademyButton(
                outlined: true,
                icon: Icons.calendar_today_outlined,
                label: 'Change date',
                onPressed: onChangeDate,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'With $teacherName',
            style: const TextStyle(color: Academy.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap one available time. Booked slots are red and cannot be selected.',
            style: TextStyle(color: Brand.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          day.when(
            skipLoadingOnReload: true,
            loading: () => const AcademySkeleton(height: 120),
            error: (_, _) => AcademyError(
              onRetry: () => ref.invalidate(studentAvailabilityProvider((teacherId: teacherId, date: date))),
            ),
            data: (value) {
              if (value.slots.isEmpty) {
                return const Text('No times on this date. Please choose another date.');
              }
              return SlotGrid(
                slots: value.slots,
                selectedStart: selected,
                colorFor: studentSlotColor,
                onSelectAvailable: onSelect,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.type,
    required this.teacher,
    required this.date,
    required this.start,
    required this.busy,
    required this.onBack,
    required this.onConfirm,
    this.lastChance = false,
  });

  final String type;
  final bool lastChance;
  final TeacherDto? teacher;
  final DateTime? date;
  final String? start;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final end = start == null ? '' : _endFrom(start!);
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel('Booking summary'),
          const SizedBox(height: 12),
          Text(
            type == 'master_class' ? 'Master Class' : 'Introduction Call',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Academy.ink),
          ),
          const SizedBox(height: 16),
          _line('Teacher', teacher?.fullName ?? '—'),
          _line('Date', date == null ? '—' : formatPrettyDate(formatScheduleDate(date!))),
          _line('Time', start == null ? '—' : '${formatHm(start!)} – ${formatHm(end)}'),
          if (lastChance) ...[
            const SizedBox(height: 12),
            const Text(
              'Last chance: please be available at this time. If this Introduction Call is missed, you cannot book another interview.',
              style: TextStyle(fontWeight: FontWeight.w700, height: 1.4, color: Color(0xFFB45309)),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AcademyButton(outlined: true, label: 'Change time', onPressed: busy ? null : onBack),
              AcademyButton(
                label: type == 'master_class' ? 'Confirm Master Class' : 'Confirm Introduction',
                busy: busy,
                onPressed: busy ? null : onConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: const TextStyle(color: Academy.muted))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Academy.ink))),
        ],
      ),
    );
  }

  String _endFrom(String start) {
    final parts = start.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final total = hour * 60 + minute + 30;
    final endHour = (total ~/ 60).toString().padLeft(2, '0');
    final endMinute = (total % 60).toString().padLeft(2, '0');
    return '$endHour:$endMinute';
  }
}

class _BookingConfirmedDialog extends StatelessWidget {
  const _BookingConfirmedDialog({
    required this.reschedule,
    required this.type,
    required this.teacherName,
    required this.date,
    required this.start,
    required this.onContinue,
    this.meetingUrl,
    this.canJoin = false,
    this.onJoin,
  });

  final bool reschedule;
  final String type;
  final String teacherName;
  final String date;
  final String start;
  final VoidCallback onContinue;
  final String? meetingUrl;
  final bool canJoin;
  final Future<void> Function()? onJoin;

  @override
  Widget build(BuildContext context) {
    final session = type == 'master_class' ? 'Master Class' : 'Introduction Call';
    final title = reschedule ? 'Session rescheduled' : '$session confirmed';
    final body = reschedule
        ? 'Your $session has been moved to the time below.'
        : 'Your $session is booked. We look forward to seeing you.';
    final end = _slotEnd(start);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Brand.gold.withValues(alpha: 0.35), width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.gold.withValues(alpha: 0.18),
                  border: Border.all(color: Brand.gold.withValues(alpha: 0.7), width: 1.5),
                ),
                child: const Icon(Icons.check_rounded, color: Brand.navy, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Academy.ink),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Academy.muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detail('Session', session),
                    _detail('Teacher', teacherName),
                    _detail('Date', formatPrettyDate(date)),
                    _detail('Time', '${formatHm(start)} – ${formatHm(end)}', last: true),
                  ],
                ),
              ),
              if ((meetingUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'You and your teacher join the same Google Meet for this day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Academy.muted, height: 1.45),
                ),
                const SizedBox(height: 12),
                if (canJoin && onJoin != null)
                  JoinMeetButton(
                    meetingUrl: meetingUrl,
                    label: 'Join Google Meet',
                    onPressed: onJoin,
                  )
                else
                  Text(
                    type == 'master_class'
                        ? 'Join available 2 minutes before class'
                        : 'Join available 2 minutes before the call',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Academy.muted, fontSize: 13, height: 1.4),
                  ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: AcademyButton(label: 'View my sessions', onPressed: onContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(color: Academy.muted, fontSize: 13))),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Academy.ink)),
          ),
        ],
      ),
    );
  }
}

String _slotEnd(String start) {
  final parts = start.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final total = hour * 60 + minute + 30;
  return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}
