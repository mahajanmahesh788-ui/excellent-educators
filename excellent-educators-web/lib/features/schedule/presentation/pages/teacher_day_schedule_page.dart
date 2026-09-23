import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
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
import 'package:excellent_educators_web/core/constants/app_strings.dart';

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

bool _teacherSessionIsPast(SessionBookingDto booking, DateTime now) {
  if (booking.isCancelled || booking.isCompleted || booking.attendance?.classCompleted == true) {
    return true;
  }
  return booking.hasEndedAt(now);
}

class TeacherDaySchedulePage extends ConsumerStatefulWidget {
  const TeacherDaySchedulePage({super.key});

  @override
  ConsumerState<TeacherDaySchedulePage> createState() => _TeacherDaySchedulePageState();
}

class _TeacherDaySchedulePageState extends ConsumerState<TeacherDaySchedulePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final date = ref.watch(teacherDayScheduleDateProvider);
    final day = ref.watch(teacherDayScheduleProvider);
    final today = scheduleToday();
    final tomorrow = today.add(const Duration(days: 1));
    final selected = DateTime.tryParse(date);
    final isToday = selected != null && scheduleDateOnly(selected) == today;
    final isTomorrow = selected != null && scheduleDateOnly(selected) == tomorrow;

    void setDate(DateTime target) {
      final only = scheduleDateOnly(target);
      ref.read(teacherDayScheduleDateProvider.notifier).state = formatScheduleDate(target);
      setState(() {
        _selectedTab = only.isBefore(today) ? 1 : 0;
      });
    }

    void stepDay(int delta) {
      final current = selected ?? today;
      setDate(current.add(Duration(days: delta)));
    }

    return AppScaffold(
      title: AppStrings.todaySchedule,
      body: AnimatedPortalBackdrop(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 12 : 16,
          ),
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

                final current = bookings.where((item) {
                  if (item.isCancelled) {
                    return false;
                  }
                  return !_teacherSessionIsPast(item, now);
                }).toList();
                final past = bookings.where((item) => _teacherSessionIsPast(item, now)).toList()
                  ..sort((a, b) => b.start.compareTo(a.start));
                final activeList = _selectedTab == 0 ? current : past;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 620;
                        final sectionTitle = Row(
                          mainAxisSize: MainAxisSize.min,
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
                              _selectedTab == 0 ? AppStrings.current3 : AppStrings.pastSessions,
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
                        final switcher = _TeacherSessionSwitcher(
                          selectedIndex: _selectedTab,
                          currentCount: current.length,
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
                          children: [
                            sectionTitle,
                            const Spacer(),
                            switcher,
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    if (activeList.isEmpty)
                      _EmptyScheduleCard(
                        isToday: isToday,
                        isPastTab: _selectedTab == 1,
                        date: date,
                        onCheckTomorrow: () => setDate(tomorrow),
                      )
                    else
                      for (int i = 0; i < activeList.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ExecutiveBookingCard(
                            booking: activeList[i],
                            index: i,
                            isPast: _selectedTab == 1,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final pretty = formatPrettyDate(date);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 14 : 20),
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
            border: Border.all(color: Brand.gold.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Status badge + Gold Accent
              Row(
                children: [
                  Container(
                    width: isNarrow ? 28 : 32,
                    height: isNarrow ? 28 : 32,
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
                    ),
                    child: Icon(Icons.event_note_rounded, size: isNarrow ? 15 : 18, color: Brand.gold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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
                          const SizedBox(width: 5),
                        ],
                        Text(
                          isToday
                              ? AppStrings.todaySSchedule
                              : (isTomorrow ? AppStrings.tomorrowSAgenda : AppStrings.scheduleCalendar),
                          style: TextStyle(
                            color: isToday
                                ? const Color(0xFF6EE7B7)
                                : (isTomorrow ? const Color(0xFF93C5FD) : Colors.white),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isNarrow ? 10 : 14),

              // Date Headline
              Text(
                pretty,
                style: TextStyle(
                  fontSize: isNarrow ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                AppStrings.monitorUpcomingStudentSessionsLaunchLiveMeetingRoomsAndRecord,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: isNarrow ? 12 : 13,
                  height: 1.35,
                ),
              ),

              SizedBox(height: isNarrow ? 12 : 16),

              // Segmented Date Bar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Previous Day
                    IconButton(
                      onPressed: onPreviousDay,
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                      tooltip: AppStrings.previousDay,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),

                    // Today Pill
                    _DateSelectorPill(
                      label: AppStrings.today,
                      isSelected: isToday,
                      icon: Icons.today_rounded,
                      onTap: onSelectToday,
                    ),

                    // Tomorrow Pill
                    _DateSelectorPill(
                      label: AppStrings.tomorrow,
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
                      tooltip: AppStrings.nextDay,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  size: 13,
                  color: isSelected ? Brand.navy : Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Brand.navy : Colors.white,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
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

class _TeacherSessionSwitcher extends StatelessWidget {
  const _TeacherSessionSwitcher({
    required this.selectedIndex,
    required this.currentCount,
    required this.pastCount,
    required this.onTap,
  });

  final int selectedIndex;
  final int currentCount;
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
          _TeacherPillItem(
            label: AppStrings.current3,
            count: currentCount,
            icon: Icons.calendar_today_rounded,
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(width: 4),
          _TeacherPillItem(
            label: AppStrings.pastSessions,
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

class _TeacherPillItem extends StatelessWidget {
  const _TeacherPillItem({
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
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? Brand.navy : Brand.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Brand.navy : Brand.muted,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Brand.navy.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Brand.navy : Brand.muted,
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
/// Executive Animated Booking Card
/// ---------------------------------------------------------------------------
class _ExecutiveBookingCard extends ConsumerStatefulWidget {
  const _ExecutiveBookingCard({
    required this.booking,
    required this.index,
    required this.onRefresh,
    this.isPast = false,
  });

  final SessionBookingDto booking;
  final int index;
  final VoidCallback onRefresh;
  final bool isPast;

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
    const months = [AppStrings.jan, AppStrings.feb, AppStrings.mar, AppStrings.apr, AppStrings.may, AppStrings.jun, AppStrings.jul, AppStrings.aug, AppStrings.sep, AppStrings.oct, AppStrings.nov, AppStrings.dec];
    const weekdays = [AppStrings.mon, AppStrings.tue, AppStrings.wed, AppStrings.thu, AppStrings.fri, AppStrings.sat, AppStrings.sun];
    final month = dt != null && dt.month >= 1 && dt.month <= 12 ? months[dt.month - 1] : AppStrings.date;
    final day = dt != null ? '${dt.day}' : '—';
    final weekday = dt != null && dt.weekday >= 1 && dt.weekday <= 7 ? weekdays[dt.weekday - 1] : '';

    final canJoin = !widget.isPast && (booking.attendance?.canJoin ?? false);
    final showJoin = !widget.isPast && !isCancelled && (booking.meetingUrl ?? '').isNotEmpty;
    final canWhatsApp = booking.attendance?.canWhatsAppStudent ?? false;
    final borderColor = _sessionBorderColor(booking, DateTime.now());
    final studentInitial = (booking.studentName?.isNotEmpty ?? false)
        ? booking.studentName!.substring(0, 1).toUpperCase()
        : 'S';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 660;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isNarrow ? 14 : 18),
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
              borderRadius: BorderRadius.circular(isNarrow ? 14 : 18),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: booking.studentId.isEmpty
                      ? null
                      : () => context.go(
                            '${RoutePaths.teacherScheduleStudentFor(booking.studentId)}?slot=${Uri.encodeComponent('${formatHm(booking.start)} – ${formatHm(booking.end)}')}',
                          ),
                  child: Padding(
                    padding: EdgeInsets.all(isNarrow ? 12 : 18),
                    child: Builder(
                      builder: (context) {
                        // The left Calendar Date Pillar
                        final calendarBlock = Container(
                          width: isNarrow ? 54 : 66,
                          height: isNarrow ? 60 : 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(isNarrow ? 11 : 14),
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
                                        : AppStrings.introductionCall,
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
                            if (widget.isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  isCompleted ? AppStrings.completed : AppStrings.past,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            else if (canJoin)
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
                                      AppStrings.readyToJoin,
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
                                      AppStrings.completed,
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
                                  AppStrings.cancelled,
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
                                      AppStrings.scheduled,
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

                        const SizedBox(height: 8),

                        // Student Name & Time slot
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Initial Avatar
                            CircleAvatar(
                              radius: isNarrow ? 16 : 19,
                              backgroundColor: Brand.navy,
                              child: Text(
                                studentInitial,
                                style: TextStyle(
                                  color: Brand.gold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isNarrow ? 13 : 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        booking.studentName ?? AppStrings.student,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: isNarrow ? 14.5 : 16,
                                          color: Brand.navy,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Brand.gold),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${formatHm(booking.start)} – ${formatHm(booking.end)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: isNarrow ? 11.5 : 12.5,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                      if (booking.attemptNumber != null) ...[
                                        const SizedBox(width: 6),
                                        const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Attempt ${booking.attemptNumber}',
                                          style: TextStyle(fontSize: isNarrow ? 11 : 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
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
                          label: const Text(AppStrings.briefing, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),

                        if (showJoin)
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
                                    await launchUrl(uri, webOnlyWindowName: AppStrings.blank);
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
                                ? AppStrings.completed
                                : (isMasterClass ? AppStrings.joinClass : AppStrings.joinCall),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                        ),

                        // WhatsApp Student
                        Tooltip(
                          message: canWhatsApp ? AppStrings.messageStudentOnWhatsapp : (booking.attendance?.whatsappHint ?? AppStrings.availableShortlyBeforeSessionStarts),
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
                                      await launchUrl(uri, webOnlyWindowName: AppStrings.blank);
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
                            label: const Text(AppStrings.whatsapp, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
                                    context.go(
                                      '${RoutePaths.masterTeacherFeedbackNewFor(booking.studentId)}?bookingId=${booking.id}',
                                    );
                                  },
                            icon: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                            label: Text(
                              booking.attendance?.canEditStudentRating == true ? AppStrings.editRating : AppStrings.rate,
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
                              final session = booking.type == 'master_class' ? 'class' : AppStrings.introductionCall;
                              final message = await showAttendanceReportDialog(
                                context,
                                title: AppStrings.studentDidnTJoin,
                                hint: 'Tell Admin what happened on this $session:',
                              );
                              if (message == null) return;
                              await ref.read(scheduleRepositoryProvider).teacherReportStudent(booking.id, message);
                              widget.onRefresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text(AppStrings.reportSentToAdmin)),
                                );
                              }
                            },
                            icon: const Icon(Icons.person_off_rounded, size: 13, color: Color(0xFFDC2626)),
                            label: const Text(AppStrings.studentDidnTJoin, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
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
                                  AppStrings.reportSubmitted,
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
                              const SizedBox(width: 10),
                              Expanded(child: detailsColumn),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 8),
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
  },
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
    this.isPastTab = false,
  });

  final bool isToday;
  final bool isPastTab;
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
            isPastTab
                ? AppStrings.pastSessions
                : (isToday ? AppStrings.noSessionBookingsToday : AppStrings.noBookingsOnThisDate),
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
              isPastTab
                  ? AppStrings.noPastSessionsYet
                  : isToday
                  ? AppStrings.thereAreNoStudentSessionsBookedOnYourCalendarToday
                  : 'There are no sessions booked for ${formatPrettyDate(date)}. Use the date navigator above to check other days.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (isToday && !isPastTab) ...[
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
              label: const Text(AppStrings.checkTomorrowSSchedule, style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
