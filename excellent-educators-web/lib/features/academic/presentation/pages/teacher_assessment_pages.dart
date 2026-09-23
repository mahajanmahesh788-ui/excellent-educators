import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/assessment_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class TeacherBatchAssessmentsPage extends ConsumerWidget {
  const TeacherBatchAssessmentsPage({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessments = ref.watch(teacherBatchAssessmentsProvider(batchId));

    return AppScaffold(
      title: AppStrings.assessments,
      backTo: RoutePaths.teacherBatch(batchId),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.teacherAssessmentNewFor(batchId)),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newAssessment),
      ),
      body: AsyncBody(
        value: assessments,
        onRetry: () => ref.invalidate(teacherBatchAssessmentsProvider(batchId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              AppStrings.noAssessmentsYet,
              icon: EmptyIcons.assessments,
              subtitle: AppStrings.createOneToRecordAndScoreYourBatch,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final assessment = items[index];
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE6DCCB)),
                ),
                child: ListTile(
                  title: Text(assessment.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    'Max ${assessment.maxScore} · ${assessment.scoredCount} scored · v${assessment.version} · ${assessment.status}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(RoutePaths.teacherAssessmentFor(batchId, assessment.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TeacherCreateAssessmentPage extends ConsumerStatefulWidget {
  const TeacherCreateAssessmentPage({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<TeacherCreateAssessmentPage> createState() => _TeacherCreateAssessmentPageState();
}

class _TeacherCreateAssessmentPageState extends ConsumerState<TeacherCreateAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _maxScore = TextEditingController(text: '20');
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _maxScore.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final assessment = await ref.read(academicRepositoryProvider).createAssessment(widget.batchId, {
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'max_score': double.parse(_maxScore.text.trim()),
        'status': 'published',
      });
      ref.invalidate(teacherBatchAssessmentsProvider(widget.batchId));
      if (mounted) {
        context.go(RoutePaths.teacherAssessmentFor(widget.batchId, assessment.id));
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
      title: AppStrings.newAssessment,
      backTo: RoutePaths.teacherAssessmentsFor(widget.batchId),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: AppStrings.title),
              validator: (value) => validateRequired(value, message: AppStrings.required2),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: AppStrings.descriptionOptional),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxScore,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: AppStrings.maxScore),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return AppStrings.enterAValidMaxScore;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(AppStrings.createAndScore),
            ),
          ],
        ),
      ),
    );
  }

}

class TeacherAssessmentDetailPage extends ConsumerStatefulWidget {
  const TeacherAssessmentDetailPage({
    super.key,
    required this.batchId,
    required this.assessmentId,
  });

  final String batchId;
  final String assessmentId;

  @override
  ConsumerState<TeacherAssessmentDetailPage> createState() => _TeacherAssessmentDetailPageState();
}

class _TeacherAssessmentDetailPageState extends ConsumerState<TeacherAssessmentDetailPage> {
  final _scoreControllers = <String, TextEditingController>{};
  bool _saving = false;
  String? _boundKey;

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _bindScores(List<StudentDto> students, List<AssessmentScoreDto> scores) {
    final key = '${widget.assessmentId}-${scores.length}-${students.length}';
    if (_boundKey == key) {
      return;
    }
    _boundKey = key;
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    _scoreControllers.clear();
    final scoreMap = {for (final score in scores) score.studentId: score.score};
    for (final student in students) {
      final existing = scoreMap[student.id];
      _scoreControllers[student.id] = TextEditingController(
        text: existing == null ? '' : existing.toString(),
      );
    }
  }

  Future<void> _save(AssessmentDto assessment, List<StudentDto> students) async {
    setState(() => _saving = true);
    try {
      final scores = [
        for (final student in students)
          {
            'student_id': student.id,
            'score': _parseScore(_scoreControllers[student.id]?.text),
          },
      ];
      await ref.read(academicRepositoryProvider).recordAssessmentScores(
            widget.batchId,
            widget.assessmentId,
            scores,
          );
      ref.invalidate(teacherAssessmentProvider((batchId: widget.batchId, assessmentId: widget.assessmentId)));
      ref.invalidate(teacherAssessmentScoresProvider((batchId: widget.batchId, assessmentId: widget.assessmentId)));
      ref.invalidate(teacherBatchAssessmentsProvider(widget.batchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.scoresSaved)));
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

  double? _parseScore(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final assessmentValue = ref.watch(
      teacherAssessmentProvider((batchId: widget.batchId, assessmentId: widget.assessmentId)),
    );
    final studentsValue = ref.watch(teacherBatchStudentsProvider(widget.batchId));
    final scoresValue = ref.watch(
      teacherAssessmentScoresProvider((batchId: widget.batchId, assessmentId: widget.assessmentId)),
    );

    return AppScaffold(
      title: AppStrings.scoreAssessment,
      backTo: RoutePaths.teacherAssessmentsFor(widget.batchId),
      body: AsyncBody(
        value: assessmentValue,
        onRetry: () => ref.invalidate(
          teacherAssessmentProvider((batchId: widget.batchId, assessmentId: widget.assessmentId)),
        ),
        builder: (assessment) {
          return AsyncBody(
            value: studentsValue,
            onRetry: () => ref.invalidate(teacherBatchStudentsProvider(widget.batchId)),
            builder: (students) {
              return AsyncBody(
                value: scoresValue,
                onRetry: () => ref.invalidate(
                  teacherAssessmentScoresProvider((batchId: widget.batchId, assessmentId: widget.assessmentId)),
                ),
                builder: (payload) {
                  _bindScores(students, payload.scores);
                  return ListView(
                    children: [
                      DetailSection(
                        title: assessment.title,
                        children: [
                          DetailRow(label: AppStrings.maxScore, value: '${assessment.maxScore}'),
                          DetailRow(label: AppStrings.version, value: 'v${assessment.version}'),
                          DetailRow(label: AppStrings.status2, value: assessment.status),
                          if (assessment.description != null && assessment.description!.isNotEmpty)
                            DetailRow(label: AppStrings.notes, value: assessment.description!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(AppStrings.students, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...students.map((student) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(student.studentCode, style: const TextStyle(color: Brand.muted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 88,
                                child: TextField(
                                  controller: _scoreControllers[student.id],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.score2,
                                    isDense: true,
                                    hintText: '0-${assessment.maxScore}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saving ? null : () => _save(assessment, students),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text(AppStrings.saveScores),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
