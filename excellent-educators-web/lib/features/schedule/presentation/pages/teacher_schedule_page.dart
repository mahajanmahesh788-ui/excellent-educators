import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/schedule_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

const _breakfastStarts = [
  '06:00', '07:00', '08:00', '09:00', '10:00',
];

const _lunchStarts = [
  '12:00', '13:00', '14:00', '15:00',
];

class TeacherSchedulePage extends ConsumerStatefulWidget {
  const TeacherSchedulePage({super.key});

  @override
  ConsumerState<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends ConsumerState<TeacherSchedulePage> {
  bool _fullDay = false;
  final Set<String> _selectedSlots = {};
  String? _rangeStart;
  bool _savingLeave = false;
  bool _savingBreaks = false;
  String? _breakfastStart;
  String? _lunchStart;
  var _breaksHydrated = false;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _plusHour(String start) {
    final minutes = int.parse(start.substring(0, 2)) * 60 + int.parse(start.substring(3, 5)) + 60;
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(teacherScheduleDateProvider);
    final day = ref.watch(teacherDayProvider);
    final leaves = ref.watch(teacherLeavesProvider);

    ref.listen(teacherDayProvider, (previous, next) {
      next.whenData((schedule) {
        if (_breaksHydrated) {
          return;
        }
        setState(() {
          _breakfastStart = schedule.breaks.where((item) => item.type == 'breakfast').firstOrNull?.startTime;
          _lunchStart = schedule.breaks.where((item) => item.type == 'lunch').firstOrNull?.startTime;
          _breaksHydrated = true;
        });
      });
    });

    return AppScaffold(
      title: AppStrings.takeLeave,
      body: ListView(
        children: [
          _breaksCard(),
          const SizedBox(height: 16),
          AsyncBody(
            value: day,
            onRetry: () => ref.invalidate(teacherDayProvider),
            builder: (schedule) => _dayCard(schedule, date),
          ),
          const SizedBox(height: 16),
          AsyncBody(
            value: leaves,
            onRetry: () => ref.invalidate(teacherLeavesProvider),
            builder: (items) => _leavesCard(items),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _breaksCard() {
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.dailyBreaks, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Brand.navy)),
          const SizedBox(height: 4),
          const Text(
            AppStrings.breakfastAndLunchAreFullHoursForExample100,
            style: TextStyle(color: Brand.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final breakfast = _breakDropdown(
                label: AppStrings.breakfast1Hour,
                value: _breakfastStart,
                options: _breakfastStarts,
                onChanged: (value) => setState(() => _breakfastStart = value),
              );
              final lunch = _breakDropdown(
                label: AppStrings.lunch1Hour,
                value: _lunchStart,
                options: _lunchStarts,
                onChanged: (value) => setState(() => _lunchStart = value),
              );
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: breakfast),
                    const SizedBox(width: 12),
                    Expanded(child: lunch),
                    const SizedBox(width: 12),
                    PortalButton(
                      label: _savingBreaks ? AppStrings.saving : AppStrings.saveBreaks,
                      busy: _savingBreaks,
                      onPressed: _saveBreaks,
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  breakfast,
                  const SizedBox(height: 12),
                  lunch,
                  const SizedBox(height: 12),
                  PortalButton(
                    label: _savingBreaks ? AppStrings.saving : AppStrings.saveBreaks,
                    busy: _savingBreaks,
                    onPressed: _saveBreaks,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _breakDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final starts = [...options];
    if (value != null && value.isNotEmpty && !starts.contains(value)) {
      starts.add(value);
      starts.sort();
    }
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text(AppStrings.notSet)),
      for (final start in starts)
        DropdownMenuItem<String?>(
          value: start,
          child: Text('${formatHm(start)} – ${formatHm(_plusHour(start))}'),
        ),
    ];
    final selected = starts.contains(value) ? value : null;
    return DropdownButtonFormField<String?>(
      key: ValueKey('$label-$selected'),
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _dayCard(ScheduleDayDto schedule, String date) {
    final today = scheduleToday();
    final isPast = isScheduleDatePast(date);
    final hasFullDayLeave = schedule.leaves.any((leave) => leave.isFullDay);
    final locked = isPast || hasFullDayLeave;
    final hideSlots = _fullDay || locked;
    final canSubmit = !locked &&
        _reason.text.trim().isNotEmpty &&
        (_fullDay || _selectedSlots.isNotEmpty);

    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Today's slots · $date",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Brand.navy),
              ),
              PortalButton(
                outlined: true,
                icon: Icons.calendar_today_outlined,
                label: AppStrings.changeDate,
                onPressed: () async {
                  final parsed = DateTime.tryParse(date);
                  final initial = parsed == null || scheduleDateOnly(parsed).isBefore(today)
                      ? today
                      : scheduleDateOnly(parsed);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: today,
                    lastDate: DateTime(today.year + 2),
                  );
                  if (picked != null) {
                    ref.read(teacherScheduleDateProvider.notifier).state = formatScheduleDate(picked);
                    setState(() {
                      _selectedSlots.clear();
                      _rangeStart = null;
                      _fullDay = false;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(AppStrings.howDoYouWantToTakeLeave, style: TextStyle(fontWeight: FontWeight.w600, color: Brand.navy)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text(AppStrings.selectHours), icon: Icon(Icons.schedule, size: 16)),
              ButtonSegment(value: true, label: Text(AppStrings.fullDayLeave), icon: Icon(Icons.event_busy, size: 16)),
            ],
            selected: {hasFullDayLeave || _fullDay},
            onSelectionChanged: locked
                ? null
                : (value) => setState(() {
                      _fullDay = value.first;
                      _selectedSlots.clear();
                      _rangeStart = null;
                    }),
          ),
          const SizedBox(height: 12),
          if (hideSlots)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD7E0EA)),
              ),
              child: Text(
                isPast
                    ? AppStrings.pastDatesCannotBeSelectedForLeaveChooseTodayOr
                    : hasFullDayLeave
                        ? 'Full day leave is already recorded for $date. Hour slots cannot be selected and Take leave is disabled until this leave is removed.'
                        : 'Full day leave uses this teacher’s working hours on $date. Hour slots are hidden.',
                style: const TextStyle(color: Brand.muted, height: 1.4),
              ),
            )
          else ...[
            const Text(
              AppStrings.tapAStartTimeThenAnEndTimeToMark,
              style: TextStyle(color: Brand.muted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final slot in _leaveSlots(schedule))
                  InkWell(
                    onTap: slot.status == 'booked' || slot.status == 'leave' ? null : () => _toggleSlot(slot.start, schedule),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 118,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedSlots.contains(slot.start)
                            ? Brand.navy
                            : slotColor(slot.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedSlots.contains(slot.start)
                              ? Brand.navy
                              : slotColor(slot.status).withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatHm(slot.start),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _selectedSlots.contains(slot.start) ? Colors.white : Brand.navy,
                            ),
                          ),
                          Text(
                            _selectedSlots.contains(slot.start) ? AppStrings.leave : slotLabel(slot),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _selectedSlots.contains(slot.start) ? Colors.white70 : slotColor(slot.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            enabled: !locked,
            maxLength: 255,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: AppStrings.leaveReason,
              hintText: AppStrings.whyAreYouTakingLeave,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: PortalButton(
              label: _savingLeave
                  ? AppStrings.saving
                  : (locked ? AppStrings.takeLeaveDisabled : (_fullDay ? AppStrings.confirmFullDayLeave : AppStrings.confirmSelectedHours)),
              busy: _savingLeave,
              onPressed: canSubmit ? _submitLeave : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leavesCard(List<LeaveRequestDto> items) {
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu_rounded, size: 20, color: Brand.navy),
              const SizedBox(width: 8),
              const Text(
                AppStrings.historyOfLeaves,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Brand.navy),
              ),
              const SizedBox(width: 8),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Brand.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Brand.navy,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.allRecordedLeavesWithDurationAppliedDateAndStatus,
            style: TextStyle(color: Brand.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8E4DB)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.event_available_rounded, size: 36, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.noLeavesRecordedYet,
                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    AppStrings.leavesYouApplyForUsingTheCalendarAboveWillAppear,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            for (final leave in items)
              _leaveItemTile(leave),
        ],
      ),
    );
  }

  Widget _leaveItemTile(LeaveRequestDto leave) {
    final past = isScheduleDatePast(leave.date);
    final appliedText = _formatAppliedDate(leave.createdAt);
    final reason = leave.reason?.trim();
    final rangeLabel = leave.isFullDay
        ? AppStrings.fullDay
        : (leave.ranges.isNotEmpty
            ? '${formatHm(leave.ranges.first.startTime)} – ${formatHm(leave.ranges.last.endTime)}'
            : AppStrings.partial);
    final canCancel = leave.isOpen && !past;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: past ? const Color(0xFFFBFBFA) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: past ? const Color(0xFFEBE7DE) : const Color(0xFFE2DCD2),
        ),
        boxShadow: past
            ? null
            : [
                BoxShadow(
                  color: Brand.navy.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 660;

          final leftInfo = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: past ? const Color(0xFFF1F5F9) : Brand.navy.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  past ? Icons.history_rounded : Icons.event_busy_rounded,
                  size: 16,
                  color: past ? const Color(0xFF94A3B8) : Brand.navy,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatLeaveDate(leave.date),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: past ? const Color(0xFF64748B) : Brand.navy,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: leave.isFullDay
                      ? (past ? const Color(0xFFF1F5F9) : Brand.gold.withValues(alpha: 0.16))
                      : (past ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: leave.isFullDay
                        ? (past ? const Color(0xFFE2E8F0) : Brand.gold.withValues(alpha: 0.45))
                        : (past ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE)),
                  ),
                ),
                child: Text(
                  rangeLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: leave.isFullDay
                        ? (past ? const Color(0xFF64748B) : const Color(0xFF785500))
                        : (past ? const Color(0xFF64748B) : const Color(0xFF1D4ED8)),
                  ),
                ),
              ),
            ],
          );

          final statusAndAction = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (appliedText.isNotEmpty) ...[
                Text(
                  appliedText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: past ? const Color(0xFFF1F5F9) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: past ? const Color(0xFFCBD5E1) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Text(
                  leave.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: past ? const Color(0xFF64748B) : const Color(0xFF047857),
                  ),
                ),
              ),
              if (canCancel) ...[
                const SizedBox(width: 4),
                IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  tooltip: AppStrings.cancel,
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () async {
                    final ok = await showAppConfirmDialog(
                      context,
                      title: AppStrings.cancel,
                      message: AppStrings.thisWillMakeTheTeacherAvailableAgainForThatTime,
                      confirmLabel: AppStrings.cancel,
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref
                        .read(scheduleRepositoryProvider)
                        .deleteTeacherLeave(leave.primaryLeaveId);
                    ref.invalidate(teacherLeavesProvider);
                    ref.invalidate(teacherDayProvider);
                  },
                ),
              ],
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    leftInfo,
                    statusAndAction,
                  ],
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 42),
                      const Icon(Icons.notes_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: past ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              leftInfo,
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notes_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: past ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              statusAndAction,
            ],
          );
        },
      ),
    );
  }

  String _formatLeaveDate(String ymd) {
    final parsed = DateTime.tryParse(ymd);
    if (parsed == null) return ymd;
    const weekdays = [AppStrings.mon2, AppStrings.tue2, AppStrings.wed2, AppStrings.thu2, AppStrings.fri2, AppStrings.sat2, AppStrings.sun2];
    const months = [AppStrings.jan2, AppStrings.feb2, AppStrings.mar2, AppStrings.apr2, AppStrings.may2, AppStrings.jun2, AppStrings.jul2, AppStrings.aug2, AppStrings.sep2, AppStrings.oct2, AppStrings.nov2, AppStrings.dec2];
    return '${weekdays[parsed.weekday - 1]}, ${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _formatAppliedDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    const months = [AppStrings.jan2, AppStrings.feb2, AppStrings.mar2, AppStrings.apr2, AppStrings.may2, AppStrings.jun2, AppStrings.jul2, AppStrings.aug2, AppStrings.sep2, AppStrings.oct2, AppStrings.nov2, AppStrings.dec2];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    return 'Applied on $day $month $year';
  }

  List<ScheduleSlotDto> _leaveSlots(ScheduleDayDto schedule) {
    return schedule.slots
        .where((slot) => slot.status != 'unavailable' && slot.status != 'weekly_off')
        .toList();
  }

  void _toggleSlot(String start, ScheduleDayDto schedule) {
    final starts = _leaveSlots(schedule).map((slot) => slot.start).toList();
    setState(() {
      if (_rangeStart == null) {
        _rangeStart = start;
        _selectedSlots
          ..clear()
          ..add(start);
        return;
      }
      final from = _rangeStart!.compareTo(start) <= 0 ? _rangeStart! : start;
      final to = _rangeStart!.compareTo(start) <= 0 ? start : _rangeStart!;
      _selectedSlots
        ..clear()
        ..addAll(starts.where((slot) => slot.compareTo(from) >= 0 && slot.compareTo(to) <= 0));
      _rangeStart = null;
    });
  }

  Future<void> _saveBreaks() async {
    setState(() => _savingBreaks = true);
    try {
      await ref.read(scheduleRepositoryProvider).saveTeacherBreaks(
            breakfastStart: _breakfastStart,
            lunchStart: _lunchStart,
          );
      ref.invalidate(teacherDayProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.breaksSaved)));
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _savingBreaks = false);
    }
  }

  Future<void> _submitLeave() async {
    if (!_fullDay && _selectedSlots.isEmpty) {
      return;
    }
    final date = ref.read(teacherScheduleDateProvider);
    if (isScheduleDatePast(date)) {
      return;
    }
    final day = ref.read(teacherDayProvider).asData?.value;
    if (day?.leaves.any((leave) => leave.isFullDay) == true) {
      return;
    }
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      return;
    }
    setState(() => _savingLeave = true);
    try {
      final slots = _selectedSlots.toList()..sort();
      await ref.read(scheduleRepositoryProvider).takeLeave(
            date: date,
            isFullDay: _fullDay,
            reason: reason,
            slotStarts: _fullDay ? null : slots,
          );
      ref.invalidate(teacherDayProvider);
      ref.invalidate(teacherLeavesProvider);
      setState(() {
        _selectedSlots.clear();
        _rangeStart = null;
        _reason.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.leavePendingAdminReview)),
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _savingLeave = false);
    }
  }
}
