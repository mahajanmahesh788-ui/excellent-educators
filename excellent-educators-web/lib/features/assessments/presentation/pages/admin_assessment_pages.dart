import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/domain/dimension_catalog.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/assessment_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminAssessmentsPage extends ConsumerWidget {
  const AdminAssessmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(adminAssessmentsProvider);
    final repo = ref.watch(assessmentRepositoryProvider);

    return AppScaffold(
      title: 'Assessments',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.adminAssessmentNew),
        icon: const Icon(Icons.add),
        label: const Text('New assessment'),
      ),
      body: AsyncBody(
        value: page,
        onRetry: () => ref.invalidate(adminAssessmentsProvider),
        builder: (result) {
          final items = repo.parseAssessments(result);
          if (items.isEmpty) {
            return const EmptyHint(
              'No aptitude assessments yet',
              icon: EmptyIcons.assessments,
              subtitle: 'Create an assessment and add questions for students to take.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final assessment = items[index];
              final level = assessment.careerCompassLevel;
              return Card(
                child: ListTile(
                  title: Text(assessment.title),
                  subtitle: Text(
                    [
                      if (level != null) level.displayName,
                      assessment.status,
                      '${assessment.questionsCount} questions',
                      if (assessment.createdAt != null) formatDisplayDateTime(assessment.createdAt),
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(RoutePaths.adminAssessmentFor(assessment.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminAssessmentEditorPage extends ConsumerWidget {
  const AdminAssessmentEditorPage({super.key, this.assessmentId});

  final String? assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = assessmentId;

    return AppScaffold(
      title: id == null ? 'New assessment' : 'Edit assessment',
      backTo: RoutePaths.adminAssessments,
      body: id == null
          ? const _AssessmentEditorForm()
          : AsyncBody(
              value: ref.watch(adminAssessmentProvider(id)),
              onRetry: () => ref.invalidate(adminAssessmentProvider(id)),
              builder: (assessment) => _AssessmentEditorForm(
                key: ValueKey(assessment.id),
                assessmentId: id,
                initialAssessment: assessment,
              ),
            ),
    );
  }
}

class _AssessmentEditorForm extends ConsumerStatefulWidget {
  const _AssessmentEditorForm({
    super.key,
    this.assessmentId,
    this.initialAssessment,
  });

  final String? assessmentId;
  final AptitudeAssessmentDto? initialAssessment;

  @override
  ConsumerState<_AssessmentEditorForm> createState() => _AssessmentEditorFormState();
}

class _QuestionDraft {
  _QuestionDraft({this.id, String text = '', List<_OptionDraft>? options})
      : text = TextEditingController(text: text),
        options = options ?? [_OptionDraft(), _OptionDraft()];

  final String? id;
  final TextEditingController text;
  List<_OptionDraft> options;

  void dispose() {
    text.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _OptionDraft {
  _OptionDraft({this.id, String text = '', List<String>? dimensionCodes})
      : text = TextEditingController(text: text),
        dimensionCodes = List<String>.from(dimensionCodes ?? const ['TW']);

  final String? id;
  final TextEditingController text;
  List<String> dimensionCodes;

  void dispose() {
    text.dispose();
  }
}

class _AssessmentEditorFormState extends ConsumerState<_AssessmentEditorForm> {
  final _title = TextEditingController();
  String? _levelId;
  String? _status;
  bool _saving = false;
  List<_QuestionDraft> _questions = [_QuestionDraft()];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAssessment;
    if (initial != null) {
      _applyInitial(initial);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _applyInitial(AptitudeAssessmentDto assessment) {
    _title.text = assessment.title;
    _levelId = assessment.careerCompassLevel?.id ?? assessment.careerCompassLevelId;
    _status = assessment.status;
    for (final question in _questions) {
      question.dispose();
    }
    _questions = assessment.questions.isEmpty
        ? [_QuestionDraft()]
        : [
            for (final question in assessment.questions)
              _QuestionDraft(
                id: question.id,
                text: question.questionText,
                options: [
                  for (final option in question.options)
                    _OptionDraft(
                      id: option.id,
                      text: option.optionText,
                      dimensionCodes: option.dimensionCodes.isEmpty ? const ['TW'] : option.dimensionCodes,
                    ),
                ],
              ),
          ];
  }

  Map<String, dynamic> _payload() {
    return {
      'title': _title.text.trim(),
      'career_compass_level_id': _levelId,
      'questions': [
        for (var i = 0; i < _questions.length; i++)
          {
            'question_text': _questions[i].text.text.trim(),
            'display_order': i + 1,
            'options': [
              for (var j = 0; j < _questions[i].options.length; j++)
                {
                  'option_text': _questions[i].options[j].text.text.trim(),
                  'dimension_codes': _questions[i].options[j].dimensionCodes,
                  'display_order': j + 1,
                },
            ],
          },
      ],
    };
  }

  String? _validate() {
    if (_title.text.trim().isEmpty) {
      return 'Title is required.';
    }
    if (_levelId == null) {
      return 'Select a Career Compass level.';
    }
    if (_questions.isEmpty) {
      return 'Add at least one question.';
    }
    for (final question in _questions) {
      if (question.text.text.trim().isEmpty) {
        return 'Every question needs text.';
      }
      if (question.options.isEmpty) {
        return 'Every question must have options.';
      }
      for (final option in question.options) {
        if (option.text.text.trim().isEmpty) {
          return 'Every option needs text.';
        }
        if (!DimensionCatalog.areValid(option.dimensionCodes)) {
          return 'Each option needs 1 to ${DimensionCatalog.maxCodesPerOption} unique dimension codes.';
        }
      }
    }
    return null;
  }

  Future<void> _save({bool activate = false}) async {
    final error = _validate();
    if (error != null) {
      showFailure(context, error);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(assessmentRepositoryProvider);
      AptitudeAssessmentDto saved;
      if (widget.assessmentId == null) {
        saved = await repo.createAssessment(_payload());
      } else {
        saved = await repo.updateAssessment(widget.assessmentId!, _payload());
      }
      if (activate) {
        saved = await repo.activate(saved.id);
      }
      ref.invalidate(adminAssessmentsProvider);
      ref.invalidate(adminAssessmentProvider(saved.id));
      if (mounted) {
        context.go(RoutePaths.adminAssessmentFor(saved.id));
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

  Future<void> _toggleStatus() async {
    final id = widget.assessmentId;
    if (id == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(assessmentRepositoryProvider);
      if (_status == 'active') {
        await repo.deactivate(id);
        setState(() => _status = 'inactive');
      } else {
        await repo.activate(id);
        setState(() => _status = 'active');
      }
      ref.invalidate(adminAssessmentsProvider);
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

    return ListView(
      key: const PageStorageKey('admin-assessment-editor'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 12),
        AsyncBody(
          value: levels,
          builder: (items) {
            return DropdownButtonFormField<String>(
              key: const ValueKey('assessment-level-dropdown'),
              initialValue: _levelId,
              decoration: const InputDecoration(labelText: 'Career Compass level'),
              items: [
                for (final level in items)
                  DropdownMenuItem(value: level.id, child: Text(level.displayName)),
              ],
              onChanged: (value) => setState(() => _levelId = value),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('Questions', style: TextStyle(fontWeight: FontWeight.w700, color: Brand.navy)),
        const SizedBox(height: 8),
        for (var q = 0; q < _questions.length; q++) _questionEditor(q),
        TextButton.icon(
          onPressed: () => setState(() => _questions.add(_QuestionDraft())),
          icon: const Icon(Icons.add),
          label: const Text('Add question'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _saving ? null : () => _save(),
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
            FilledButton.tonal(
              onPressed: _saving ? null : () => _save(activate: true),
              child: const Text('Save and activate'),
            ),
            if (widget.assessmentId != null)
              OutlinedButton(
                onPressed: _saving ? null : _toggleStatus,
                child: Text(_status == 'active' ? 'Deactivate' : 'Activate'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _questionEditor(int index) {
    final question = _questions[index];
    return Card(
      key: ValueKey(question.id ?? 'question-$index'),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Brand.navyDeep.withValues(alpha: 0.08),
                  Brand.navy.withValues(alpha: 0.04),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Brand.gold.withValues(alpha: 0.35)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Brand.navyDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(
                      color: Brand.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: question.text,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Brand.navyDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Question',
                      labelStyle: TextStyle(
                        color: Brand.navy.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Brand.navy.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Brand.gold, width: 1.5),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    final removed = _questions.removeAt(index);
                    removed.dispose();
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFFAF7F0),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Answer options',
                  style: TextStyle(
                    color: Brand.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                for (var o = 0; o < question.options.length; o++) _optionEditor(index, question, o),
                TextButton(
                  onPressed: () => setState(() => question.options.add(_OptionDraft())),
                  child: const Text('Add option'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionEditor(int questionIndex, _QuestionDraft question, int index) {
    final option = question.options[index];
    final codeLabel = option.dimensionCodes.isEmpty ? '—' : option.dimensionCodes.join(', ');

    return Padding(
      key: ValueKey(option.id ?? 'q$questionIndex-o$index'),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: option.text,
              style: const TextStyle(
                color: Brand.ink,
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 1.3,
              ),
              decoration: InputDecoration(
                labelText: 'Option ${index + 1}',
                labelStyle: const TextStyle(color: Brand.muted, fontSize: 12),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8E0D4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Brand.gold.withValues(alpha: 0.7)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _pickDimensionCodes(option),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(56, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.white,
            ),
            child: Text(
              codeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: option.dimensionCodes.isEmpty ? Brand.muted : Brand.navy,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              final removed = question.options.removeAt(index);
              removed.dispose();
            }),
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDimensionCodes(_OptionDraft option) async {
    final selected = List<String>.from(option.dimensionCodes);

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppModalDialog(
              title: 'Select codes',
              maxWidth: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final dimension in DimensionCatalog.values)
                    CheckboxListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        '${dimension.code} · ${dimension.name}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: selected.contains(dimension.code),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            if (selected.length >= DimensionCatalog.maxCodesPerOption) {
                              return;
                            }
                            selected.add(dimension.code);
                          } else {
                            selected.remove(dimension.code);
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  AppDialogActions(
                    confirmLabel: 'Done',
                    onCancel: () => Navigator.pop(dialogContext),
                    onConfirm: selected.isEmpty
                        ? null
                        : () {
                            setState(() => option.dimensionCodes = List<String>.from(selected));
                            Navigator.pop(dialogContext);
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AdminAssessmentAttemptsPage extends ConsumerWidget {
  const AdminAssessmentAttemptsPage({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempts = ref.watch(adminAssessmentAttemptsProvider(assessmentId));

    return AppScaffold(
      title: 'Assessment attempts',
      backTo: RoutePaths.adminAssessmentFor(assessmentId),
      body: AsyncBody(
        value: attempts,
        onRetry: () => ref.invalidate(adminAssessmentAttemptsProvider(assessmentId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              'No submissions yet',
              icon: EmptyIcons.students,
              subtitle: 'Student aptitude attempts will appear here after they submit.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final result = items[index];
              return DetailSection(
                title: result.studentName ?? 'Student',
                children: [
                  if (result.submittedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 6),
                          Text(
                            'Submitted ${formatDisplayDateTime(result.submittedAt)}',
                            style: const TextStyle(color: Brand.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  AssessmentResultView(result: result),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
