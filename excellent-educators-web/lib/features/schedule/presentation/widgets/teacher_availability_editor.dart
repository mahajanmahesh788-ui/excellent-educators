import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class TeacherAvailabilitySummary extends ConsumerWidget {
  const TeacherAvailabilitySummary({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(adminTeacherAvailabilityProvider(teacherId));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE6DCCB))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            const Icon(Icons.schedule_outlined, size: 18, color: Brand.navy),
            const SizedBox(width: 10),
            Expanded(
              child: value.when(
                skipLoadingOnReload: true,
                loading: () => const Text(AppStrings.timeSlots, style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 14)),
                error: (error, _) => Text(error.toString(), style: const TextStyle(color: Colors.red, fontSize: 13)),
                data: (data) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.timeSlots,
                        style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _compactLabel(data),
                        style: const TextStyle(color: Brand.muted, fontSize: 13, height: 1.3),
                      ),
                    ],
                  );
                },
              ),
            ),
            IconButton(
              tooltip: AppStrings.editTimeSlots,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => context.go(RoutePaths.adminTeacherAvailabilityFor(teacherId)),
            ),
          ],
        ),
      ),
    );
  }

  String _compactLabel(TeacherAvailabilityDto data) {
    final working = data.weekly.where((day) => !day.off && day.ranges.isNotEmpty).toList();
    if (working.isEmpty) {
      return AppStrings.notAvailable;
    }
    String rangesOf(AvailabilityDayDto day) =>
        day.ranges.map((range) => '${formatHm(range.start)} – ${formatHm(range.end)}').join(', ');
    final first = rangesOf(working.first);
    final sameHours = working.every((day) => rangesOf(day) == first);
    if (sameHours && working.length == 7) {
      return 'All days available · $first';
    }
    if (sameHours) {
      final days = working.map((day) => day.label.substring(0, 3)).join(', ');
      return '$days · $first';
    }
    return working.map((day) => '${day.label.substring(0, 3)} ${rangesOf(day)}').join(' · ');
  }
}

class TeacherAvailabilityEditPage extends StatelessWidget {
  const TeacherAvailabilityEditPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppStrings.timeSlots,
      backTo: RoutePaths.adminTeacher(teacherId),
      body: TeacherAvailabilityEditor(teacherId: teacherId),
    );
  }
}

class TeacherAvailabilityEditor extends ConsumerStatefulWidget {
  const TeacherAvailabilityEditor({super.key, required this.teacherId});

  final String teacherId;

  @override
  ConsumerState<TeacherAvailabilityEditor> createState() => _TeacherAvailabilityEditorState();
}

class _TeacherAvailabilityEditorState extends ConsumerState<TeacherAvailabilityEditor> {
  String? _boundId;
  String _workType = 'full_time';
  List<AvailabilityDayDto> _weekly = [];
  var _saving = false;

  static const _times = [
    '06:00', '06:30', '07:00', '07:30', '08:00', '08:30', '09:00', '09:30',
    '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30',
    '22:00', '22:30', '23:00',
  ];

  void _bind(TeacherAvailabilityDto data) {
    if (_boundId == data.teacherId) {
      return;
    }
    _boundId = data.teacherId;
    _workType = data.workType;
    _weekly = data.weekly.map((day) => day.copyWith(ranges: List.of(day.ranges))).toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(scheduleRepositoryProvider).adminSaveTeacherAvailability(
            teacherId: widget.teacherId,
            workType: _workType,
            weekly: _weekly,
          );
      ref.invalidate(adminTeacherAvailabilityProvider(widget.teacherId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.timeSlotsSaved)),
        );
        context.go(RoutePaths.adminTeacher(widget.teacherId));
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _setDayOff(int index, bool off) {
    setState(() {
      final day = _weekly[index];
      _weekly[index] = day.copyWith(
        off: off,
        ranges: off
            ? const []
            : (day.ranges.isEmpty
                ? const [AvailabilityRangeDto(start: '06:00', end: '20:00')]
                : day.ranges),
      );
    });
  }

  void _addRange(int index) {
    setState(() {
      final day = _weekly[index];
      _weekly[index] = day.copyWith(
        off: false,
        ranges: [...day.ranges, const AvailabilityRangeDto(start: '06:00', end: '10:00')],
      );
    });
  }

  void _removeRange(int dayIndex, int rangeIndex) {
    setState(() {
      final day = _weekly[dayIndex];
      final next = [...day.ranges]..removeAt(rangeIndex);
      _weekly[dayIndex] = day.copyWith(off: next.isEmpty, ranges: next);
    });
  }

  void _updateRange(int dayIndex, int rangeIndex, {String? start, String? end}) {
    setState(() {
      final day = _weekly[dayIndex];
      final next = [...day.ranges];
      next[rangeIndex] = next[rangeIndex].copyWith(start: start, end: end);
      _weekly[dayIndex] = day.copyWith(ranges: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(adminTeacherAvailabilityProvider(widget.teacherId));
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return ListView(
      padding: isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(16),
      children: [
        DetailSection(
          title: AppStrings.weeklyTimeSlots,
          children: [
            Text(
              AppStrings.setTheHoursThisTeacherCanBeBookedStudentsOnly,
              style: TextStyle(
                color: Brand.muted,
                height: 1.3,
                fontSize: isMobile ? 12 : 13,
              ),
            ),
            SizedBox(height: isMobile ? 10 : 16),
            AsyncBody(
              value: value,
              onRetry: () => ref.invalidate(adminTeacherAvailabilityProvider(widget.teacherId)),
              builder: (data) {
                if (_boundId != data.teacherId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _bind(data));
                  });
                }
                if (_weekly.isEmpty) {
                  return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _workType,
                      decoration: InputDecoration(
                        labelText: AppStrings.workType,
                        isDense: isMobile,
                        contentPadding: isMobile
                            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: isMobile ? 18 : 22,
                        color: Brand.navy,
                      ),
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Brand.ink,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'full_time', child: Text(AppStrings.fullTime)),
                        DropdownMenuItem(value: 'part_time', child: Text(AppStrings.partTime)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _workType = value);
                        }
                      },
                    ),
                    SizedBox(height: isMobile ? 10 : 16),
                    for (var i = 0; i < _weekly.length; i++) ...[
                      _DayCard(
                        day: _weekly[i],
                        times: _times,
                        isMobile: isMobile,
                        onOffChanged: (off) => _setDayOff(i, off),
                        onAddRange: () => _addRange(i),
                        onRemoveRange: (rangeIndex) => _removeRange(i, rangeIndex),
                        onUpdateRange: (rangeIndex, {start, end}) =>
                            _updateRange(i, rangeIndex, start: start, end: end),
                      ),
                      SizedBox(height: isMobile ? 6 : 10),
                    ],
                    SizedBox(height: isMobile ? 6 : 10),
                    Align(
                      alignment: isMobile ? Alignment.center : Alignment.centerLeft,
                      child: SizedBox(
                        width: isMobile ? double.infinity : null,
                        child: FilledButton(
                          style: isMobile
                              ? FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? AppStrings.saving : AppStrings.saveTimeSlots),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.times,
    required this.onOffChanged,
    required this.onAddRange,
    required this.onRemoveRange,
    required this.onUpdateRange,
    this.isMobile = false,
  });

  final AvailabilityDayDto day;
  final List<String> times;
  final ValueChanged<bool> onOffChanged;
  final VoidCallback onAddRange;
  final ValueChanged<int> onRemoveRange;
  final void Function(int rangeIndex, {String? start, String? end}) onUpdateRange;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: day.off ? const Color(0xFFFAFAF9) : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: day.off ? const Color(0xFFEBE6DC) : const Color(0xFFE2D9CA),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 7 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        day.label,
                        style: TextStyle(
                          color: day.off ? Brand.muted : Brand.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 13.5 : 15,
                        ),
                      ),
                      if (isMobile && !day.off && day.ranges.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8F1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${day.ranges.length} slot${day.ranges.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  day.off ? AppStrings.off : AppStrings.available,
                  style: TextStyle(
                    color: day.off ? Brand.muted : const Color(0xFF16A34A),
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: isMobile ? 0.72 : 1.0,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: !day.off,
                    onChanged: (on) => onOffChanged(!on),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            if (!day.off) ...[
              SizedBox(height: isMobile ? 6 : 10),
              for (var i = 0; i < day.ranges.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: times.contains(day.ranges[i].start)
                            ? day.ranges[i].start
                            : times.first,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.from,
                          isDense: isMobile,
                          contentPadding: isMobile
                              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                              : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          labelStyle: TextStyle(
                            fontSize: isMobile ? 11 : 13,
                            color: Brand.muted,
                          ),
                          floatingLabelStyle: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            color: Brand.muted,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: isMobile ? 12.5 : 14,
                          color: Brand.navy,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: isMobile ? 18 : 22,
                          color: Brand.navy,
                        ),
                        items: [
                          for (final time in times)
                            DropdownMenuItem(
                              value: time,
                              child: Text(
                                formatHm(time),
                                style: TextStyle(fontSize: isMobile ? 12.5 : 14),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) onUpdateRange(i, start: value);
                        },
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: times.contains(day.ranges[i].end)
                            ? day.ranges[i].end
                            : times.last,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.to,
                          isDense: isMobile,
                          contentPadding: isMobile
                              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                              : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          labelStyle: TextStyle(
                            fontSize: isMobile ? 11 : 13,
                            color: Brand.muted,
                          ),
                          floatingLabelStyle: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            color: Brand.muted,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: isMobile ? 12.5 : 14,
                          color: Brand.navy,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: isMobile ? 18 : 22,
                          color: Brand.navy,
                        ),
                        items: [
                          for (final time in times)
                            DropdownMenuItem(
                              value: time,
                              child: Text(
                                formatHm(time),
                                style: TextStyle(fontSize: isMobile ? 12.5 : 14),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) onUpdateRange(i, end: value);
                        },
                      ),
                    ),
                    SizedBox(width: isMobile ? 2 : 4),
                    IconButton(
                      tooltip: AppStrings.removeRange,
                      visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                      padding: EdgeInsets.zero,
                      constraints: isMobile
                          ? const BoxConstraints(minWidth: 28, minHeight: 28)
                          : null,
                      iconSize: isMobile ? 18 : 22,
                      color: const Color(0xFFDC2626),
                      onPressed: () => onRemoveRange(i),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 5 : 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                    padding: isMobile
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                        : null,
                    tapTargetSize: isMobile ? MaterialTapTargetSize.shrinkWrap : null,
                  ),
                  onPressed: onAddRange,
                  icon: Icon(Icons.add, size: isMobile ? 14 : 18),
                  label: Text(
                    AppStrings.addTimeRange,
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
