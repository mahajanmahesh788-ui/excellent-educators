import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminAttendancePage extends ConsumerStatefulWidget {
  const AdminAttendancePage({super.key, this.issueId});

  final String? issueId;

  @override
  ConsumerState<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends ConsumerState<AdminAttendancePage> {
  late String _status;
  AttendanceIssueDto? _open;
  String? _openedIssueId;

  @override
  void initState() {
    super.initState();
    _status = widget.issueId != null && widget.issueId!.isNotEmpty ? 'all' : 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final issues = ref.watch(adminAttendanceProvider(_status));

    return AppScaffold(
      title: AppStrings.classConflicts,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.studentAndTeacherReportsWhenSomeoneDidNotJoinA,
            style: TextStyle(color: Brand.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text(AppStrings.pending), selected: _status == 'pending', onSelected: (_) => setState(() => _status = 'pending')),
              ChoiceChip(label: const Text(AppStrings.resolved), selected: _status == 'resolved', onSelected: (_) => setState(() => _status = 'resolved')),
              ChoiceChip(label: const Text(AppStrings.all), selected: _status == 'all', onSelected: (_) => setState(() => _status = 'all')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AsyncBody(
              value: issues,
              onRetry: () => ref.invalidate(adminAttendanceProvider(_status)),
              builder: (items) {
                final issueId = widget.issueId;
                if (issueId != null && issueId.isNotEmpty && _openedIssueId != issueId) {
                  final match = items.where((item) => item.id == issueId);
                  if (match.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _openedIssueId == issueId) {
                        return;
                      }
                      setState(() {
                        _open = match.first;
                        _openedIssueId = issueId;
                      });
                    });
                  }
                }
                if (items.isEmpty) {
                  return const EmptyState(
                    title: AppStrings.noClassConflicts,
                    subtitle: AppStrings.newStudentAndTeacherJoinReportsWillAppearHere,
                  );
                }
                final table = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text(AppStrings.student)),
                            DataColumn(label: Text(AppStrings.teacher)),
                            DataColumn(label: Text(AppStrings.level)),
                            DataColumn(label: Text(AppStrings.classLabel)),
                            DataColumn(label: Text(AppStrings.attempt)),
                            DataColumn(label: Text(AppStrings.week2)),
                            DataColumn(label: Text(AppStrings.date2)),
                            DataColumn(label: Text(AppStrings.time)),
                            DataColumn(label: Text(AppStrings.issue)),
                            DataColumn(label: Text(AppStrings.studentJoin)),
                            DataColumn(label: Text(AppStrings.teacherJoin)),
                            DataColumn(label: Text(AppStrings.status2)),
                          ],
                          rows: [
                            for (final item in items)
                              DataRow(
                                selected: _open?.id == item.id,
                                onSelectChanged: (_) => setState(() => _open = item),
                                cells: [
                                  DataCell(
                                    _ProfileLink(item.studentName ?? '—'),
                                    onTap: item.studentId == null || item.studentId!.isEmpty
                                        ? null
                                        : () => context.go(RoutePaths.adminStudent(item.studentId!)),
                                  ),
                                  DataCell(
                                    _ProfileLink(item.teacherName ?? '—'),
                                    onTap: item.teacherId == null || item.teacherId!.isEmpty
                                        ? null
                                        : () => context.go(RoutePaths.adminTeacher(item.teacherId!)),
                                  ),
                                  DataCell(Text(item.levelName ?? '—')),
                                  DataCell(Text(item.classLabel)),
                                  DataCell(Text(item.attemptLabel)),
                                  DataCell(Text(item.weekLabel)),
                                  DataCell(Text(item.date ?? '—')),
                                  DataCell(Text(item.start ?? '—')),
                                  DataCell(Text(item.issueLabel)),
                                  DataCell(Text(item.studentJoinCount > 0 ? '${item.studentJoinCount} click(s)' : AppStrings.noRecord)),
                                  DataCell(Text(item.teacherDayJoinAt != null ? AppStrings.sameDayMeetClick : AppStrings.noIndividualClickRecorded)),
                                  DataCell(Text(item.status)),
                                ],
                              ),
                          ],
                    ),
                  ),
                );
                final detail = _open == null
                    ? null
                    : _DetailPane(
                        issue: _open!,
                        onResolved: () {
                          setState(() => _open = null);
                          ref.invalidate(adminAttendanceProvider(_status));
                          ref.invalidate(adminPendingConflictsCountProvider);
                        },
                      );
                if (MediaQuery.sizeOf(context).width < 900) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: table),
                      if (detail != null)
                        SizedBox(height: 300, child: detail),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: table),
                    if (detail != null) ...[
                      const SizedBox(width: 16),
                      SizedBox(width: 360, child: detail),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Brand.navy,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
        decorationColor: Brand.navy,
      ),
    );
  }
}

class _DetailPane extends ConsumerStatefulWidget {
  const _DetailPane({required this.issue, required this.onResolved});

  final AttendanceIssueDto issue;
  final VoidCallback onResolved;

  @override
  ConsumerState<_DetailPane> createState() => _DetailPaneState();
}

class _DetailPaneState extends ConsumerState<_DetailPane> {
  var _saving = false;

  Future<void> _resolve(String decision) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(scheduleRepositoryProvider).adminResolveAttendance(
            id: widget.issue.id,
            decision: decision,
          );
      widget.onResolved();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(issue.issueLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Brand.navy)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (issue.studentId != null && issue.studentId!.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go(RoutePaths.adminStudent(issue.studentId!)),
                    child: Text(issue.studentName ?? AppStrings.student),
                  ),
                if (issue.teacherId != null && issue.teacherId!.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go(RoutePaths.adminTeacher(issue.teacherId!)),
                    child: Text(issue.teacherName ?? AppStrings.teacher),
                  ),
              ],
            ),
            Text('${issue.classLabel} · Attempt ${issue.attemptLabel} · Week ${issue.weekLabel}'),
            Text('Level ${issue.levelName ?? '—'}'),
            Text('${issue.date} ${issue.start}'),
            const SizedBox(height: 12),
            Text(issue.message ?? '', style: const TextStyle(height: 1.4)),
            const SizedBox(height: 12),
            Text('Student Join: ${issue.studentJoinCount > 0 ? issue.studentFirstJoinAt ?? AppStrings.yes : AppStrings.noRecord}'),
            Text('Teacher Join: ${issue.teacherDayJoinAt ?? AppStrings.noIndividualClickRecorded}'),
            Text(AppStrings.aMissingTeacherClickDoesNotMeanTheTeacherWas),
            if (issue.meetingUrl != null) Text('Meet: ${issue.meetingUrl}'),
            const SizedBox(height: 12),
            if (issue.status == 'pending') ...[
              FilledButton(
                onPressed: _saving ? null : () => _resolve('resolved'),
                child: Text(_saving ? AppStrings.saving : AppStrings.markAsResolved),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _saving ? null : () => _resolve('extra_chance'),
                child: const Text(AppStrings.giveOneMoreChance),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.giveOneMoreChanceLetsTheStudentBookAgainAfter,
                style: TextStyle(color: Brand.muted.withValues(alpha: 0.95), fontSize: 12, height: 1.35),
              ),
            ] else ...[
              Text(
                issue.adminDecision == 'extra_chance'
                    ? AppStrings.oneMoreChanceGiven
                    : AppStrings.markedAsResolved,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.navy),
              ),
              if (issue.rebookingGranted)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(AppStrings.theStudentCanBookAnotherSlot),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
