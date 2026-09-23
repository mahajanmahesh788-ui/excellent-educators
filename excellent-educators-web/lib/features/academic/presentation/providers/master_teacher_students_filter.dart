import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/time/app_clock.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

enum MasterTeacherStudentsRatedFilter {
  all,
  rated,
  notRated,
}

class MasterTeacherStudentsFilter {
  const MasterTeacherStudentsFilter({
    required this.year,
    required this.month,
    this.rated = MasterTeacherStudentsRatedFilter.all,
    this.levelId = '',
    this.batchId = '',
  });

  final int year;
  final int month;
  final MasterTeacherStudentsRatedFilter rated;
  final String levelId;
  final String batchId;

  factory MasterTeacherStudentsFilter.currentMonth() {
    final current = AppClock.currentYearMonth();
    return MasterTeacherStudentsFilter(year: current.year, month: current.month);
  }

  String get monthLabel => AppClock.monthLabel(year, month);

  MasterTeacherStudentsFilter copyWith({
    int? year,
    int? month,
    MasterTeacherStudentsRatedFilter? rated,
    String? levelId,
    String? batchId,
  }) {
    return MasterTeacherStudentsFilter(
      year: year ?? this.year,
      month: month ?? this.month,
      rated: rated ?? this.rated,
      levelId: levelId ?? this.levelId,
      batchId: batchId ?? this.batchId,
    );
  }

  Map<String, String> toQuery() {
    return {
      'year': '$year',
      'month': '$month',
      if (rated == MasterTeacherStudentsRatedFilter.rated) 'rated': '1',
      if (rated == MasterTeacherStudentsRatedFilter.notRated) 'rated': '0',
      if (levelId.isNotEmpty) 'level_id': levelId,
      if (batchId.isNotEmpty) 'batch_id': batchId,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MasterTeacherStudentsFilter &&
        other.year == year &&
        other.month == month &&
        other.rated == rated &&
        other.levelId == levelId &&
        other.batchId == batchId;
  }

  @override
  int get hashCode => Object.hash(year, month, rated, levelId, batchId);
}

List<({int year, int month, String label})> masterTeacherStudentMonthOptions({int count = 12}) {
  final options = <({int year, int month, String label})>[];
  var cursor = AppClock.now();
  for (var i = 0; i < count; i++) {
    options.add((
      year: cursor.year,
      month: cursor.month,
      label: AppClock.monthLabel(cursor.year, cursor.month),
    ));
    cursor = DateTime(cursor.year, cursor.month - 1, 1);
  }
  return options;
}

class MasterTeacherStudentsFilterBar extends StatelessWidget {
  const MasterTeacherStudentsFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    this.levels = const [],
  });

  final MasterTeacherStudentsFilter filter;
  final ValueChanged<MasterTeacherStudentsFilter> onFilterChanged;
  final List<MasterTeacherRosterLevelDto> levels;

  String _monthKey(int year, int month) => '$year-$month';

  Widget _labeledDropdown({
    required String label,
    required double width,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Brand.muted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            key: ValueKey('$label-$value'),
            isExpanded: true,
            initialValue: items.any((item) => item.value == value) ? value : '',
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthOptions = masterTeacherStudentMonthOptions();
    final selectedMonthKey = _monthKey(filter.year, filter.month);
    final selectedLevel = levels.where((level) => level.id == filter.levelId).firstOrNull;
    final batchOptions = selectedLevel?.batches ?? [for (final level in levels) ...level.batches];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _labeledDropdown(
                label: AppStrings.level,
                width: 200,
                value: filter.levelId,
                items: [
                  const DropdownMenuItem(value: '', child: Text(AppStrings.allLevels)),
                  for (final level in levels)
                    DropdownMenuItem(value: level.id, child: Text(level.name)),
                ],
                onChanged: (value) => onFilterChanged(filter.copyWith(levelId: value ?? '', batchId: '')),
              ),
              _labeledDropdown(
                label: AppStrings.batch,
                width: 200,
                value: filter.batchId,
                items: [
                  const DropdownMenuItem(value: '', child: Text(AppStrings.allBatches)),
                  for (final batch in batchOptions)
                    DropdownMenuItem(value: batch.id, child: Text(batch.label)),
                ],
                onChanged: (value) => onFilterChanged(filter.copyWith(batchId: value ?? '')),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppStrings.month,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Brand.muted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedMonthKey),
                      isExpanded: true,
                      initialValue: selectedMonthKey,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        for (final option in monthOptions)
                          DropdownMenuItem(
                            value: _monthKey(option.year, option.month),
                            child: Text(option.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        final parts = value.split('-');
                        onFilterChanged(filter.copyWith(
                          year: int.parse(parts[0]),
                          month: int.parse(parts[1]),
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text(AppStrings.all),
                selected: filter.rated == MasterTeacherStudentsRatedFilter.all,
                onSelected: (_) => onFilterChanged(
                  filter.copyWith(rated: MasterTeacherStudentsRatedFilter.all),
                ),
              ),
              FilterChip(
                label: const Text(AppStrings.rated),
                selected: filter.rated == MasterTeacherStudentsRatedFilter.rated,
                onSelected: (_) => onFilterChanged(
                  filter.copyWith(rated: MasterTeacherStudentsRatedFilter.rated),
                ),
              ),
              FilterChip(
                label: const Text(AppStrings.notRated),
                selected: filter.rated == MasterTeacherStudentsRatedFilter.notRated,
                onSelected: (_) => onFilterChanged(
                  filter.copyWith(rated: MasterTeacherStudentsRatedFilter.notRated),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
