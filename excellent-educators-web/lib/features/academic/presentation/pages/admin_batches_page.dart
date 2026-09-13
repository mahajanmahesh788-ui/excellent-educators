import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminBatchesPage extends ConsumerStatefulWidget {
  const AdminBatchesPage({super.key});

  @override
  ConsumerState<AdminBatchesPage> createState() => _AdminBatchesPageState();
}

class _AdminBatchesPageState extends ConsumerState<AdminBatchesPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final levelsValue = ref.watch(adminLevelsProvider);

    return AppScaffold(
      title: 'Levels',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.adminBatchNew),
        icon: const Icon(Icons.add),
        label: const Text('Add level'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DirectoryToolbar(
            key: const ValueKey('admin-levels-toolbar'),
            searchHint: 'Search level name',
            searchQuery: _search,
            onSearchChanged: (value) {
              setState(() => _search = value);
            },
            total: levelsValue.asData?.value.length,
            page: 1,
            perPage: 25,
            onPageChanged: (_) {},
          ),
          Expanded(
            child: AsyncBody(
              value: levelsValue,
              onRetry: () => ref.invalidate(adminLevelsProvider),
              builder: (levels) {
                final filtered = levels.where((lvl) {
                  if (_search.trim().isEmpty) return true;
                  return lvl.name.toLowerCase().contains(_search.toLowerCase().trim());
                }).toList();

                if (filtered.isEmpty && _search.isEmpty) {
                  return const EmptyHint(
                    'No levels yet',
                    icon: EmptyIcons.batches,
                    subtitle: 'Add levels to organize students and batches.',
                  );
                }

                if (filtered.isEmpty) {
                  return const EmptyHint(
                    'No levels match your search',
                    icon: EmptyIcons.search,
                    subtitle: 'Try a different search query.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 72),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return DirectoryHeader(
                        countLabel: filtered.length == 1
                            ? '1 level'
                            : '${filtered.length} levels',
                      );
                    }
                    final level = filtered[index - 1];
                    return AcademicLevelCard(
                      level: level,
                      onTap: () => context.go(RoutePaths.adminBatch(level.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCreateBatchPage extends ConsumerStatefulWidget {
  const AdminCreateBatchPage({super.key});

  @override
  ConsumerState<AdminCreateBatchPage> createState() => _AdminCreateBatchPageState();
}

class _AdminCreateBatchPageState extends ConsumerState<AdminCreateBatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _year = TextEditingController(text: DateTime.now().year.toString());
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final level = await ref.read(academicRepositoryProvider).createLevel({
        'name': _name.text.trim(),
        'academic_year': int.parse(_year.text.trim()),
      });
      ref.invalidate(adminLevelsProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        context.go(RoutePaths.adminBatch(level.id));
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

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: 'Add level',
      backTo: RoutePaths.adminBatches,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Level name',
                hintText: 'e.g. Level 2, Class 6',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a level name.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Academic year',
                hintText: 'e.g. 2026',
              ),
              validator: (value) =>
                  int.tryParse(value ?? '') == null ? 'Enter a valid year.' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create level'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminBatchDetailPage extends ConsumerStatefulWidget {
  const AdminBatchDetailPage({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<AdminBatchDetailPage> createState() => _AdminBatchDetailPageState();
}

class _AdminBatchDetailPageState extends ConsumerState<AdminBatchDetailPage> {
  @override
  Widget build(BuildContext context) {
    final levelValue = ref.watch(adminLevelProvider(widget.batchId));

    return AppScaffold(
      title: 'Level Details',
      backTo: RoutePaths.adminBatches,
      body: AsyncBody(
        value: levelValue,
        onRetry: () => ref.invalidate(adminLevelProvider(widget.batchId)),
        builder: (level) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE6DCCB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Brand.navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Academic Year ${level.academicYear} · Unlimited student capacity',
                                  style: const TextStyle(
                                    color: Brand.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _editLevelDialog(context, level),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Level'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              _MetricPill(
                                label: 'Total Students',
                                value: '${level.studentsCount}',
                                color: Brand.navy,
                              ),
                              _MetricPill(
                                label: 'Batches (Sections)',
                                value: '${level.batches.length}',
                                color: Brand.gold,
                              ),
                              _MetricPill(
                                label: 'Master Teachers',
                                value: '${level.masterTeachers.length}',
                                color: const Color(0xFF5BB98C),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                ),
                                onPressed: () => context.go(RoutePaths.adminLevelLearning(level.id)),
                                icon: const Icon(Icons.menu_book_outlined, size: 18),
                                label: const Text('Learning Journey'),
                              ),
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                ),
                                onPressed: () => _assignMasterTeacher(context, level),
                                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                                label: const Text('Add Master Teacher'),
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                ),
                                onPressed: () => _addBatchDialog(context, level),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Batch'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Batches (Sections)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Max 50 students / batch',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (level.batches.isEmpty)
                const EmptyHint(
                  'No batches in this level yet',
                  icon: EmptyIcons.batches,
                  subtitle: 'Tap Add Batch to create a new section.',
                  fillHeight: false,
                )
              else
                ...level.batches.map(
                  (batch) => _BatchRowCard(
                    levelId: level.id,
                    batch: batch,
                  ),
                ),
              if (level.masterTeachers.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Master Teachers (${level.masterTeachers.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                ...level.masterTeachers.map(
                  (teacher) => _LevelMasterTeacherCard(
                    levelId: level.id,
                    teacher: teacher,
                    onUnassign: () => _unassignMasterTeacher(context, level, teacher),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _assignMasterTeacher(BuildContext context, AcademicLevelDto level) async {
    final repo = ref.read(academicRepositoryProvider);
    try {
      final selected = await pickTeacher(
        context: context,
        repo: repo,
        title: 'Assign Master Teacher to ${level.name}',
        role: 'master_teacher',
        excludeLevelId: level.id,
        excludeTeacherIds: level.masterTeachers.map((t) => t.id).toSet(),
        emptyMessage: 'No Master Teachers available to assign. All Master Teachers are already assigned or none exist.',
      );
      if (selected == null) {
        return;
      }
      await repo.assignLevelTeacher(levelId: level.id, teacherId: selected.id);
      ref.invalidate(adminLevelProvider(widget.batchId));
      ref.invalidate(adminLevelsProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _unassignMasterTeacher(
    BuildContext context,
    AcademicLevelDto level,
    TeacherDto teacher,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppModalDialog(
        title: 'Remove Master Teacher',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Are you sure you want to remove ${teacher.fullName} from ${level.name}? Students in this level will no longer see this Master Teacher.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            AppDialogActions(
              confirmLabel: 'Remove',
              destructive: true,
              onConfirm: () => Navigator.of(ctx).pop(true),
              onCancel: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(academicRepositoryProvider).unassignLevelTeacher(
            levelId: level.id,
            teacherId: teacher.id,
          );
      ref.invalidate(adminLevelProvider(widget.batchId));
      ref.invalidate(adminLevelsProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _editLevelDialog(BuildContext context, AcademicLevelDto level) async {
    final nameCtrl = TextEditingController(text: level.name);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppModalDialog(
          title: 'Edit Level',
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Level name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 20),
                AppDialogActions(
                  confirmLabel: 'Save',
                  isConfirming: saving,
                  onConfirm: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => saving = true);
                    try {
                      await ref.read(academicRepositoryProvider).updateLevel(level.id, {
                        'name': nameCtrl.text.trim(),
                      });
                      ref.invalidate(adminLevelProvider(level.id));
                      ref.invalidate(adminLevelsProvider);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    } catch (e) {
                      if (ctx.mounted) showFailure(ctx, e);
                    } finally {
                      if (ctx.mounted) setDialogState(() => saving = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addBatchDialog(BuildContext context, AcademicLevelDto level) async {
  final defaultNum = level.batches.length + 1;
  final nameCtrl = TextEditingController(text: 'Batch $defaultNum');
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AppModalDialog(
        title: 'Add Batch to Level',
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Batch name',
                  hintText: 'e.g. Batch 2, Section A',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 20),
              AppDialogActions(
                confirmLabel: 'Create Batch',
                isConfirming: saving,
                onConfirm: () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => saving = true);
                  try {
                    await ref.read(academicRepositoryProvider).createLevelBatch(level.id, {
                      'name': nameCtrl.text.trim(),
                    });
                    ref.invalidate(adminLevelProvider(level.id));
                    ref.invalidate(adminLevelsProvider);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  } catch (e) {
                    if (ctx.mounted) showFailure(ctx, e);
                  } finally {
                    if (ctx.mounted) setDialogState(() => saving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchRowCard extends ConsumerStatefulWidget {
  const _BatchRowCard({
    required this.levelId,
    required this.batch,
  });

  final String levelId;
  final BatchDto batch;

  @override
  ConsumerState<_BatchRowCard> createState() => _BatchRowCardState();
}

class _BatchRowCardState extends ConsumerState<_BatchRowCard> {
  bool _expanded = false;
  bool _toggling = false;

  Future<void> _toggleStatus() async {
    setState(() => _toggling = true);
    try {
      await ref.read(academicRepositoryProvider).toggleBatchStatus(widget.batch.id);
      ref.invalidate(adminLevelProvider(widget.levelId));
      ref.invalidate(adminLevelsProvider);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _editBatchDialog() async {
  final nameCtrl = TextEditingController(text: widget.batch.name);
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AppModalDialog(
        title: 'Edit Batch',
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Batch name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 20),
              AppDialogActions(
                confirmLabel: 'Save',
                isConfirming: saving,
                onConfirm: () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => saving = true);
                  try {
                    await ref.read(academicRepositoryProvider).updateBatch(widget.batch.id, {
                      'name': nameCtrl.text.trim(),
                    });
                    ref.invalidate(adminLevelProvider(widget.levelId));
                    ref.invalidate(adminLevelsProvider);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  } catch (e) {
                    if (ctx.mounted) showFailure(ctx, e);
                  } finally {
                    if (ctx.mounted) setDialogState(() => saving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Future<void> _enrollStudent() async {
    final repo = ref.read(academicRepositoryProvider);
    try {
      final selected = await pickStudent(
        context: context,
        repo: repo,
        title: 'Enroll student in ${widget.batch.name}',
        withoutBatch: true,
        emptyMessage: 'No unassigned students found.',
      );
      if (selected == null) return;

      await repo.enrollStudent(batchId: widget.batch.id, studentId: selected.id);
      ref.invalidate(adminLevelProvider(widget.levelId));
      ref.invalidate(adminBatchStudentsProvider(widget.batch.id));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _unenrollStudent(StudentDto student) async {
    try {
      await ref.read(academicRepositoryProvider).unenrollStudent(
            batchId: widget.batch.id,
            studentId: student.id,
          );
      ref.invalidate(adminLevelProvider(widget.levelId));
      ref.invalidate(adminBatchStudentsProvider(widget.batch.id));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final isActive = batch.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? const Color(0xFFE6DCCB) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive ? Brand.gold : Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            batch.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Brand.navy : Colors.grey.shade700,
                            ),
                          ),
                          if (batch.monthName.isNotEmpty || batch.year != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${batch.year ?? batch.academicYear}${batch.monthName.isNotEmpty ? ' · ${batch.monthName}' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.green.shade700 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${batch.activeStudentCount}/50 students',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Brand.navy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 100,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (batch.activeStudentCount / 50.0).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: batch.activeStudentCount >= 50
                                      ? Colors.red
                                      : Brand.gold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          if (batch.activeStudentCount >= 50) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Full (Limit 50)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Active / Inactive toggle button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? Colors.orange.shade800 : Colors.green.shade700,
                    side: BorderSide(
                      color: isActive ? Colors.orange.shade300 : Colors.green.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: _toggling ? null : _toggleStatus,
                  icon: _toggling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          size: 16,
                        ),
                  label: Text(
                    isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Edit batch name / year / month',
                  onPressed: _editBatchDialog,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  tooltip: _expanded ? 'Hide students' : 'View students',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            _BatchStudentList(
              levelId: widget.levelId,
              batchId: batch.id,
              onEnrollStudent: _enrollStudent,
              onUnenrollStudent: _unenrollStudent,
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchStudentList extends ConsumerWidget {
  const _BatchStudentList({
    required this.levelId,
    required this.batchId,
    required this.onEnrollStudent,
    required this.onUnenrollStudent,
  });

  final String levelId;
  final String batchId;
  final VoidCallback onEnrollStudent;
  final void Function(StudentDto) onUnenrollStudent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsValue = ref.watch(adminBatchStudentsProvider(batchId));

    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enrolled Students',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Brand.navy,
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onEnrollStudent,
                icon: const Icon(Icons.person_add, size: 15),
                label: const Text('Add student to batch', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AsyncBody(
            value: studentsValue,
            onRetry: () => ref.invalidate(adminBatchStudentsProvider(batchId)),
            builder: (students) {
              if (students.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No students currently in this batch.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: [
                  for (final student in students) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Brand.navy.withOpacity(0.1),
                            child: Text(
                              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Brand.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Code: ${student.studentCode} · Phone: ${student.phone}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove from batch',
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                            onPressed: () => onUnenrollStudent(student),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LevelMasterTeacherCard extends StatelessWidget {
  const _LevelMasterTeacherCard({
    required this.levelId,
    required this.teacher,
    required this.onUnassign,
  });

  final String levelId;
  final TeacherDto teacher;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE6DCCB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF5BB98C).withOpacity(0.15),
              child: const Icon(
                Icons.psychology_alt_rounded,
                color: Color(0xFF2E7D52),
                size: 20,
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
                        teacher.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Brand.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${teacher.email}${teacher.phone != null && teacher.phone!.isNotEmpty ? " · ${teacher.phone}" : ""}${teacher.address != null && teacher.address!.isNotEmpty ? " · ${teacher.address}" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove from Level',
              icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
              onPressed: onUnassign,
            ),
          ],
        ),
      ),
    );
  }
}
