import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/time/app_clock.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminTeacherHistoryPage extends ConsumerStatefulWidget {
  const AdminTeacherHistoryPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  ConsumerState<AdminTeacherHistoryPage> createState() => _AdminTeacherHistoryPageState();
}

class _AdminTeacherHistoryPageState extends ConsumerState<AdminTeacherHistoryPage> {
  final _searchController = TextEditingController();
  String _search = '';
  String _kind = 'all';
  String? _selectedMonthKey; // e.g., '2026-09' or null for all
  String _timeframeScope = 'month'; // 'month', 'all_time' (when no specific month selected)
  String _viewMode = 'timeline'; // 'timeline', 'overview'
  final Set<String> _expandedEventIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _search = '';
      _kind = 'all';
      _selectedMonthKey = null;
    });
  }

  bool get _hasActiveFilters =>
      _search.isNotEmpty || _kind != 'all' || _selectedMonthKey != null;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(adminTeacherHistoryProvider(widget.teacherId));

    return AppScaffold(
      title: AppStrings.teacherHistory,
      backTo: RoutePaths.adminTeacher(widget.teacherId),
      body: AsyncBody(
        value: history,
        onRetry: () => ref.invalidate(adminTeacherHistoryProvider(widget.teacherId)),
        builder: (data) {
          final currentMonthKey =
              '${data.currentYear}-${data.currentMonth.toString().padLeft(2, '0')}';

          // Determine which counts to show in the compact KPI ribbon
          TeacherHistoryCountsDto activeCounts;
          String activeCountsLabel;

          if (_selectedMonthKey != null) {
            final match = data.byMonth.where(
              (m) => '${m.year}-${m.month.toString().padLeft(2, '0')}' == _selectedMonthKey,
            );
            if (match.isNotEmpty) {
              activeCounts = match.first.counts;
              activeCountsLabel = AppClock.monthLabel(match.first.year, match.first.month);
            } else {
              activeCounts = data.thisMonth;
              activeCountsLabel = AppClock.monthLabel(data.currentYear, data.currentMonth);
            }
          } else if (_timeframeScope == 'all_time') {
            activeCounts = data.allTime;
            activeCountsLabel = AppStrings.allTimeSummary;
          } else {
            activeCounts = data.thisMonth;
            activeCountsLabel = 'This month · ${AppClock.monthLabel(data.currentYear, data.currentMonth)}';
          }

          // Filter events
          final filteredEvents = data.events.where((event) {
            // Month filter
            if (_selectedMonthKey != null && !event.date.startsWith(_selectedMonthKey!)) {
              return false;
            }

            // Kind filter
            if (_kind != 'all') {
              if (_kind == 'conflict') {
                if (event.conflictStatus == null && event.kind != 'conflict') return false;
              } else if (event.kind != _kind) {
                return false;
              }
            }

            // Search query filter
            if (_search.isNotEmpty) {
              final q = _search.toLowerCase();
              final matchesTitle = event.title.toLowerCase().contains(q);
              final matchesDetail = event.detail.toLowerCase().contains(q);
              final matchesStudent = (event.studentName ?? '').toLowerCase().contains(q) ||
                  (event.studentCode ?? '').toLowerCase().contains(q);
              final matchesLevel = (event.levelName ?? '').toLowerCase().contains(q);
              final matchesFacts = event.facts.any(
                (f) => f.label.toLowerCase().contains(q) || f.value.toLowerCase().contains(q),
              );
              final matchesTags = event.tags.any((t) => t.label.toLowerCase().contains(q));
              if (!matchesTitle &&
                  !matchesDetail &&
                  !matchesStudent &&
                  !matchesLevel &&
                  !matchesFacts &&
                  !matchesTags) {
                return false;
              }
            }

            return true;
          }).toList();

          // Group filtered events by date
          final grouped = <String, List<TeacherHistoryEventDto>>{};
          for (final event in filteredEvents) {
            (grouped[event.date] ??= []).add(event);
          }
          final dates = grouped.keys.toList();

          // Kind counts for category chips
          final totalAll = data.events.length;
          final interviewCount =
              data.events.where((e) => e.kind == 'introduction_call').length;
          final masterCount = data.events.where((e) => e.kind == 'master_class').length;
          final leaveCount = data.events.where((e) => e.kind == 'leave').length;
          final ratingCount = data.events.where((e) => e.kind == 'rating').length;
          final conflictCount =
              data.events.where((e) => e.conflictStatus != null || e.kind == 'conflict').length;

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // 1. Compact Header Row
              _buildHeader(data.teacherName),
              const SizedBox(height: 10),

              // 2. Compact KPI Ribbon
              _buildCompactKpiRibbon(
                activeCounts: activeCounts,
                activeCountsLabel: activeCountsLabel,
                isMonthSelected: _selectedMonthKey != null,
                timeframeScope: _timeframeScope,
                onScopeChanged: (scope) => setState(() => _timeframeScope = scope),
                onResetMonth: () => setState(() => _selectedMonthKey = null),
              ),
              const SizedBox(height: 14),

              // 3. Compact Multi-Filter Toolbar
              _buildFilterToolbar(
                byMonth: data.byMonth,
                currentMonthKey: currentMonthKey,
                totalAll: totalAll,
                interviewCount: interviewCount,
                masterCount: masterCount,
                leaveCount: leaveCount,
                ratingCount: ratingCount,
                conflictCount: conflictCount,
                showingCount: filteredEvents.length,
              ),
              const SizedBox(height: 14),

              // 4. View Switcher & Content
              if (_viewMode == 'overview')
                _buildMonthlyBreakdownTable(data.byMonth, currentMonthKey)
              else
                _buildTimelineList(grouped, dates, filteredEvents.length),
            ],
          );
        },
      ),
    );
  }

  // --- Sub-views ---

  Widget _buildHeader(String teacherName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        final titleContent = Row(
          children: [
            CircleAvatar(
              radius: isNarrow ? 16 : 18,
              backgroundColor: Brand.navy.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: Brand.navy, size: isNarrow ? 18 : 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacherName.isEmpty ? AppStrings.teacherProgressHistory : teacherName,
                    style: TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: isNarrow ? 17 : 20,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Text(
                    AppStrings.performanceClassCompletionsLeavesConflicts,
                    style: TextStyle(color: Brand.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        );

        final viewToggle = SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'timeline',
              icon: Icon(Icons.timeline, size: 15),
              label: Text(AppStrings.timeline, style: TextStyle(fontSize: 11.5)),
            ),
            ButtonSegment(
              value: 'overview',
              icon: Icon(Icons.calendar_view_month, size: 15),
              label: Text(AppStrings.monthlyTable, style: TextStyle(fontSize: 11.5)),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: (set) => setState(() => _viewMode = set.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleContent,
              const SizedBox(height: 10),
              viewToggle,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleContent),
            const SizedBox(width: 12),
            viewToggle,
          ],
        );
      },
    );
  }

  Widget _buildCompactKpiRibbon({
    required TeacherHistoryCountsDto activeCounts,
    required String activeCountsLabel,
    required bool isMonthSelected,
    required String timeframeScope,
    required ValueChanged<String> onScopeChanged,
    required VoidCallback onResetMonth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2D9C8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isMonthSelected ? Icons.filter_alt : Icons.analytics_outlined,
                size: 15,
                color: Brand.goldDark,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activeCountsLabel,
                  style: const TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isMonthSelected)
                InkWell(
                  onTap: onResetMonth,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 14, color: Brand.muted),
                        SizedBox(width: 4),
                        Text(AppStrings.resetMonthFilter, style: TextStyle(fontSize: 11, color: Brand.muted)),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 4,
                  children: [
                    ChoiceChip(
                      showCheckmark: false,
                      label: const Text(AppStrings.thisMonth, style: TextStyle(fontSize: 11)),
                      selected: timeframeScope == 'month',
                      onSelected: (_) => onScopeChanged('month'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    ChoiceChip(
                      showCheckmark: false,
                      label: const Text(AppStrings.allTime, style: TextStyle(fontSize: 11)),
                      selected: timeframeScope == 'all_time',
                      onSelected: (_) => onScopeChanged('all_time'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
            ],
          ),
          const Divider(height: 14, thickness: 1, color: Color(0xFFF1EAE0)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _CompactMetric(
                label: AppStrings.interviews,
                value: '${activeCounts.interviewsHeld} / ${activeCounts.interviews}',
                subtext: AppStrings.heldTotal,
                icon: Icons.call_outlined,
                accentColor: const Color(0xFF2F6FED),
              ),
              _CompactMetric(
                label: AppStrings.masterClasses,
                value: '${activeCounts.masterClassesHeld} / ${activeCounts.masterClasses}',
                subtext: AppStrings.heldTotal,
                icon: Icons.school_outlined,
                accentColor: const Color(0xFF1B7A4E),
              ),
              _CompactMetric(
                label: AppStrings.rating,
                value: activeCounts.ratingAverage != null
                    ? '${activeCounts.ratingAverage!.toStringAsFixed(1)} ★'
                    : '—',
                subtext: '${activeCounts.ratingsSubmitted} reviews',
                icon: Icons.star_outline,
                accentColor: const Color(0xFFC27803),
              ),
              _CompactMetric(
                label: AppStrings.leaves,
                value: '${activeCounts.leaveDays} d',
                subtext: AppStrings.daysOff,
                icon: Icons.event_busy_outlined,
                accentColor: const Color(0xFF8A6D3B),
              ),
              _CompactMetric(
                label: AppStrings.conflicts,
                value: '${activeCounts.conflictsReported}',
                subtext: 'reported',
                icon: Icons.report_gmailerrorred_outlined,
                accentColor: activeCounts.conflictsReported > 0
                    ? const Color(0xFFC0392B)
                    : Brand.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar({
    required List<TeacherHistoryMonthDto> byMonth,
    required String currentMonthKey,
    required int totalAll,
    required int interviewCount,
    required int masterCount,
    required int leaveCount,
    required int ratingCount,
    required int conflictCount,
    required int showingCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;

        final searchInput = SizedBox(
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _search = val.trim()),
            decoration: InputDecoration(
              hintText: AppStrings.searchStudentCodeClassNote,
              hintStyle: const TextStyle(fontSize: 12, color: Brand.muted),
              prefixIcon: const Icon(Icons.search, size: 18, color: Brand.muted),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        );

        final monthDropdown = SizedBox(
          height: 38,
          child: DropdownButtonFormField<String?>(
            initialValue: _selectedMonthKey,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD7CDBB)),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Brand.navy),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(AppStrings.allMonths, style: TextStyle(fontSize: 12)),
              ),
              ...byMonth.map((m) {
                final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
                final isCurrent = key == currentMonthKey;
                final label = '${AppClock.monthLabel(m.year, m.month)}${isCurrent ? AppStrings.current : ''}';
                return DropdownMenuItem<String?>(
                  value: key,
                  child: Text(label, style: const TextStyle(fontSize: 12)),
                );
              }),
            ],
            onChanged: (val) => setState(() => _selectedMonthKey = val),
          ),
        );

        final resetButton = _hasActiveFilters
            ? IconButton(
                tooltip: AppStrings.clearAllFilters,
                icon: const Icon(Icons.filter_alt_off, size: 20, color: Color(0xFFC0392B)),
                onPressed: _resetFilters,
                visualDensity: VisualDensity.compact,
              )
            : null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2D9C8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Month Filter
              if (isNarrow) ...[
                Row(
                  children: [
                    Expanded(child: searchInput),
                    ?resetButton,
                  ],
                ),
                const SizedBox(height: 8),
                monthDropdown,
              ] else ...[
                Row(
                  children: [
                    Expanded(flex: 3, child: searchInput),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: monthDropdown),
                    if (resetButton != null) ...[
                      const SizedBox(width: 8),
                      resetButton,
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // Row 2: Category chips & Result counter
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildKindChip('all', AppStrings.all, totalAll, Icons.apps_outlined),
                          const SizedBox(width: 6),
                          _buildKindChip(
                            'introduction_call',
                            AppStrings.interviews,
                            interviewCount,
                            Icons.call_outlined,
                          ),
                          const SizedBox(width: 6),
                          _buildKindChip(
                            'master_class',
                            AppStrings.masterClasses,
                            masterCount,
                            Icons.school_outlined,
                          ),
                          const SizedBox(width: 6),
                          _buildKindChip('leave', AppStrings.leaves, leaveCount, Icons.event_busy_outlined),
                          const SizedBox(width: 6),
                          _buildKindChip('rating', AppStrings.ratings, ratingCount, Icons.star_outline),
                          const SizedBox(width: 6),
                          _buildKindChip(
                            'conflict',
                            AppStrings.conflicts,
                            conflictCount,
                            Icons.report_gmailerrorred_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1E6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Showing $showingCount',
                      style: const TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKindChip(String kindValue, String label, int count, IconData icon) {
    final isSelected = _kind == kindValue;
    return FilterChip(
      showCheckmark: false,
      selected: isSelected,
      onSelected: (_) => setState(() => _kind = kindValue),
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Brand.navy : Brand.muted,
      ),
      label: Text(
        '$label ($count)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Brand.navy : Brand.ink,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: Brand.gold.withValues(alpha: 0.25),
      side: BorderSide(
        color: isSelected ? Brand.gold : const Color(0xFFE2D9C8),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  // --- Monthly Overview Table ---

  Widget _buildMonthlyBreakdownTable(
    List<TeacherHistoryMonthDto> byMonth,
    String currentMonthKey,
  ) {
    if (byMonth.isEmpty) {
      return const EmptyHint(AppStrings.noMonthlyDataRecordedYet, fillHeight: false);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2D9C8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFAF7F2)),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text(AppStrings.month, style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text(AppStrings.interviewsHeldTotal, style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text(AppStrings.masterClassesHeldTotal, style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text(AppStrings.leaves, style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text(AppStrings.ratings, style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text(AppStrings.conflicts, style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text(AppStrings.action2, style: TextStyle(fontWeight: FontWeight.w700))),
            ],
            rows: byMonth.map((month) {
              final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
              final isCurrent = key == currentMonthKey;
              final isFiltered = _selectedMonthKey == key;

              return DataRow(
                color: isFiltered
                    ? WidgetStateProperty.all(Brand.gold.withValues(alpha: 0.12))
                    : null,
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppClock.monthLabel(month.year, month.month),
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: Brand.navy,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F6EE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              AppStrings.current3,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B7A4E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  DataCell(Text('${month.counts.interviewsHeld} / ${month.counts.interviews}')),
                  DataCell(Text('${month.counts.masterClassesHeld} / ${month.counts.masterClasses}')),
                  DataCell(Text('${month.counts.leaveDays} days')),
                  DataCell(Text('${month.counts.ratingsSubmitted}')),
                  DataCell(
                    Text(
                      '${month.counts.conflictsReported}',
                      style: TextStyle(
                        fontWeight: month.counts.conflictsReported > 0
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: month.counts.conflictsReported > 0
                            ? const Color(0xFFC0392B)
                            : Brand.ink,
                      ),
                    ),
                  ),
                  DataCell(
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedMonthKey = key;
                          _viewMode = 'timeline';
                        });
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text(AppStrings.viewEvents, style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- Timeline View ---

  Widget _buildTimelineList(
    Map<String, List<TeacherHistoryEventDto>> grouped,
    List<String> dates,
    int totalCount,
  ) {
    if (totalCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2D9C8)),
        ),
        child: Column(
          children: [
            const Icon(Icons.filter_list_off, size: 48, color: Brand.muted),
            const SizedBox(height: 12),
            const Text(
              AppStrings.noEventsFoundMatchingCurrentFilters,
              style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              AppStrings.tryChangingSearchTermsDatePeriodsOrEventCategoryFilters,
              style: TextStyle(color: Brand.muted, fontSize: 13),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(AppStrings.resetAllFilters),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final date in dates) ...[
          _buildDateHeader(date, grouped[date]!.length),
          const SizedBox(height: 6),
          for (final event in grouped[date]!) ...[
            _CompactEventCard(
              event: event,
              isExpanded: _expandedEventIds.contains(event.id),
              onToggleExpanded: () {
                setState(() {
                  if (_expandedEventIds.contains(event.id)) {
                    _expandedEventIds.remove(event.id);
                  } else {
                    _expandedEventIds.add(event.id);
                  }
                });
              },
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildDateHeader(String date, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4D5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event, size: 14, color: Brand.navy),
          const SizedBox(width: 6),
          Text(
            formatDisplayDate(date),
            style: const TextStyle(
              color: Brand.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count == 1 ? AppStrings.n1Event : '· $count events',
            style: const TextStyle(color: Brand.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// --- Compact Metric Tile ---

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEFE7D8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Brand.muted, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.1,
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(color: Brand.muted, fontSize: 9),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- High-Density Event Card ---

class _CompactEventCard extends StatelessWidget {
  const _CompactEventCard({
    required this.event,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final TeacherHistoryEventDto event;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  IconData _kindIcon(String kind) {
    return switch (kind) {
      'leave' => Icons.event_busy_outlined,
      'introduction_call' => Icons.call_outlined,
      'master_class' => Icons.school_outlined,
      'rating' => Icons.star_outline,
      'conflict' => Icons.report_gmailerrorred_outlined,
      _ => Icons.history,
    };
  }

  Color _kindColor(String kind) {
    return switch (kind) {
      'leave' => const Color(0xFF8A6D3B),
      'introduction_call' => const Color(0xFF2F6FED),
      'master_class' => const Color(0xFF1B7A4E),
      'rating' => const Color(0xFFC27803),
      'conflict' => const Color(0xFFC0392B),
      _ => Brand.navy,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(event.kind);
    final hasConflict = event.conflictId != null && event.conflictId!.isNotEmpty;
    final timeLabel = [
      if (event.time != null && event.time!.isNotEmpty) event.time,
      if (event.endTime != null && event.endTime!.isNotEmpty) event.endTime,
    ].whereType<String>().join('–');

    // Find class from facts if present
    final classFact = event.facts
        .where((f) => f.label.toLowerCase() == 'class')
        .firstOrNull;

    // Filter facts to eliminate redundancy (student code and class are shown in the main row)
    final uniqueFacts = event.facts.where((f) {
      final l = f.label.toLowerCase();
      return l != AppStrings.studentCode &&
          l != 'student_code' &&
          l != 'class' &&
          l != 'student';
    }).toList();

    // Check if detail is just a raw concatenation of facts (e.g. "Student code: 26-0002 · Class: Class 6")
    final isRedundantDetail = event.detail.isEmpty ||
        event.detail.contains(AppStrings.studentCode2) ||
        event.detail.contains(AppStrings.duration) ||
        event.detail == event.facts.map((f) => '${f.label}: ${f.value}').join(' · ');

    // Deduplicate tags so they don't repeat status, kind, level, attempt, or conflict
    final cleanTags = event.tags.where((tag) {
      final l = tag.label.toLowerCase();
      if (l == 'interview' || l == AppStrings.masterClass2 || l == 'master_class') return false;
      if (l == 'completed' || l == 'held' || l == 'cancelled' || l == event.status.toLowerCase()) return false;
      if (event.levelName != null && l == event.levelName!.toLowerCase()) return false;
      if (l.startsWith('attempt ')) return false;
      if (hasConflict && l.contains('conflict')) return false;
      if (tag.label == event.title) return false;
      return true;
    }).toList();

    final hasExtraDetails = uniqueFacts.isNotEmpty ||
        (!isRedundantDetail && event.detail.isNotEmpty);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: hasConflict
              ? const Color(0xFFC0392B).withValues(alpha: 0.6)
              : const Color(0xFFE2D9C8),
          width: hasConflict ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: hasExtraDetails ? onToggleExpanded : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Row: Icon + Title/Student/Meta + Status/Action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Event icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_kindIcon(event.kind), color: color, size: 17),
                  ),
                  const SizedBox(width: 10),

                  // Title & Student Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  color: Brand.navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeLabel.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EAE0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  timeLabel,
                                  style: const TextStyle(
                                    color: Brand.navy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (event.studentId != null &&
                                event.studentId!.isNotEmpty &&
                                (event.studentName ?? '').isNotEmpty)
                              InkWell(
                                onTap: () =>
                                    context.go(RoutePaths.adminStudent(event.studentId!)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_outline, size: 13, color: Brand.goldDark),
                                    const SizedBox(width: 3),
                                    Text(
                                      event.studentName!,
                                      style: const TextStyle(
                                        color: Brand.goldDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (event.studentCode != null && event.studentCode!.isNotEmpty)
                              Text(
                                '(${event.studentCode})',
                                style: const TextStyle(
                                  color: Brand.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (classFact != null && classFact.value.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EAE0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  classFact.value,
                                  style: const TextStyle(
                                    color: Brand.navy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (event.levelName != null && event.levelName!.isNotEmpty)
                              Text(
                                event.levelName!,
                                style: const TextStyle(color: Brand.muted, fontSize: 11),
                              ),
                            if (event.learningWeek != null)
                              Text(
                                'Week ${event.learningWeek}',
                                style: const TextStyle(color: Brand.muted, fontSize: 11),
                              ),
                            if (event.attemptNumber != null)
                              Text(
                                'Attempt ${event.attemptNumber}${event.attemptMax != null ? '/${event.attemptMax}' : ''}',
                                style: const TextStyle(color: Brand.muted, fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tags & Status
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final tag in cleanTags) _EventTag(tag: tag),
                      if (event.status.isNotEmpty) _StatusBadge(status: event.status),
                    ],
                  ),

                  // Action for conflict
                  if (hasConflict) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(RoutePaths.adminAttendanceIssue(event.conflictId!)),
                      icon: const Icon(Icons.report_gmailerrorred_outlined, size: 14),
                      label: Text(
                        event.conflictStatus == 'resolved' ? AppStrings.resolved : AppStrings.conflict,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFDECEA),
                        foregroundColor: const Color(0xFFC0392B),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                  ],

                  if (hasExtraDetails) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Brand.muted,
                    ),
                  ],
                ],
              ),

              // Expanded Details (Facts, Detail Text)
              if (isExpanded && hasExtraDetails) ...[
                const Divider(height: 14, thickness: 1, color: Color(0xFFF1EAE0)),
                if (!isRedundantDetail && event.detail.isNotEmpty) ...[
                  Text(
                    event.detail,
                    style: const TextStyle(color: Brand.ink, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                if (uniqueFacts.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (final fact in uniqueFacts)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF8F3),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEFE7D8)),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 11, color: Brand.ink),
                              children: [
                                TextSpan(
                                  text: '${fact.label}: ',
                                  style: const TextStyle(color: Brand.muted, fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: fact.value,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.navy),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bg = const Color(0xFFF1EAE0);
    Color fg = Brand.navy;

    if (lower.contains('held') || lower.contains('completed') || lower.contains('verified')) {
      bg = const Color(0xFFE8F6EE);
      fg = const Color(0xFF1B7A4E);
    } else if (lower.contains('cancel')) {
      bg = const Color(0xFFFDECEA);
      fg = const Color(0xFFC0392B);
    } else if (lower.contains('pending') || lower.contains('scheduled')) {
      bg = const Color(0xFFFFF4E0);
      fg = const Color(0xFFC27803);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}

class _EventTag extends StatelessWidget {
  const _EventTag({required this.tag});

  final TeacherHistoryTagDto tag;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tag.tone) {
      'danger' => (const Color(0xFFC0392B), const Color(0xFFFDECEA)),
      'success' => (const Color(0xFF1B7A4E), const Color(0xFFE8F6EE)),
      'warning' => (const Color(0xFFC27803), const Color(0xFFFFF4E0)),
      'info' => (const Color(0xFF2F6FED), const Color(0xFFE8F0FF)),
      _ => (Brand.navy, const Color(0xFFF4EEE3)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.label,
        style: TextStyle(color: colors.$1, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
