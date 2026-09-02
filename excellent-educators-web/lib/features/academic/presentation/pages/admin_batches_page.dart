import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_dashboard_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/utils/admin_list_route_sync.dart';
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scheduleBatchesFilterFromRoute(
      ref,
      GoRouterState.of(context),
      isMounted: () => mounted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(adminBatchesFilterProvider);
    final batches = ref.watch(adminBatchesProvider(filter));
    final levels = ref.watch(careerCompassLevelsProvider);
    final repo = ref.watch(academicRepositoryProvider);
    final levelItems = levels.maybeWhen(
      data: careerCompassDropdownItems,
      orElse: () => <DropdownMenuItem<String>>[],
    );
    final page = batches.asData?.value;

    return AppScaffold(
      title: 'Batches',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.adminBatchNew),
        icon: const Icon(Icons.add),
        label: const Text('Add batch'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DirectoryToolbar(
            key: const ValueKey('admin-batches-toolbar'),
            searchHint: 'Search batch name',
            searchQuery: filter.search,
            onSearchChanged: (value) {
              ref.read(adminBatchesFilterProvider.notifier).state =
                  filter.copyWith(search: value, page: 1);
            },
            levelItems: levelItems.isEmpty ? null : levelItems,
            selectedLevelId: filter.levelId,
            onLevelChanged: levelItems.isEmpty
                ? null
                : (value) {
                    ref.read(adminBatchesFilterProvider.notifier).state = filter.copyWith(
                          levelId: value,
                          page: 1,
                          clearLevel: value == null,
                        );
                  },
            total: page?.total,
            page: page?.page ?? filter.page,
            perPage: page?.perPage,
            onPageChanged: (nextPage) {
              ref.read(adminBatchesFilterProvider.notifier).state = filter.copyWith(page: nextPage);
            },
          ),
          if (filter.attentionLabel != null) ...[
            const SizedBox(height: 8),
            ActiveFilterBanner(
              label: filter.attentionLabel!,
              onClear: () => clearBatchesAttentionRoute(context, ref, filter),
            ),
          ],
          Expanded(
            child: AsyncBody(
              value: batches,
              onRetry: () => ref.invalidate(adminBatchesProvider(filter)),
              builder: (page) {
                final items = repo.parseBatches(page);

                if (items.isEmpty &&
                    filter.search.isEmpty &&
                    filter.levelId == null &&
                    filter.attentionKey == null) {
                  return const EmptyHint(
                    'No batches yet',
                    icon: EmptyIcons.batches,
                    subtitle: 'Create a batch, enroll students, and assign a Common Teacher.',
                  );
                }

                if (items.isEmpty) {
                  return const EmptyHint(
                    'No batches match your filters',
                    icon: EmptyIcons.search,
                    subtitle: 'Try a different search term or filter.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 72),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return DirectoryHeader(
                        countLabel: page.total == 1 ? '1 batch' : '${page.total} batches',
                      );
                    }
                    final batch = items[index - 1];
                    return BatchCard(
                      batch: batch,
                      onTap: () => context.go(RoutePaths.adminBatch(batch.id)),
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
  String? _levelId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _levelId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final batch = await ref.read(academicRepositoryProvider).createBatch({
        'name': _name.text.trim(),
        'career_compass_level_id': _levelId,
        'academic_year': int.parse(_year.text.trim()),
      });
      ref.invalidate(adminBatchesProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        context.go(RoutePaths.adminBatch(batch.id));
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
    final levels = ref.watch(careerCompassLevelsProvider);
    return AppFormPage(
      title: 'Add batch',
      backTo: RoutePaths.adminBatches,
      child: AsyncBody(
        value: levels,
        onRetry: () => ref.invalidate(careerCompassLevelsProvider),
        builder: (items) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Batch name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Enter a batch name.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_levelId),
                  initialValue: _levelId,
                  decoration: const InputDecoration(labelText: 'Career Compass'),
                  items: [
                    for (final level in items)
                      DropdownMenuItem(value: level.id, child: Text(level.displayName)),
                  ],
                  onChanged: (value) => setState(() => _levelId = value),
                  validator: (value) => value == null ? 'Select a Career Compass level.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Academic year'),
                  validator: (value) =>
                      int.tryParse(value ?? '') == null ? 'Enter a year.' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: const Text('Create batch'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminBatchDetailPage extends ConsumerWidget {
  const AdminBatchDetailPage({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchValue = ref.watch(adminBatchProvider(batchId));
    final studentsValue = ref.watch(adminBatchStudentsProvider(batchId));

    return AppScaffold(
      title: 'Batch',
      backTo: RoutePaths.adminBatches,
      body: AsyncBody(
        value: batchValue,
        onRetry: () => ref.invalidate(adminBatchProvider(batchId)),
        builder: (batch) {
          return ListView(
            children: [
              Text(batch.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Brand.navy, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                [
                  batch.careerCompassLevel?.displayName,
                  '${batch.activeStudentCount}/${batch.maxActiveStudents} active students',
                  'Common Teacher: ${batch.commonTeacher?.label ?? 'Unassigned'}',
                ].whereType<String>().join('  ·  '),
                style: const TextStyle(color: Brand.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _BatchEditCard(batch: batch, batchId: batchId),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
                    onPressed: () => _assignTeacher(context, ref, batch),
                    child: Text(batch.commonTeacher == null || batch.commonTeacher!.isEmpty
                        ? 'Assign Common Teacher'
                        : 'Change Common Teacher'),
                  ),
                  if (batch.commonTeacher != null && !batch.commonTeacher!.isEmpty)
                    OutlinedButton(
                      onPressed: () => _unassignTeacher(context, ref, batch),
                      child: const Text('Remove Common Teacher'),
                    ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
                    onPressed: batch.isFull ? null : () => _enroll(context, ref, batch),
                    child: const Text('Add student'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Students', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              AsyncBody(
                value: studentsValue,
                onRetry: () => ref.invalidate(adminBatchStudentsProvider(batchId)),
                builder: (students) {
                  if (students.isEmpty) {
                    return const EmptyHint(
                      'No students in this batch yet',
                      icon: EmptyIcons.students,
                      subtitle: 'Tap Add student to enroll someone into this batch.',
                      fillHeight: false,
                    );
                  }
                  return Column(
                    children: [
                      for (final student in students) ...[
                        StudentCard(
                          student: student,
                          action: IconButton(
                            tooltip: 'Remove from batch',
                            onPressed: () => _unenroll(context, ref, student),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _unassignTeacher(BuildContext context, WidgetRef ref, BatchDto batch) async {
    try {
      await ref.read(academicRepositoryProvider).unassignCommonTeacher(batch.id);
      ref.invalidate(adminBatchProvider(batchId));
      ref.invalidate(adminBatchesProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _assignTeacher(BuildContext context, WidgetRef ref, BatchDto batch) async {
    final repo = ref.read(academicRepositoryProvider);
    try {
      final selected = await pickTeacher(
        context: context,
        repo: repo,
        title: 'Assign Common Teacher',
        role: 'common_teacher',
        highlightLevelId: batch.careerCompassLevel?.id,
        emptyMessage: 'No Common Teachers found. Add a teacher with the Common Teacher role first.',
      );
      if (selected == null) {
        return;
      }
      await repo.assignCommonTeacher(batchId: batch.id, teacherId: selected.id);
      ref.invalidate(adminBatchProvider(batchId));
      ref.invalidate(adminBatchesProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _enroll(BuildContext context, WidgetRef ref, BatchDto batch) async {
    final repo = ref.read(academicRepositoryProvider);
    try {
      final selected = await pickStudent(
        context: context,
        repo: repo,
        title: 'Enroll student',
        careerCompassLevelId: batch.careerCompassLevel?.id,
        withoutBatch: true,
        emptyMessage: 'No unassigned students for this Career Compass level.',
      );
      if (selected == null) {
        return;
      }
      await repo.enrollStudent(batchId: batch.id, studentId: selected.id);
      ref.invalidate(adminBatchProvider(batchId));
      ref.invalidate(adminBatchStudentsProvider(batchId));
      ref.invalidate(adminBatchesProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminStudentsProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _unenroll(BuildContext context, WidgetRef ref, StudentDto student) async {
    try {
      await ref.read(academicRepositoryProvider).unenrollStudent(
            batchId: batchId,
            studentId: student.id,
          );
      ref.invalidate(adminBatchProvider(batchId));
      ref.invalidate(adminBatchStudentsProvider(batchId));
      ref.invalidate(adminBatchesProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminStudentsProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }
}

class _BatchEditCard extends ConsumerStatefulWidget {
  const _BatchEditCard({required this.batch, required this.batchId});

  final BatchDto batch;
  final String batchId;

  @override
  ConsumerState<_BatchEditCard> createState() => _BatchEditCardState();
}

class _BatchEditCardState extends ConsumerState<_BatchEditCard> {
  late final TextEditingController _name;
  late final TextEditingController _year;
  String? _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.batch.name);
    _year = TextEditingController(text: '${widget.batch.academicYear}');
    _status = widget.batch.status;
  }

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).updateBatch(widget.batchId, {
        'name': _name.text.trim(),
        'academic_year': int.parse(_year.text.trim()),
        'status': _status,
      });
      ref.invalidate(adminBatchProvider(widget.batchId));
      ref.invalidate(adminBatchesProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch updated.')));
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
    return DetailSection(
      title: 'Edit batch',
      children: [
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Batch name')),
        const SizedBox(height: 12),
        TextFormField(
          controller: _year,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Academic year'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_status),
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'closed', child: Text('Closed')),
            DropdownMenuItem(value: 'draft', child: Text('Draft')),
          ],
          onChanged: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save batch'),
        ),
      ],
    );
  }
}
