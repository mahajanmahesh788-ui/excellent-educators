import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/attendance_report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

int _sessionLane(SessionBookingDto booking, DateTime now) {
  if (booking.attendance?.reportSubmitted == true) {
    return 2;
  }
  if (booking.isCompleted || booking.attendance?.classCompleted == true) {
    return 3;
  }
  if (booking.isOngoingAt(now)) {
    return 1;
  }
  final start = booking.startsAt;
  if (start != null && start.isAfter(now)) {
    return 0;
  }
  return 4;
}

Color _sessionBorderColor(SessionBookingDto booking, DateTime now) {
  if (booking.attendance?.reportSubmitted == true) {
    return const Color(0xFFF87171);
  }
  if (booking.isCompleted || booking.attendance?.classCompleted == true) {
    return const Color(0xFF22C55E);
  }
  if (booking.isOngoingAt(now)) {
    return const Color(0xFFF97316);
  }
  return const Color(0xFF94A3B8);
}

class TeacherDaySchedulePage extends ConsumerWidget {
  const TeacherDaySchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(teacherDayScheduleDateProvider);
    final day = ref.watch(teacherDayScheduleProvider);
    final today = scheduleToday();
    final tomorrow = today.add(const Duration(days: 1));
    final selected = DateTime.tryParse(date);
    final isToday = selected != null && scheduleDateOnly(selected) == today;
    final isTomorrow = selected != null && scheduleDateOnly(selected) == tomorrow;

    void setDate(DateTime target) {
      ref.read(teacherDayScheduleDateProvider.notifier).state = formatScheduleDate(target);
    }

    void stepDay(int delta) {
      final current = selected ?? today;
      setDate(current.add(Duration(days: delta)));
    }

    return AppScaffold(
      title: 'Today schedule',
      body: AnimatedPortalBackdrop(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Hero Date Navigator Header
            _TeacherDayHero(
              date: date,
              selected: selected,
              isToday: isToday,
              isTomorrow: isTomorrow,
              today: today,
              tomorrow: tomorrow,
              onSelectToday: () => setDate(today),
              onSelectTomorrow: () => setDate(tomorrow),
              onPreviousDay: () => stepDay(-1),
              onNextDay: () => stepDay(1),
              onPickDate: () async {
                final initial = selected == null || scheduleDateOnly(selected).isBefore(today)
                    ? today
                    : scheduleDateOnly(selected);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(today.year - 1),
                  lastDate: DateTime(today.year + 2),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Brand.navy,
                          onPrimary: Colors.white,
                          secondary: Brand.gold,
                          surface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setDate(picked);
                }
              },
            ),

            const SizedBox(height: 18),

            // 2. Schedule Feed (Metrics Bar + Animated Session Cards)
            AsyncBody(
              value: day,
              onRetry: () => ref.invalidate(teacherDayScheduleProvider),
              builder: (schedule) {
                final now = DateTime.now();
                final bookings = [...schedule.bookings]..sort((a, b) {
                  final rank = _sessionLane(a, now).compareTo(_sessionLane(b, now));
                  if (rank != 0) {
                    return rank;
                  }
                  return a.start.compareTo(b.start);
                });

                final completedCount = bookings.where((b) => b.isCompleted).length;
                final scheduledCount = bookings.where((b) => !b.isCompleted && !b.isCancelled).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metrics Strip
                    _DayOverviewStats(
                      totalCount: bookings.length,
                      completedCount: completedCount,
                      upcomingCount: scheduledCount,
                    ),

                    const SizedBox(height: 20),

                    // Section Heading
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Brand.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isToday ? "Today's Sessions" : 'Scheduled Sessions',
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
                            '${bookings.length} booked',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Brand.navy,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    if (bookings.isEmpty)
                      _EmptyScheduleCard(
                        isToday: isToday,
                        date: date,
                        onCheckTomorrow: () => setDate(tomorrow),
                      )
                    else
                      for (int i = 0; i < bookings.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ExecutiveBookingCard(
                            booking: bookings[i],
                            index: i,
                            onRefresh: () => ref.invalidate(teacherDayScheduleProvider),
                          ),
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Hero Date Navigator Component
/// ---------------------------------------------------------------------------
class _TeacherDayHero extends StatelessWidget {
  const _TeacherDayHero({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.isTomorrow,
    required this.today,
    required this.tomorrow,
    required this.onSelectToday,
    required this.onSelectTomorrow,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
  });

  final String date;
  final DateTime? selected;
  final bool isToday;
  final bool isTomorrow;
  final DateTime today;
  final DateTime tomorrow;
  final VoidCallback onSelectToday;
  final VoidCallback onSelectTomorrow;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final pretty = formatPrettyDate(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        border: Border.all(color: Brand.gold.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge + Gold Accent
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Brand.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.event_note_rounded, size: 18, color: Brand.gold),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF059669).withValues(alpha: 0.25)
                      : (isTomorrow
                          ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isToday
                        ? const Color(0xFF10B981)
                        : (isTomorrow ? const Color(0xFF60A5FA) : Colors.white24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isToday) ...[
                      const _PulsingLiveDot(color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isToday
                          ? "TODAY'S SCHEDULE"
                          : (isTomorrow ? "TOMORROW'S AGENDA" : "SCHEDULE CALENDAR"),
                      style: TextStyle(
                        color: isToday
                            ? const Color(0xFF6EE7B7)
                            : (isTomorrow ? const Color(0xFF93C5FD) : Colors.white),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Date Headline
          Text(
            pretty,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitor upcoming student sessions, launch live meeting rooms, and record attendance.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // Segmented Date Bar
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Previous Day
                IconButton(
                  onPressed: onPreviousDay,
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  tooltip: 'Previous day',
                  visualDensity: VisualDensity.compact,
                ),

                // Today Pill
                _DateSelectorPill(
                  label: 'Today',
                  isSelected: isToday,
                  icon: Icons.today_rounded,
                  onTap: onSelectToday,
                ),

                // Tomorrow Pill
                _DateSelectorPill(
                  label: 'Tomorrow',
                  isSelected: isTomorrow,
                  icon: Icons.event_rounded,
                  onTap: onSelectTomorrow,
                ),

                // Date Picker Button
                _DateSelectorPill(
                  label: date,
                  isSelected: !isToday && !isTomorrow,
                  icon: Icons.calendar_month_rounded,
                  onTap: onPickDate,
                ),

                // Next Day
                IconButton(
                  onPressed: onNextDay,
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  tooltip: 'Next day',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelectorPill extends StatelessWidget {
  const _DateSelectorPill({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Brand.gold : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Brand.gold : Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Brand.gold.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
                  color: isSelected ? Brand.navy : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Brand.navy : Colors.white,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Overview KPI Metrics Strip
/// ---------------------------------------------------------------------------
class _DayOverviewStats extends StatelessWidget {
  const _DayOverviewStats({
    required this.totalCount,
    required this.completedCount,
    required this.upcomingCount,
  });

  final int totalCount;
  final int completedCount;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              title: 'Total Booked',
              value: '$totalCount',
              subtitle: totalCount == 1 ? '1 student session' : '$totalCount student sessions',
              icon: Icons.calendar_today_rounded,
              accentColor: Brand.navy,
              iconBg: Brand.navy.withValues(alpha: 0.08),
              width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3,
            ),
            _MetricCard(
              title: 'Completed',
              value: '$completedCount',
              subtitle: completedCount == 0 ? 'None finished yet' : '$completedCount conducted',
              icon: Icons.check_circle_rounded,
              accentColor: const Color(0xFF059669),
              iconBg: const Color(0xFFECFDF5),
              width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3,
            ),
            _MetricCard(
              title: 'Upcoming / Ready',
              value: '$upcomingCount',
              subtitle: upcomingCount == 0 ? 'No pending sessions' : '$upcomingCount ready to meet',
              icon: Icons.access_time_filled_rounded,
              accentColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFFFBEB),
              width: isCompact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatefulWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.iconBg,
    required this.width,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color iconBg;
  final double width;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: widget.width,
        padding: const EdgeInsets.all(16),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? widget.accentColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.12)
                  : Brand.navy.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: widget.accentColor,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Executive Animated Booking Card
/// ---------------------------------------------------------------------------
class _ExecutiveBookingCard extends ConsumerStatefulWidget {
  const _ExecutiveBookingCard({
    required this.booking,
    required this.index,
    required this.onRefresh,
  });

  final SessionBookingDto booking;
  final int index;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_ExecutiveBookingCard> createState() => _ExecutiveBookingCardState();
}

class _ExecutiveBookingCardState extends ConsumerState<_ExecutiveBookingCard> {
  bool _isHovered = false;
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isMasterClass = booking.type == 'master_class';
    final isCompleted = booking.status == 'completed';
    final isCancelled = booking.status == 'cancelled';

    // Parse date for two-tone badge
    final dt = DateTime.tryParse(booking.date);
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final month = dt != null && dt.month >= 1 && dt.month <= 12 ? months[dt.month - 1] : 'DATE';
    final day = dt != null ? '${dt.day}' : '—';
    final weekday = dt != null && dt.weekday >= 1 && dt.weekday <= 7 ? weekdays[dt.weekday - 1] : '';

    final canJoin = booking.attendance?.canJoin ?? false;
    final canWhatsApp = booking.attendance?.canWhatsAppStudent ?? false;
    final borderColor = _sessionBorderColor(booking, DateTime.now());
    final studentInitial = (booking.studentName?.isNotEmpty ?? false)
        ? booking.studentName!.substring(0, 1).toUpperCase()
        : 'S';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered ? borderColor : borderColor.withValues(alpha: 0.9),
            width: _isHovered ? 2.0 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: _isHovered ? 0.22 : 0.12),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: booking.studentId.isEmpty
                  ? null
                  : () => context.go(
                        '${RoutePaths.teacherScheduleStudentFor(booking.studentId)}?slot=${Uri.encodeComponent('${formatHm(booking.start)} – ${formatHm(booking.end)}')}',
                      ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 660;

                    // The left Calendar Date Pillar
                    final calendarBlock = Container(
                      width: 66,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
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
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            decoration: const BoxDecoration(
                              color: Brand.navy,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              month,
                              style: const TextStyle(
                                color: Brand.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    day,
                                    style: const TextStyle(
                                      color: Brand.navy,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                  if (weekday.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      weekday,
                                      style: const TextStyle(
                                        color: Brand.muted,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
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

                    // Student & Session Details Column
                    final detailsColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Session Type Badge + Status Pill
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Session Type
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isMasterClass
                                      ? [const Color(0xFF0A1E34), const Color(0xFF163C65)]
                                      : [const Color(0xFF0F4A5E), const Color(0xFF16627C)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMasterClass ? Icons.stars_rounded : Icons.handshake_rounded,
                                    size: 13,
                                    color: Brand.gold,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isMasterClass
                                        ? 'Master Class · Week ${booking.learningWeek ?? 1}'
                                        : 'Introduction Call',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status Pill
                            if (canJoin)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _PulsingLiveDot(color: Color(0xFF10B981)),
                                    SizedBox(width: 6),
                                    Text(
                                      'READY TO JOIN',
                                      style: TextStyle(
                                        color: Color(0xFF047857),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10.5,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Color(0xFF334155),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isCancelled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: const Text(
                                  'Cancelled',
                                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF2563EB)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Scheduled',
                                      style: TextStyle(
                                        color: Color(0xFF1D4ED8),
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

                        // Student Name & Time slot
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Initial Avatar
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: Brand.navy,
                              child: Text(
                                studentInitial,
                                style: const TextStyle(
                                  color: Brand.gold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        booking.studentName ?? 'Student',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Brand.navy,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Brand.gold),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${formatHm(booking.start)} – ${formatHm(booking.end)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      if (booking.attemptNumber != null) ...[
                                        const SizedBox(width: 8),
                                        const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Attempt ${booking.attemptNumber}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Last Chance alert
                        if (booking.attendance?.isLastChance == true &&
                            (booking.attendance?.lastChanceMessage ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFD97706)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    booking.attendance!.lastChanceMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF92400E),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );

                    // Actions Row
                    final actionsRow = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // History Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Brand.navy,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: booking.studentId.isEmpty
                              ? null
                              : () => context.go(
                                    '${RoutePaths.teacherScheduleStudentFor(booking.studentId)}?slot=${Uri.encodeComponent('${formatHm(booking.start)} – ${formatHm(booking.end)}')}',
                                  ),
                          icon: const Icon(Icons.history_edu_rounded, size: 14, color: Brand.goldDark),
                          label: const Text('Briefing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),

                        // Join Call Button
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: canJoin ? const Color(0xFF047857) : Brand.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            elevation: canJoin ? 3 : 1,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: isCancelled || (booking.meetingUrl ?? '').isEmpty || _isBusy
                              ? null
                              : () async {
                                  setState(() => _isBusy = true);
                                  try {
                                    await ref.read(scheduleRepositoryProvider).teacherJoinClass(booking.id);
                                    widget.onRefresh();
                                    final uri = Uri.parse(booking.meetingUrl!);
                                    await launchUrl(uri, webOnlyWindowName: '_blank');
                                  } finally {
                                    if (mounted) setState(() => _isBusy = false);
                                  }
                                },
                          icon: Icon(
                            isCompleted ? Icons.check_circle_outline_rounded : Icons.videocam_rounded,
                            size: 15,
                            color: canJoin ? Colors.white : Brand.gold,
                          ),
                          label: Text(
                            isCompleted
                                ? 'Completed'
                                : (isMasterClass ? 'Join Class' : 'Join Call'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                        ),

                        // WhatsApp Student
                        Tooltip(
                          message: canWhatsApp ? 'Message student on WhatsApp' : (booking.attendance?.whatsappHint ?? 'Available shortly before session starts'),
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: canWhatsApp ? const Color(0xFFE8F8EE) : const Color(0xFFF1F5F9),
                              foregroundColor: canWhatsApp ? const Color(0xFF128C7E) : const Color(0xFF94A3B8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                                side: BorderSide(
                                  color: canWhatsApp ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: !canWhatsApp || _isBusy
                                ? null
                                : () async {
                                    try {
                                      final ready = await ref
                                          .read(scheduleRepositoryProvider)
                                          .teacherWhatsAppStudent(booking.id);
                                      widget.onRefresh();
                                      final uri = Uri.parse(ready.whatsappUrl);
                                      await launchUrl(uri, webOnlyWindowName: '_blank');
                                    } catch (error) {
                                      if (context.mounted) {
                                        showFailure(context, error);
                                      }
                                    }
                                  },
                            icon: Icon(
                              Icons.chat_rounded,
                              size: 14,
                              color: canWhatsApp ? const Color(0xFF25D366) : const Color(0xFF94A3B8),
                            ),
                            label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ),

                        if (booking.attendance?.canRateStudent == true ||
                            booking.attendance?.canEditStudentRating == true)
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF3C7),
                              foregroundColor: const Color(0xFFB45309),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: booking.studentId.isEmpty
                                ? null
                                : () {
                                    final attendance = booking.attendance;
                                    if (attendance?.canEditStudentRating == true &&
                                        attendance?.monthlyFeedbackId != null &&
                                        attendance!.monthlyFeedbackId!.isNotEmpty) {
                                      context.go(
                                        RoutePaths.masterTeacherFeedbackEditFor(
                                          booking.studentId,
                                          attendance.monthlyFeedbackId!,
                                        ),
                                      );
                                      return;
                                    }
                                    context.go(RoutePaths.masterTeacherFeedbackNewFor(booking.studentId));
                                  },
                            icon: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                            label: Text(
                              booking.attendance?.canEditStudentRating == true ? 'Edit rating' : 'Rate',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                            ),
                          ),

                        // Student didn't join
                        if (booking.attendance?.canReportStudentDidNotJoin == true)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () async {
                              final session = booking.type == 'master_class' ? 'class' : 'Introduction Call';
                              final message = await showAttendanceReportDialog(
                                context,
                                title: "Student didn't join",
                                hint: 'Tell Admin what happened on this $session:',
                              );
                              if (message == null) return;
                              await ref.read(scheduleRepositoryProvider).teacherReportStudent(booking.id, message);
                              widget.onRefresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Report sent to Admin')),
                                );
                              }
                            },
                            icon: const Icon(Icons.person_off_rounded, size: 13, color: Color(0xFFDC2626)),
                            label: const Text("Student didn't join", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                          ),

                        // Report sent badge
                        if (booking.attendance?.reportSubmitted == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text(
                                  'Report submitted',
                                  style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w700, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              calendarBlock,
                              const SizedBox(width: 14),
                              Expanded(child: detailsColumn),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          actionsRow,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        calendarBlock,
                        const SizedBox(width: 16),
                        Expanded(child: detailsColumn),
                        const SizedBox(width: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: actionsRow,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Pulsing Live Status Dot
/// ---------------------------------------------------------------------------
class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot({required this.color});
  final Color color;

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: 8 + (t * 2),
          height: 8 + (t * 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3 + (t * 0.4)),
                blurRadius: 4 + (t * 4),
                spreadRadius: t * 1.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Animated Empty State Card
/// ---------------------------------------------------------------------------
class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({
    required this.isToday,
    required this.date,
    required this.onCheckTomorrow,
  });

  final bool isToday;
  final String date;
  final VoidCallback onCheckTomorrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Brand.navy.withValues(alpha: 0.05),
              border: Border.all(color: Brand.gold.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.event_busy_rounded, size: 34, color: Brand.navy),
          ),
          const SizedBox(height: 18),
          Text(
            isToday ? 'No Session Bookings Today' : 'No Bookings on This Date',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Brand.navy,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              isToday
                  ? 'There are no student sessions booked on your calendar today. Check tomorrow or pick an upcoming date to see your schedule.'
                  : 'There are no sessions booked for ${formatPrettyDate(date)}. Use the date navigator above to check other days.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onCheckTomorrow,
              icon: const Icon(Icons.event_rounded, size: 16, color: Brand.gold),
              label: const Text("Check Tomorrow's Schedule", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
