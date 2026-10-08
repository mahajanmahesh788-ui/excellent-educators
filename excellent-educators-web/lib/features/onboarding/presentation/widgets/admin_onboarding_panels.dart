import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/onboarding/data/dto/onboarding_dtos.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminInterestQuestionsPanel extends ConsumerStatefulWidget {
  const AdminInterestQuestionsPanel({super.key});

  @override
  ConsumerState<AdminInterestQuestionsPanel> createState() =>
      _AdminInterestQuestionsPanelState();
}

class _AdminInterestQuestionsPanelState
    extends ConsumerState<AdminInterestQuestionsPanel> {
  final _drafts = <_InterestQuestionDraft>[];
  var _bound = false;
  var _saving = false;

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _load(List<InterestQuestionDto> questions) {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts
      ..clear()
      ..addAll(questions.map(_InterestQuestionDraft.fromDto));
    if (_drafts.isEmpty) {
      _drafts.add(_InterestQuestionDraft());
    }
    _bound = true;
  }

  Future<void> _save() async {
    if (_saving) return;
    final payload = <Map<String, dynamic>>[];
    for (final draft in _drafts) {
      final text = draft.question.text.trim();
      final options = draft.options
          .map((option) => option.text.text.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (text.isEmpty || options.isEmpty) {
        showFailure(context, AppStrings.addAtLeastOneQuestion);
        return;
      }
      payload.add({
        if (draft.id != null && draft.id!.isNotEmpty) 'id': draft.id,
        'question_text': text,
        'allow_other': draft.allowOther,
        'max_selections': draft.maxSelections,
        'is_active': true,
        'options': [
          for (var i = 0; i < draft.options.length; i++)
            if (draft.options[i].text.text.trim().isNotEmpty)
              {
                if (draft.options[i].id != null &&
                    draft.options[i].id!.isNotEmpty)
                  'id': draft.options[i].id,
                'option_text': draft.options[i].text.text.trim(),
                'is_active': true,
              },
        ],
      });
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .upsertInterestQuestions(payload);
      ref.invalidate(adminInterestQuestionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsSaved)),
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminInterestQuestionsProvider);
    final isMobile = Breakpoints.isMobile(context);

    return AsyncBody(
      value: async,
      onRetry: () => ref.invalidate(adminInterestQuestionsProvider),
      builder: (questions) {
        if (!_bound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _load(questions));
          });
        }
        return ListView(
          padding: EdgeInsets.only(
            top: 4,
            bottom: isMobile ? 80 : 48,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppStrings.interestQuestions,
                            style: TextStyle(
                              color: Brand.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 15 : 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Brand.navy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_drafts.length}',
                              style: const TextStyle(
                                color: Brand.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        AppStrings.interestQuestionsHelp,
                        style: TextStyle(color: Brand.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(_saving ? AppStrings.saving : AppStrings.save),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _drafts.length; i++)
              _InterestQuestionCard(
                index: i,
                draft: _drafts[i],
                onRemove: _drafts.length <= 1
                    ? null
                    : () => setState(() {
                        final removed = _drafts.removeAt(i);
                        removed.dispose();
                      }),
                onChanged: () => setState(() {}),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _drafts.add(_InterestQuestionDraft())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(AppStrings.addQuestion),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Brand.navy,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_saving ? AppStrings.saving : AppStrings.save),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InterestQuestionCard extends StatelessWidget {
  const _InterestQuestionCard({
    required this.index,
    required this.draft,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _InterestQuestionDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Card(
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
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE2E8F0)),
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
                const Text(
                  AppStrings.interestQuestionLabel,
                  style: TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    tooltip: AppStrings.removeQuestion,
                    visualDensity: VisualDensity.compact,
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
                  controller: draft.question,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Brand.navy,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.questions,
                    hintText: AppStrings.enterQuestionPrompt,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                // Compact Controls Row (Allow Other & Max Selections)
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        draft.allowOther = !draft.allowOther;
                        onChanged();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: draft.allowOther
                              ? Brand.navy.withValues(alpha: 0.06)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: draft.allowOther ? Brand.navy : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              draft.allowOther ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 15,
                              color: draft.allowOther ? Brand.navy : Brand.muted,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              AppStrings.allowOther,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Brand.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '${AppStrings.maxSelections}: ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Brand.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: draft.maxSelections,
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Brand.navy,
                              ),
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1')),
                                DropdownMenuItem(value: 2, child: Text('2')),
                                DropdownMenuItem(value: 3, child: Text('3')),
                                DropdownMenuItem(value: 4, child: Text('4')),
                                DropdownMenuItem(value: 5, child: Text('5')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                draft.maxSelections = value;
                                onChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Options Subheader
                Row(
                  children: [
                    Text(
                      AppStrings.optionsCountLabel(draft.options.length),
                      style: const TextStyle(
                        color: Brand.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        draft.options.add(_InterestOptionDraft());
                        onChanged();
                      },
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
                for (var i = 0; i < draft.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
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
                            '${i + 1}',
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
                            controller: draft.options[i].text,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: AppStrings.optionHint(i + 1),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              suffixIcon: draft.options[i].fromStudents
                                  ? const Tooltip(
                                      message: AppStrings.fromStudents,
                                      child: Icon(Icons.groups_outlined, size: 16, color: Brand.muted),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (draft.options.length > 1) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              draft.options.removeAt(i).dispose();
                              onChanged();
                            },
                            tooltip: AppStrings.removeOption,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            icon: const Icon(Icons.close, size: 16, color: Brand.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestQuestionDraft {
  _InterestQuestionDraft({
    this.id,
    String questionText = '',
    this.allowOther = true,
    this.maxSelections = 5,
    List<_InterestOptionDraft>? options,
  }) : question = TextEditingController(text: questionText),
       options = options ??
           [
             _InterestOptionDraft(),
             _InterestOptionDraft(),
           ];

  factory _InterestQuestionDraft.fromDto(InterestQuestionDto dto) {
    return _InterestQuestionDraft(
      id: dto.id,
      questionText: dto.questionText,
      allowOther: dto.allowOther,
      maxSelections: dto.maxSelections.clamp(1, 5),
      options: dto.options
          .where((option) => option.isActive)
          .map(_InterestOptionDraft.fromDto)
          .toList(),
    );
  }

  final String? id;
  final TextEditingController question;
  bool allowOther;
  int maxSelections;
  final List<_InterestOptionDraft> options;

  void dispose() {
    question.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _InterestOptionDraft {
  _InterestOptionDraft({
    this.id,
    String text = '',
    this.fromStudents = false,
  }) : text = TextEditingController(text: text);

  factory _InterestOptionDraft.fromDto(InterestOptionDto dto) {
    return _InterestOptionDraft(
      id: dto.id,
      text: dto.optionText,
      fromStudents: dto.isFromStudents,
    );
  }

  final String? id;
  final TextEditingController text;
  final bool fromStudents;

  void dispose() => text.dispose();
}

class AdminParentQuestionsPanel extends ConsumerStatefulWidget {
  const AdminParentQuestionsPanel({super.key});

  @override
  ConsumerState<AdminParentQuestionsPanel> createState() =>
      _AdminParentQuestionsPanelState();
}

class _AdminParentQuestionsPanelState
    extends ConsumerState<AdminParentQuestionsPanel> {
  final _drafts = <_ParentQuestionDraft>[];
  var _bound = false;
  var _saving = false;

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _load(List<ParentQuestionDto> questions) {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _drafts
      ..clear()
      ..addAll(questions.map(_ParentQuestionDraft.fromDto));
    if (_drafts.isEmpty) {
      _drafts.add(_ParentQuestionDraft());
    }
    _bound = true;
  }

  Future<void> _save() async {
    if (_saving) return;
    final payload = <Map<String, dynamic>>[];
    for (final draft in _drafts) {
      final text = draft.question.text.trim();
      if (text.isEmpty) {
        showFailure(context, AppStrings.addAtLeastOneQuestion);
        return;
      }
      final options = draft.isOptions
          ? draft.options
                .map((option) => option.text.text.trim())
                .where((value) => value.isNotEmpty)
                .toList()
          : <String>[];
      if (draft.isOptions && options.isEmpty) {
        showFailure(context, AppStrings.addAtLeastOneQuestion);
        return;
      }
      payload.add({
        if (draft.id != null && draft.id!.isNotEmpty) 'id': draft.id,
        'question_text': text,
        'question_type': draft.questionType,
        'is_active': true,
        'options': [
          for (var i = 0; i < draft.options.length; i++)
            if (draft.options[i].text.text.trim().isNotEmpty)
              {
                if (draft.options[i].id != null &&
                    draft.options[i].id!.isNotEmpty)
                  'id': draft.options[i].id,
                'option_text': draft.options[i].text.text.trim(),
                'is_active': true,
              },
        ],
      });
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .upsertParentQuestions(payload);
      ref.invalidate(adminParentQuestionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsSaved)),
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminParentQuestionsProvider);
    final isMobile = Breakpoints.isMobile(context);

    return AsyncBody(
      value: async,
      onRetry: () => ref.invalidate(adminParentQuestionsProvider),
      builder: (questions) {
        if (!_bound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _load(questions));
          });
        }
        return ListView(
          padding: EdgeInsets.only(
            top: 4,
            bottom: isMobile ? 80 : 48,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppStrings.parentQuestions,
                            style: TextStyle(
                              color: Brand.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 15 : 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Brand.navy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_drafts.length}',
                              style: const TextStyle(
                                color: Brand.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        AppStrings.parentQuestionsHelp,
                        style: TextStyle(color: Brand.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(_saving ? AppStrings.saving : AppStrings.save),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _drafts.length; i++)
              _ParentQuestionCard(
                index: i,
                draft: _drafts[i],
                onRemove: _drafts.length <= 1
                    ? null
                    : () => setState(() {
                        final removed = _drafts.removeAt(i);
                        removed.dispose();
                      }),
                onChanged: () => setState(() {}),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _drafts.add(_ParentQuestionDraft())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(AppStrings.addQuestion),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Brand.navy,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_saving ? AppStrings.saving : AppStrings.save),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ParentQuestionCard extends StatelessWidget {
  const _ParentQuestionCard({
    required this.index,
    required this.draft,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _ParentQuestionDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Card(
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
                const Text(
                  AppStrings.parentQuestionLabel,
                  style: TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const Spacer(),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: draft.questionType,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Brand.navy,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'text',
                          child: Text(AppStrings.textResponse),
                        ),
                        DropdownMenuItem(
                          value: 'options',
                          child: Text(AppStrings.multipleChoice),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        draft.questionType = value;
                        onChanged();
                      },
                    ),
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onRemove,
                    tooltip: AppStrings.removeQuestion,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB42318)),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: draft.question,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Brand.navy,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.questions,
                    hintText: AppStrings.enterQuestionPrompt,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
                if (draft.isOptions) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        AppStrings.optionsCountLabel(draft.options.length),
                        style: const TextStyle(
                          color: Brand.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          draft.options.add(_ParentOptionDraft());
                          onChanged();
                        },
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
                  for (var i = 0; i < draft.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
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
                              '${i + 1}',
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
                              controller: draft.options[i].text,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: AppStrings.optionHint(i + 1),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                          if (draft.options.length > 1) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                draft.options.removeAt(i).dispose();
                                onChanged();
                              },
                              tooltip: AppStrings.removeOption,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              icon: const Icon(Icons.close, size: 16, color: Brand.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentQuestionDraft {
  _ParentQuestionDraft({
    this.id,
    String questionText = '',
    this.questionType = 'text',
    List<_ParentOptionDraft>? options,
  }) : question = TextEditingController(text: questionText),
       options = options ?? [_ParentOptionDraft(), _ParentOptionDraft()];

  factory _ParentQuestionDraft.fromDto(ParentQuestionDto dto) {
    return _ParentQuestionDraft(
      id: dto.id,
      questionText: dto.questionText,
      questionType: dto.questionType,
      options: dto.options
          .where((option) => option.isActive)
          .map(_ParentOptionDraft.fromDto)
          .toList(),
    );
  }

  final String? id;
  final TextEditingController question;
  String questionType;
  final List<_ParentOptionDraft> options;

  bool get isOptions => questionType == 'options';

  void dispose() {
    question.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _ParentOptionDraft {
  _ParentOptionDraft({this.id, String text = ''})
    : text = TextEditingController(text: text);

  factory _ParentOptionDraft.fromDto(ParentOptionDto dto) {
    return _ParentOptionDraft(id: dto.id, text: dto.optionText);
  }

  final String? id;
  final TextEditingController text;

  void dispose() => text.dispose();
}
