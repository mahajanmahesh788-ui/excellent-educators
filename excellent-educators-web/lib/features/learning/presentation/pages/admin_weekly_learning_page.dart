import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/assessments/domain/dimension_catalog.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminWeeklyLearningPage extends ConsumerStatefulWidget {
  const AdminWeeklyLearningPage({super.key, required this.levelId});

  final String levelId;

  @override
  ConsumerState<AdminWeeklyLearningPage> createState() =>
      _AdminWeeklyLearningPageState();
}

class _AdminWeeklyLearningPageState
    extends ConsumerState<AdminWeeklyLearningPage> {
  var _week = 1;
  final _video = TextEditingController();
  final _questions = <_QuestionDraft>[];
  var _boundLevelId = '';
  var _saving = false;

  @override
  void dispose() {
    _video.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _loadWeek(List<WeeklyLearningContentDto> content) {
    final unit = content.where((item) => item.weekNumber == _week).firstOrNull;
    _video.text = unit?.videoUrl ?? '';
    for (final question in _questions) {
      question.dispose();
    }
    _questions
      ..clear()
      ..addAll(
        unit == null || unit.questions.isEmpty
            ? [_QuestionDraft()]
            : unit.questions.map(_QuestionDraft.fromDto),
      );
  }

  Future<void> _save() async {
    if (_video.text.trim().isEmpty) {
      showFailure(context, AppStrings.enterAVideoLinkForThisWeek);
      return;
    }
    for (final question in _questions) {
      if (question.text.text.trim().isEmpty) {
        showFailure(context, AppStrings.everyQuestionNeedsText);
        return;
      }
      if (question.isText) {
        continue;
      }
      if (question.options.length < 2) {
        showFailure(context, AppStrings.eachQuestionNeedsAtLeastTwoOptions);
        return;
      }
      if (question.options.any((option) => option.text.text.trim().isEmpty)) {
        showFailure(context, AppStrings.everyOptionNeedsText);
        return;
      }
      if (question.options.any(
        (option) => !DimensionCatalog.areValid(option.dimensionCodes),
      )) {
        showFailure(
          context,
          'Each option needs 1 to ${DimensionCatalog.maxCodesPerOption} unique dimension codes.',
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(learningRepositoryProvider)
          .upsertWeeklyLearning(
            levelId: widget.levelId,
            weekNumber: _week,
            videoUrl: _video.text.trim(),
            questions: [
              for (final question in _questions)
                {
                  'question_text': question.text.text.trim(),
                  'question_type': question.questionType,
                  'options': question.isText
                      ? <Map<String, dynamic>>[]
                      : [
                          for (final option in question.options)
                            {
                              'option_text': option.text.text.trim(),
                              'dimension_codes': option.dimensionCodes,
                            },
                        ],
                },
            ],
          );
      ref.invalidate(adminWeeklyLearningsProvider(widget.levelId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Week $_week saved.')));
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(adminLevelProvider(widget.levelId));
    final units = ref.watch(adminWeeklyLearningsProvider(widget.levelId));

    return AppScaffold(
      title: AppStrings.learningJourney2,
      backTo: RoutePaths.adminBatch(widget.levelId),
      body: AsyncBody(
        value: level,
        onRetry: () => ref.invalidate(adminLevelProvider(widget.levelId)),
        builder: (levelData) {
          return AsyncBody(
            value: units,
            onRetry: () =>
                ref.invalidate(adminWeeklyLearningsProvider(widget.levelId)),
            builder: (content) {
              if (_boundLevelId != widget.levelId) {
                _boundLevelId = widget.levelId;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _loadWeek(content));
                });
              }
              final savedWeeks = content.map((item) => item.weekNumber).toSet();
              return ListView(
                padding: const EdgeInsets.only(bottom: 48),
                children: [
                  Text(
                    '${levelData.name} · Week $_week',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Brand.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WeekStrip(
                    selected: _week,
                    savedWeeks: savedWeeks,
                    onSelect: (week) => setState(() {
                      _week = week;
                      _loadWeek(content);
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _video,
                    decoration: const InputDecoration(
                      labelText: AppStrings.videoLink,
                      hintText: 'https://',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        AppStrings.questions,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _questions.add(_QuestionDraft())),
                        icon: const Icon(Icons.add),
                        label: const Text(AppStrings.addQuestion),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var index = 0; index < _questions.length; index++)
                    _questionEditor(index),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Save week $_week'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _questionEditor(int index) {
    final question = _questions[index];
    return Card(
      key: ValueKey('question-$index-${question.text.hashCode}'),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                      labelText: AppStrings.question,
                      labelStyle: TextStyle(
                        color: Brand.navy.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Brand.navy.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Brand.gold,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _questions.length == 1
                      ? null
                      : () => setState(() {
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
                  AppStrings.answerType,
                  style: TextStyle(
                    color: Brand.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'options',
                      label: Text(AppStrings.answerTypeOptions),
                      icon: Icon(Icons.list_alt_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 'text',
                      label: Text(AppStrings.answerTypeTextField),
                      icon: Icon(Icons.short_text_rounded, size: 16),
                    ),
                  ],
                  selected: {question.questionType},
                  onSelectionChanged: (selected) {
                    setState(() {
                      question.questionType = selected.first;
                      if (question.isOptions && question.options.length < 2) {
                        while (question.options.length < 2) {
                          question.options.add(_OptionDraft());
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (question.isText)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8E0D4)),
                    ),
                    child: const Text(
                      AppStrings.textFieldQuestionHint,
                      style: TextStyle(
                        color: Brand.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  )
                else ...[
                  const Text(
                    AppStrings.answerOptions,
                    style: TextStyle(
                      color: Brand.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (
                    var optionIndex = 0;
                    optionIndex < question.options.length;
                    optionIndex++
                  )
                    _optionEditor(question, optionIndex),
                  TextButton(
                    onPressed: () =>
                        setState(() => question.options.add(_OptionDraft())),
                    child: const Text(AppStrings.addOption),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionEditor(_QuestionDraft question, int index) {
    final option = question.options[index];
    final codeLabel = option.dimensionCodes.isEmpty
        ? 'Codes'
        : option.dimensionCodes.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE8E0D4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Brand.gold.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _pickDimensionCodes(option),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(62, 40),
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
            onPressed: question.options.length <= 2
                ? null
                : () => setState(() {
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
                            if (selected.length >=
                                DimensionCatalog.maxCodesPerOption) {
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
                            setState(
                              () => option.dimensionCodes = List<String>.from(
                                selected,
                              ),
                            );
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

class _WeekStrip extends StatefulWidget {
  const _WeekStrip({
    required this.selected,
    required this.savedWeeks,
    required this.onSelect,
  });

  final int selected;
  final Set<int> savedWeeks;
  final ValueChanged<int> onSelect;

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
  }

  @override
  void didUpdateWidget(covariant _WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpToSelected() {
    if (!_controller.hasClients) return;
    final offset = ((widget.selected - 1) * 42.0) - 80;
    _controller.animateTo(
      offset.clamp(0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: AppStrings.previousWeek,
          visualDensity: VisualDensity.compact,
          onPressed: widget.selected > 1
              ? () => widget.onSelect(widget.selected - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemCount: 52,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final week = index + 1;
                final isSelected = week == widget.selected;
                final saved = widget.savedWeeks.contains(week);
                return InkWell(
                  onTap: () => widget.onSelect(week),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Brand.navy : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Brand.navy
                            : saved
                            ? Brand.gold
                            : const Color(0xFFD7CDBB),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$week',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : Brand.navy,
                          ),
                        ),
                        if (saved)
                          const Positioned(
                            top: 2,
                            right: 2,
                            child: Icon(
                              Icons.check,
                              size: 9,
                              color: Brand.gold,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        IconButton(
          tooltip: AppStrings.nextWeek,
          visualDensity: VisualDensity.compact,
          onPressed: widget.selected < 52
              ? () => widget.onSelect(widget.selected + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _QuestionDraft {
  _QuestionDraft()
    : text = TextEditingController(),
      questionType = 'options',
      options = [_OptionDraft(), _OptionDraft()];

  _QuestionDraft.fromDto(LearningQuestionDto dto)
    : text = TextEditingController(text: dto.questionText),
      questionType = dto.isText ? 'text' : 'options',
      options = dto.isText
          ? [_OptionDraft(), _OptionDraft()]
          : (dto.options.isEmpty
                ? [_OptionDraft(), _OptionDraft()]
                : dto.options.map(_OptionDraft.fromDto).toList());

  final TextEditingController text;
  String questionType;
  final List<_OptionDraft> options;

  bool get isText => questionType == 'text';
  bool get isOptions => !isText;

  void dispose() {
    text.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _OptionDraft {
  _OptionDraft()
    : text = TextEditingController(),
      dimensionCodes = [AppStrings.tw];

  _OptionDraft.fromDto(LearningOptionDto dto)
    : text = TextEditingController(text: dto.optionText),
      dimensionCodes = dto.dimensionCodes.isEmpty
          ? [AppStrings.tw]
          : List<String>.from(dto.dimensionCodes);

  final TextEditingController text;
  List<String> dimensionCodes;

  void dispose() => text.dispose();
}
