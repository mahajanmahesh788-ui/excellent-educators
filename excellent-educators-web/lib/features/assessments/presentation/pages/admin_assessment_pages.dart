import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';
import 'package:excellent_educators_web/features/assessments/domain/dimension_catalog.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/assessments/presentation/widgets/assessment_result_view.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/admin_onboarding_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminAssessmentsPage extends ConsumerStatefulWidget {
  const AdminAssessmentsPage({super.key});

  @override
  ConsumerState<AdminAssessmentsPage> createState() =>
      _AdminAssessmentsPageState();
}

class _AdminAssessmentsPageState extends ConsumerState<AdminAssessmentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(adminAssessmentsProvider);
    final repo = ref.watch(assessmentRepositoryProvider);
    final isMobile = Breakpoints.isMobile(context);
    final showFab = _tabs.index == 0;

    return AppScaffold(
      title: AppStrings.assessments,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.go(RoutePaths.adminAssessmentNew),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newAssessment),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Brand.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Brand.muted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz_outlined, size: 15),
                      SizedBox(width: 6),
                      Text(AppStrings.assessments),
                    ],
                  ),
                ),
                Tab(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.interests_outlined, size: 15),
                      SizedBox(width: 6),
                      Text(AppStrings.interests),
                    ],
                  ),
                ),
                Tab(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.family_restroom_outlined, size: 15),
                      SizedBox(width: 6),
                      Text(AppStrings.parentIntake),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                AsyncBody(
                  value: page,
                  onRetry: () => ref.invalidate(adminAssessmentsProvider),
                  builder: (result) {
                    final items = repo.parseAssessments(result);
                    if (items.isEmpty) {
                      return const EmptyHint(
                        AppStrings.noAptitudeAssessmentsYet,
                        icon: EmptyIcons.assessments,
                        subtitle: AppStrings
                            .createAnAssessmentAndAddQuestionsForStudentsToTake,
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.only(
                        top: 2,
                        bottom: isMobile ? 80 : 40,
                      ),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 8 : 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Row(
                            children: [
                              Text(
                                '${items.length} ${items.length == 1 ? "Assessment" : "Assessments"}',
                                style: const TextStyle(
                                  color: Brand.muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (!isMobile)
                                FilledButton.icon(
                                  onPressed: () => context.go(RoutePaths.adminAssessmentNew),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(AppStrings.newAssessment),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                            ],
                          );
                        }
                        final assessment = items[index - 1];
                        return _AdminAssessmentCard(
                          assessment: assessment,
                          onTap: () => context.go(
                            RoutePaths.adminAssessmentFor(assessment.id),
                          ),
                          onAttempts: () => context.go(
                            RoutePaths.adminAssessmentAttemptsFor(assessment.id),
                          ),
                        );
                      },
                    );
                  },
                ),
                const AdminInterestQuestionsPanel(),
                const AdminParentQuestionsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAssessmentCard extends StatelessWidget {
  const _AdminAssessmentCard({
    required this.assessment,
    required this.onTap,
    required this.onAttempts,
  });

  final AptitudeAssessmentDto assessment;
  final VoidCallback onTap;
  final VoidCallback onAttempts;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final isActive = assessment.status.toLowerCase() == 'active';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: 11,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            assessment.title,
                            style: const TextStyle(
                              color: Brand.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(isActive: isActive),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Brand.muted.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Brand.navy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.help_outline, size: 12, color: Brand.navy),
                        const SizedBox(width: 4),
                        Text(
                          '${assessment.questionsCount} questions',
                          style: const TextStyle(
                            color: Brand.navy,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (assessment.createdAt != null && !isMobile) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule, size: 12, color: Brand.muted),
                    const SizedBox(width: 3),
                    Text(
                      formatDisplayDateTime(assessment.createdAt),
                      style: const TextStyle(
                        color: Brand.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onAttempts,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Brand.navy,
                    ),
                    icon: const Icon(Icons.people_alt_outlined, size: 14),
                    label: const Text(
                      AppStrings.assessmentAttempts,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? AppStrings.active : AppStrings.inactive,
            style: TextStyle(
              color: isActive ? const Color(0xFF065F46) : const Color(0xFF475569),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      title: id == null ? AppStrings.newAssessment : AppStrings.editAssessment,
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
        dimensionCodes = List<String>.from(dimensionCodes ?? const [AppStrings.tw]);

  final String? id;
  final TextEditingController text;
  List<String> dimensionCodes;

  void dispose() {
    text.dispose();
  }
}

class _AssessmentEditorFormState extends ConsumerState<_AssessmentEditorForm> {
  final _title = TextEditingController();
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
                      dimensionCodes: option.dimensionCodes.isEmpty ? const [AppStrings.tw] : option.dimensionCodes,
                    ),
                ],
              ),
          ];
  }

  Map<String, dynamic> _payload() {
    return {
      'title': _title.text.trim(),
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
      return AppStrings.titleIsRequired;
    }
    if (_questions.isEmpty) {
      return AppStrings.addAtLeastOneQuestion;
    }
    for (final question in _questions) {
      if (question.text.text.trim().isEmpty) {
        return AppStrings.everyQuestionNeedsText;
      }
      if (question.options.isEmpty) {
        return AppStrings.everyQuestionMustHaveOptions;
      }
      for (final option in question.options) {
        if (option.text.text.trim().isEmpty) {
          return AppStrings.everyOptionNeedsText;
        }
        if (!DimensionCatalog.areValid(option.dimensionCodes)) {
          return AppStrings.eachOptionNeedsDimensionCodes(
            DimensionCatalog.maxCodesPerOption,
          );
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
    final isMobile = Breakpoints.isMobile(context);
    final hasId = widget.assessmentId != null;

    return ListView(
      key: const PageStorageKey('admin-assessment-editor'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(
        top: 4,
        bottom: isMobile ? 80 : 48,
      ),
      children: [
        // Top Summary & Action Bar
        Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            hasId ? (_title.text.isNotEmpty ? _title.text : AppStrings.editAssessment) : AppStrings.newAssessment,
                            style: TextStyle(
                              color: Brand.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 15 : 17,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasId && _status != null) ...[
                          const SizedBox(width: 8),
                          _StatusBadge(isActive: _status == 'active'),
                        ],
                      ],
                    ),
                  ),
                  if (hasId) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.go(RoutePaths.adminAssessmentAttemptsFor(widget.assessmentId!)),
                      icon: const Icon(Icons.people_alt_outlined, size: 14),
                      label: const Text(
                        AppStrings.assessmentAttempts,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        foregroundColor: Brand.navy,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Assessment Title Input
        TextField(
          controller: _title,
          style: const TextStyle(
            color: Brand.navy,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            labelText: AppStrings.title,
            hintText: AppStrings.assessmentTitleHint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        // Questions Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${AppStrings.questions} (${_questions.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Brand.navy,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => setState(() => _questions.add(_QuestionDraft())),
              icon: const Icon(Icons.add, size: 15),
              label: const Text(AppStrings.addQuestion),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                foregroundColor: Brand.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var q = 0; q < _questions.length; q++) _questionEditor(q),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _questions.add(_QuestionDraft())),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(AppStrings.addQuestion),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(),
              icon: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 15),
              label: const Text(AppStrings.save),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            FilledButton.tonal(
              onPressed: _saving ? null : () => _save(activate: true),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text(AppStrings.saveAndActivate),
            ),
            if (hasId) ...[
              OutlinedButton(
                onPressed: _saving ? null : _toggleStatus,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(_status == 'active' ? AppStrings.deactivate : AppStrings.activate),
              ),
              OutlinedButton(
                onPressed: _saving ? null : _deleteAssessment,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: const Color(0xFFB42318),
                ),
                child: const Text(AppStrings.deleteAssessment),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _deleteAssessment() async {
    final id = widget.assessmentId;
    if (id == null) {
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: AppStrings.deleteAssessment,
      message: AppStrings.deleteAssessmentHelp,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(assessmentRepositoryProvider).deleteAssessment(id);
      ref.invalidate(adminAssessmentsProvider);
      if (mounted) {
        context.go(RoutePaths.adminAssessments);
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

  Widget _questionEditor(int index) {
    final question = _questions[index];
    final isMobile = Breakpoints.isMobile(context);

    return Card(
      key: ValueKey(question.id ?? 'question-$index'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Brand.navy,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppStrings.questionBadge(index + 1),
                    style: const TextStyle(
                      color: Brand.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.questionNumberLabel(index + 1),
                  style: const TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {
                    final removed = _questions.removeAt(index);
                    removed.dispose();
                  }),
                  tooltip: AppStrings.deleteQuestion,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB42318)),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: question.text,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Brand.navyDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.question,
                    hintText: AppStrings.enterAptitudeQuestionText,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: 10),
                // Options Subheader
                Row(
                  children: [
                    Text(
                      AppStrings.answerOptionsCountLabel(question.options.length),
                      style: const TextStyle(
                        color: Brand.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => question.options.add(_OptionDraft())),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text(
                        AppStrings.addOption,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var o = 0; o < question.options.length; o++)
                  _optionEditor(index, question, o),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Brand.navy,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: option.text,
              style: const TextStyle(
                color: Brand.ink,
                fontSize: 12.5,
                height: 1.25,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.optionHint(index + 1),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: AppStrings.setDimensionCodes,
            child: InkWell(
              onTap: () => _pickDimensionCodes(option),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: option.dimensionCodes.isEmpty ? const Color(0xFFF8FAFC) : Brand.navy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: option.dimensionCodes.isEmpty ? const Color(0xFFCBD5E1) : Brand.navy.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 13,
                      color: option.dimensionCodes.isEmpty ? Brand.muted : Brand.navy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      codeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: option.dimensionCodes.isEmpty ? Brand.muted : Brand.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => setState(() {
              final removed = question.options.removeAt(index);
              removed.dispose();
            }),
            tooltip: AppStrings.removeOption,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: const Icon(Icons.close, size: 16, color: Brand.muted),
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
              title: AppStrings.selectCodes,
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
                    confirmLabel: AppStrings.done,
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
    final isMobile = Breakpoints.isMobile(context);

    return AppScaffold(
      title: AppStrings.assessmentAttempts,
      backTo: RoutePaths.adminAssessmentFor(assessmentId),
      body: AsyncBody(
        value: attempts,
        onRetry: () => ref.invalidate(adminAssessmentAttemptsProvider(assessmentId)),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyHint(
              AppStrings.noSubmissionsYet,
              icon: EmptyIcons.students,
              subtitle: AppStrings.studentAptitudeAttemptsWillAppearHereAfterTheySubmit,
            );
          }
          return ListView.separated(
            padding: EdgeInsets.only(
              top: 4,
              bottom: isMobile ? 80 : 40,
            ),
            itemCount: items.length + 1,
            separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 8 : 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${items.length} ${items.length == 1 ? "Student Submission" : "Student Submissions"}',
                    style: const TextStyle(
                      color: Brand.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              final result = items[index - 1];
              return _AttemptCard(result: result);
            },
          );
        },
      ),
    );
  }
}

class _AttemptCard extends StatefulWidget {
  const _AttemptCard({required this.result});

  final AssessmentResultDto result;

  @override
  State<_AttemptCard> createState() => _AttemptCardState();
}

class _AttemptCardState extends State<_AttemptCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isMobile = Breakpoints.isMobile(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Icon(Icons.check, size: 15, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.studentName ?? AppStrings.student,
                        style: const TextStyle(
                          color: Brand.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (result.submittedAt != null)
                        Text(
                          AppStrings.submittedAtLabel(
                            formatDisplayDateTime(result.submittedAt),
                          ),
                          style: const TextStyle(color: Brand.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Brand.navy,
                  ),
                  icon: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.bar_chart,
                    size: 14,
                  ),
                  label: Text(
                    _expanded ? AppStrings.hideCharts : AppStrings.viewCharts,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AssessmentResultView(
              result: result,
              compact: !_expanded,
              showCharts: _expanded,
              showTitle: false,
            ),
          ],
        ),
      ),
    );
  }
}
