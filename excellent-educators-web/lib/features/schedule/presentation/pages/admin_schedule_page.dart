import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/pages/admin_google_meet_page.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/schedule_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminSchedulePage extends ConsumerStatefulWidget {
  const AdminSchedulePage({super.key});

  @override
  ConsumerState<AdminSchedulePage> createState() => _AdminSchedulePageState();
}

class _AdminSchedulePageState extends ConsumerState<AdminSchedulePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(adminScheduleTeachersProvider);
    final teacherId = ref.watch(adminScheduleTeacherIdProvider);
    final date = ref.watch(adminScheduleDateProvider);
    final day = ref.watch(adminScheduleDayProvider);

    return AppScaffold(
      title: AppStrings.timeManagement,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AsyncBody(
            value: teachers,
            onRetry: () => ref.invalidate(adminScheduleTeachersProvider),
            builder: (items) {
              return DropdownButtonFormField<String>(
                value: teacherId,
                decoration: const InputDecoration(labelText: AppStrings.selectTeacher),
                items: [
                  for (final teacher in items)
                    DropdownMenuItem(value: teacher.id, child: Text(teacher.fullName)),
                ],
                onChanged: (value) => ref.read(adminScheduleTeacherIdProvider.notifier).state = value,
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text(AppStrings.calendar), selected: _tab == 0, onSelected: (_) => setState(() => _tab = 0)),
              ChoiceChip(label: const Text(AppStrings.leaves), selected: _tab == 1, onSelected: (_) => setState(() => _tab = 1)),
              ChoiceChip(label: const Text(AppStrings.breaks), selected: _tab == 2, onSelected: (_) => setState(() => _tab = 2)),
              ChoiceChip(label: const Text(AppStrings.studentBookings), selected: _tab == 3, onSelected: (_) => setState(() => _tab = 3)),
              ChoiceChip(label: const Text(AppStrings.googleMeet), selected: _tab == 4, onSelected: (_) => setState(() => _tab = 4)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _tabBody(day, date, teacherId)),
        ],
      ),
    );
  }

  Widget _tabBody(AsyncValue<ScheduleDayDto?> day, String date, String? teacherId) {
    if (_tab == 4) {
      return const AdminGoogleMeetConnectPanel();
    }
    if (_tab == 1) {
      final leaves = ref.watch(adminScheduleLeavesProvider);
      return AsyncBody(
        value: leaves,
        onRetry: () => ref.invalidate(adminScheduleLeavesProvider),
        builder: (items) => ListView(
          children: [
            for (final leave in items)
              ListTile(
                onTap: leave.requestGroupId.isEmpty
                    ? null
                    : () => context.go(
                          RoutePaths.adminLeaveRequest(leave.requestGroupId),
                        ),
                title: Text('${leave.teacherName ?? ''} · ${leave.date}'),
                subtitle: Text(
                  [
                    leave.statusLabel,
                    leave.isFullDay
                        ? AppStrings.fullDay2
                        : (leave.ranges.isNotEmpty
                            ? '${formatHm(leave.ranges.first.startTime)} – ${formatHm(leave.ranges.first.endTime)}'
                            : AppStrings.partial),
                    if ((leave.reason ?? '').trim().isNotEmpty) leave.reason!.trim(),
                    if (leave.affectedCount > 0)
                      '${leave.reassignedCount}/${leave.affectedCount} reassigned',
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
          ],
        ),
      );
    }
    if (_tab == 3) {
      final bookings = ref.watch(adminScheduleBookingsProvider);
      return AsyncBody(
        value: bookings,
        onRetry: () => ref.invalidate(adminScheduleBookingsProvider),
        builder: (items) => ListView(
          children: [
            for (final booking in items)
              ListTile(
                title: Text('${booking.typeLabel} · ${booking.studentName ?? ''}'),
                subtitle: Text('${booking.date} ${formatHm(booking.start)} · ${booking.teacherName ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    JoinMeetButton(meetingUrl: booking.meetingUrl, compact: true),
                    IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showAppConfirmDialog(
                      context,
                      title: AppStrings.cancelBooking2,
                      message: AppStrings.theStudentWillLoseThisReservedSlot,
                      confirmLabel: AppStrings.cancelBooking,
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref.read(scheduleRepositoryProvider).adminDeleteBooking(booking.id);
                    ref.invalidate(adminScheduleBookingsProvider);
                    ref.invalidate(adminScheduleDayProvider);
                  },
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    if (_tab == 2) {
      return ListView(
        children: [
          const Text(AppStrings.setRecurringBreakfastAndLunchForTheSelectedTeacher, style: TextStyle(color: Brand.muted)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: teacherId == null
                ? null
                : () async {
                    await ref.read(scheduleRepositoryProvider).adminSaveBreaks(
                          teacherId: teacherId,
                          breakfastStart: '09:00',
                          lunchStart: '13:00',
                        );
                    ref.invalidate(adminScheduleDayProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.breaksSetTo0900BreakfastAnd1300Lunch)),
                      );
                    }
                  },
            child: const Text(AppStrings.applyDefault09001300Breaks),
          ),
        ],
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () async {
              final today = scheduleToday();
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
                ref.read(adminScheduleDateProvider.notifier).state =
                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              }
            },
            child: Text(date),
          ),
        ),
        Expanded(
          child: AsyncBody(
            value: day,
            onRetry: () => ref.invalidate(adminScheduleDayProvider),
            builder: (schedule) {
              if (schedule == null) {
                return const Center(child: Text(AppStrings.selectATeacherToViewTheirCalendar));
              }
              return ListView(
                children: [
                  ScheduleTimeline(slots: schedule.slots),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
