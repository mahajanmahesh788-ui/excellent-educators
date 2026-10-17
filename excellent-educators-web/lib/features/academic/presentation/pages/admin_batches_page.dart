import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_person_avatar.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/app_status_toggle.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

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
    final canAddLevel = levelsValue.maybeWhen(
      data: (levels) => AcademicLevelDto.availableNumbers(levels).isNotEmpty,
      orElse: () => true,
    );

    return AppScaffold(
      title: AppStrings.levels,
      floatingActionButton: canAddLevel
          ? FloatingActionButton.extended(
              onPressed: () => context.go(RoutePaths.adminBatchNew),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addLevel),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DirectoryToolbar(
            key: const ValueKey('admin-levels-toolbar'),
            searchHint: AppStrings.searchLevelName,
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
                    AppStrings.noLevelsYet,
                    icon: EmptyIcons.batches,
                    subtitle: AppStrings.addLevelsToOrganizeStudentsAndBatches,
                  );
                }

                if (filtered.isEmpty) {
                  return const EmptyHint(
                    AppStrings.noLevelsMatchYourSearch,
                    icon: EmptyIcons.search,
                    subtitle: AppStrings.tryADifferentSearchQuery,
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
                            ? AppStrings.n1Level
                            : '${filtered.length} levels',
                      );
                    }
                    final level = filtered[index - 1];
                    return AcademicLevelCard(
                      level: level,
                      onTap: () => context.go(RoutePaths.adminBatch(level.id)),
                      onStatusChanged: (active) async {
                        await ref.read(academicRepositoryProvider).updateLevel(
                          level.id,
                          {'status': active ? 'active' : 'inactive'},
                        );
                        ref.invalidate(adminLevelsProvider);
                      },
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
  final _year = TextEditingController(text: DateTime.now().year.toString());
  final _masterClasses = TextEditingController(text: '1');
  int? _selectedNumber;
  bool _saving = false;

  @override
  void dispose() {
    _year.dispose();
    _masterClasses.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final levels = ref.read(adminLevelsProvider).asData?.value ?? const [];
    final available = AcademicLevelDto.availableNumbers(levels);
    final number = available.contains(_selectedNumber)
        ? _selectedNumber
        : (available.isNotEmpty ? available.first : null);
    if (number == null) {
      showFailure(context, AppStrings.selectLevel);
      return;
    }
    setState(() => _saving = true);
    try {
      final level = await ref.read(academicRepositoryProvider).createLevel({
        'number': number,
        'academic_year': int.parse(_year.text.trim()),
        'master_classes_per_month': int.tryParse(_masterClasses.text.trim()) ?? 1,
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
    final levelsValue = ref.watch(adminLevelsProvider);

    return AppFormPage(
      title: AppStrings.addLevel,
      backTo: RoutePaths.adminBatches,
      child: AsyncBody(
        value: levelsValue,
        onRetry: () => ref.invalidate(adminLevelsProvider),
        builder: (levels) {
          final available = AcademicLevelDto.availableNumbers(levels);
          if (available.isEmpty) {
            return const EmptyHint(
              AppStrings.allLevelsCreated,
              icon: EmptyIcons.batches,
              subtitle: AppStrings.levels,
            );
          }

          final selected = available.contains(_selectedNumber)
              ? _selectedNumber
              : available.first;

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: AppStrings.selectLevel,
                    helperText: AppStrings.chooseLevelFromList,
                  ),
                  items: [
                    for (final number in available)
                      DropdownMenuItem(
                        value: number,
                        child: Text('Level $number'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _selectedNumber = value),
                  validator: (value) =>
                      value == null ? AppStrings.selectLevel : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.academicYear,
                    hintText: AppStrings.eG2026,
                  ),
                  validator: (value) =>
                      int.tryParse(value ?? '') == null
                          ? AppStrings.enterAValidYear
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _masterClasses,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.masterClassesPerMonth,
                    helperText:
                        AppStrings.everyStudentInThisLevelGetsThisManyEachMonth,
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 1 || parsed > 10) {
                      return AppStrings.enterANumberFrom1To10;
                    }
                    return null;
                  },
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
                      : const Text(AppStrings.createLevel),
                ),
              ],
            ),
          );
        },
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
      title: AppStrings.levelDetails,
      backTo: RoutePaths.adminBatches,
      body: AsyncBody(
        value: levelValue,
        onRetry: () => ref.invalidate(adminLevelProvider(widget.batchId)),
        builder: (level) {
          final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              );
          final compactBtn = FilledButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          IconButton(
                            tooltip: AppStrings.editLevel,
                            onPressed: () => _editLevelDialog(context, level),
                            icon: const Icon(Icons.edit_outlined),
                            color: Brand.navy,
                            visualDensity: VisualDensity.compact,
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
                                label: AppStrings.totalStudents,
                                value: '${level.studentsCount}',
                                color: Brand.navy,
                              ),
                              _MetricPill(
                                label: AppStrings.batchesSections,
                                value: '${level.batches.length}',
                                color: Brand.gold,
                              ),
                              _MetricPill(
                                label: AppStrings.masterTeachers,
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
                                style: compactBtn,
                                onPressed: () =>
                                    context.go(RoutePaths.adminLevelLearning(level.id)),
                                icon: const Icon(Icons.menu_book_outlined, size: 18),
                                label: const Text(AppStrings.learningJourney2),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  foregroundColor: const Color(0xFFB42318),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                ),
                                onPressed: () => _deleteLevel(context, level),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text(AppStrings.deleteLevel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.batchesSections, style: sectionTitleStyle),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.max50StudentsBatch,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: compactBtn,
                    onPressed: () => _addBatchDialog(context, level),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.addBatch),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (level.batches.isEmpty)
                const EmptyHint(
                  AppStrings.noBatchesInThisLevelYet,
                  icon: EmptyIcons.batches,
                  subtitle: AppStrings.tapAddBatchToCreateANewSection,
                  fillHeight: false,
                )
              else
                ...level.batches.map(
                  (batch) => _BatchRowCard(
                    levelId: level.id,
                    batch: batch,
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Master Teachers (${level.masterTeachers.length})',
                      style: sectionTitleStyle,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: compactBtn,
                    onPressed: () => _assignMasterTeacher(context, level),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text(AppStrings.addMasterTeacher),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (level.masterTeachers.isEmpty)
                const EmptyHint(
                  AppStrings.noMasterTeachersAssignedYet,
                  icon: EmptyIcons.teachers,
                  subtitle: AppStrings.addMasterTeachersToMentorStudents,
                  fillHeight: false,
                )
              else
                ...level.masterTeachers.map(
                  (teacher) => _LevelMasterTeacherCard(
                    levelId: level.id,
                    teacher: teacher,
                    onUnassign: () => _unassignMasterTeacher(context, level, teacher),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.assignedAssessments} (${level.assessments.length})',
                      style: sectionTitleStyle,
                    ),
                  ),
                  FilledButton.icon(
                    style: compactBtn,
                    onPressed: () => _assignAssessmentsDialog(context, level),
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: const Text(AppStrings.assignAssessments),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (level.assessments.isEmpty)
                const EmptyHint(
                  AppStrings.noAssessmentsAssignedYet,
                  icon: EmptyIcons.assessments,
                  subtitle: AppStrings.assignAssessmentsHelp,
                  fillHeight: false,
                )
              else
                ...level.assessments.map(
                  (item) => _LevelAssessmentCard(
                    assessment: item,
                    onTap: () => context.go(RoutePaths.adminAssessmentFor(item.id)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _assignAssessmentsDialog(
    BuildContext context,
    AcademicLevelDto level,
  ) async {
    final repo = ref.read(academicRepositoryProvider);
    final assessmentRepo = ref.read(assessmentRepositoryProvider);

    List<AptitudeAssessmentDto> assessments = const [];
    var selected = <String>{};
    var loading = true;
    String? loadError;
    var saving = false;

    try {
      final page = await assessmentRepo.adminAssessments(page: 1);
      assessments = assessmentRepo.parseAssessments(page);
      final assigned = await repo.levelAssessmentIds(level.id);
      selected = assigned.toSet();
      loading = false;
    } catch (error) {
      loading = false;
      loadError = '$error';
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Re-run load inside dialog if first paint was before data arrived.
          if (loading && loadError == null && assessments.isEmpty) {
            // no-op; state already set above before dialog
          }

          return AppModalDialog(
            title: AppStrings.assignAssessmentsTitle,
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${level.name} · ${AppStrings.assignAssessmentsHelp}',
                    style: const TextStyle(color: Brand.muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (loadError != null)
                    Text(loadError, style: const TextStyle(color: Color(0xFFB42318)))
                  else if (assessments.isEmpty)
                    const Text(
                      AppStrings.noAssessmentsYetCreateInAssessments,
                      style: TextStyle(color: Brand.muted, fontSize: 13),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: assessments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = assessments[index];
                          final checked = selected.contains(item.id);
                          return Material(
                            color: checked
                                ? Brand.navy.withValues(alpha: 0.06)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            child: CheckboxListTile(
                              value: checked,
                              onChanged: saving
                                  ? null
                                  : (value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          selected.add(item.id);
                                        } else {
                                          selected.remove(item.id);
                                        }
                                      });
                                    },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Brand.navy,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${item.status} · ${item.questionsCount} questions',
                                style: const TextStyle(
                                  color: Brand.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppDialogActions(
                    confirmLabel: AppStrings.saveAssignments,
                    isConfirming: saving,
                    onConfirm: assessments.isEmpty || loadError != null
                        ? null
                        : () async {
                            setDialogState(() => saving = true);
                            try {
                              await repo.syncLevelAssessments(
                                levelId: level.id,
                                assessmentIds: selected.toList(),
                              );
                              ref.invalidate(adminLevelProvider(level.id));
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(AppStrings.assessmentsAssigned),
                                  ),
                                );
                              }
                            } catch (error) {
                              setDialogState(() => saving = false);
                              if (ctx.mounted) showFailure(ctx, error);
                            }
                          },
                    onCancel: saving ? null : () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteLevel(BuildContext context, AcademicLevelDto level) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: AppStrings.deleteLevel,
      message:
          'Delete ${level.name}? Remove or move its batches first if delete fails.',
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(academicRepositoryProvider).deleteLevel(level.id);
      ref.invalidate(adminLevelsProvider);
      if (context.mounted) {
        context.go(RoutePaths.adminBatches);
      }
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
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
        emptyMessage: AppStrings.noMasterTeachersAvailableToAssignAllMasterTeachersAre,
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
        title: AppStrings.removeMasterTeacher,
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
              confirmLabel: AppStrings.remove,
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
    final masterCtrl = TextEditingController(text: '${level.masterClassesPerMonth}');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppModalDialog(
          title: AppStrings.editLevel,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.levelName,
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    level.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Brand.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.levelNameIsFixed,
                  style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: masterCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.masterClassesPerMonth,
                  ),
                  validator: (val) {
                    final parsed = int.tryParse(val ?? '');
                    if (parsed == null || parsed < 1 || parsed > 10) {
                      return AppStrings.enter1To10;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppDialogActions(
                  confirmLabel: AppStrings.save,
                  isConfirming: saving,
                  onConfirm: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => saving = true);
                    try {
                      await ref.read(academicRepositoryProvider).updateLevel(level.id, {
                        'master_classes_per_month': int.parse(masterCtrl.text.trim()),
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
        title: AppStrings.addBatchToLevel,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.batchName,
                  hintText: AppStrings.eGBatch2SectionA,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? AppStrings.enterName : null,
              ),
              const SizedBox(height: 20),
              AppDialogActions(
                confirmLabel: AppStrings.createBatch,
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

/// Prefer full batch activation date; fall back to cohort year/month.
String? _batchDateLabel(BatchDto batch) {
  final startsOn = batch.startsOn?.trim();
  if (startsOn != null && startsOn.isNotEmpty) {
    return formatDisplayDate(startsOn);
  }
  if (batch.monthName.isNotEmpty || batch.year != null) {
    return '${batch.year ?? batch.academicYear}'
        '${batch.monthName.isNotEmpty ? ' · ${batch.monthName}' : ''}';
  }
  return null;
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

  Future<void> _toggleStatus(bool _) async {
    await ref.read(academicRepositoryProvider).toggleBatchStatus(widget.batch.id);
    ref.invalidate(adminLevelProvider(widget.levelId));
    ref.invalidate(adminLevelsProvider);
  }

  Future<void> _deleteBatch() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: AppStrings.deleteBatch,
      message:
          'Delete ${widget.batch.name}? Active enrollments must be moved or removed first.',
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(academicRepositoryProvider).deleteBatch(widget.batch.id);
      ref.invalidate(adminLevelProvider(widget.levelId));
      ref.invalidate(adminLevelsProvider);
    } catch (e) {
      if (mounted) showFailure(context, e);
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
        title: AppStrings.editBatch,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: AppStrings.batchName),
                validator: (val) => val == null || val.trim().isEmpty ? AppStrings.enterName : null,
              ),
              const SizedBox(height: 20),
              AppDialogActions(
                confirmLabel: AppStrings.save,
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
        emptyMessage: AppStrings.noUnassignedStudentsFound,
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
            child: Builder(
              builder: (context) {
                final compact = MediaQuery.sizeOf(context).width < 600;
                final stripe = Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive ? Brand.gold : Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
                final title = Wrap(
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
                    if (_batchDateLabel(batch) != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _batchDateLabel(batch)!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    AppStatusToggle(
                      active: isActive,
                      onChanged: _toggleStatus,
                    ),
                  ],
                );
                final occupancy = Row(
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
                    Expanded(
                      child: Container(
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
                              color: batch.activeStudentCount >= 50 ? Colors.red : Brand.gold,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (batch.activeStudentCount >= 50) ...[
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          AppStrings.fullLimit50,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
                final iconActions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: AppStrings.editBatchNameYearMonth,
                      visualDensity: VisualDensity.compact,
                      onPressed: _editBatchDialog,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: AppStrings.deleteBatch,
                      visualDensity: VisualDensity.compact,
                      onPressed: _deleteBatch,
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB42318)),
                    ),
                    IconButton(
                      tooltip: _expanded ? AppStrings.hideStudents : AppStrings.viewStudents,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      ),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          stripe,
                          const SizedBox(width: 12),
                          Expanded(child: title),
                          iconActions,
                        ],
                      ),
                      const SizedBox(height: 8),
                      occupancy,
                    ],
                  );
                }

                return Row(
                  children: [
                    stripe,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 6),
                          occupancy,
                        ],
                      ),
                    ),
                    iconActions,
                  ],
                );
              },
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
                AppStrings.enrolledStudents,
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
                label: const Text(AppStrings.addStudentToBatch, style: TextStyle(fontSize: 12)),
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
                    AppStrings.noStudentsCurrentlyInThisBatch,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: [
                  for (final student in students) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () =>
                              context.go(RoutePaths.adminStudent(student.id)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                AppPersonAvatar(
                                  name: student.fullName,
                                  photoUrl: student.photoUrl,
                                  radius: 14,
                                  backgroundColor:
                                      Brand.navy.withValues(alpha: 0.1),
                                  foregroundColor: Brand.navy,
                                  maxInitials: 1,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  tooltip: AppStrings.removeFromBatch,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () => onUnenrollStudent(student),
                                ),
                              ],
                            ),
                          ),
                        ),
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

class _LevelAssessmentCard extends StatelessWidget {
  const _LevelAssessmentCard({
    required this.assessment,
    required this.onTap,
  });

  final LevelAssessmentSummaryDto assessment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = assessment.status == 'active'
        ? const Color(0xFF2E7D52)
        : Brand.muted;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE6DCCB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Brand.navy.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: Brand.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assessment.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Brand.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${assessment.questionsCount} questions'
                      '${assessment.submittedAttemptsCount > 0 ? ' · ${assessment.submittedAttemptsCount} submissions' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  assessment.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
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
              backgroundColor: const Color(0xFF5BB98C).withValues(alpha: 0.15),
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
              tooltip: AppStrings.removeFromLevel,
              icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
              onPressed: onUnassign,
            ),
          ],
        ),
      ),
    );
  }
}
