import 'dart:async';

import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/empty_state.dart';
import 'package:excellent_educators_web/features/academic/data/academic_repository.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:excellent_educators_web/core/widgets/empty_state.dart' show EmptyIcons, EmptyState;

class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error.toString()),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(
    this.message, {
    super.key,
    this.icon,
    this.subtitle,
    this.action,
    this.fillHeight = true,
  });

  final String message;
  final IconData? icon;
  final String? subtitle;
  final Widget? action;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: message,
      subtitle: subtitle,
      icon: icon ?? EmptyIcons.list,
      action: action,
      fillHeight: fillHeight,
    );
  }
}

Future<T?> pickOption<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) label,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      return AppModalDialog(
        title: title,
        maxWidth: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (options.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No options available.', style: TextStyle(color: Brand.muted)),
              )
            else
              for (final option in options)
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => Navigator.of(context).pop(option),
                  title: Text(label(option)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Brand.muted),
                ),
          ],
        ),
      );
    },
  );
}

Future<TeacherDto?> pickTeacher({
  required BuildContext context,
  required AcademicRepository repo,
  required String title,
  String? role,
  String? highlightLevelId,
  String? excludeLevelId,
  Set<String>? excludeTeacherIds,
  String? emptyMessage,
}) {
  return showDialog<TeacherDto>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (context) {
      return _TeacherSearchDialog(
        title: title,
        repo: repo,
        role: role,
        highlightLevelId: highlightLevelId,
        excludeLevelId: excludeLevelId,
        excludeTeacherIds: excludeTeacherIds,
        emptyMessage: emptyMessage,
      );
    },
  );
}

Future<StudentDto?> pickStudent({
  required BuildContext context,
  required AcademicRepository repo,
  required String title,
  String? careerCompassLevelId,
  bool withoutBatch = false,
  String? emptyMessage,
}) {
  return showDialog<StudentDto>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (context) {
      return _StudentSearchDialog(
        title: title,
        repo: repo,
        careerCompassLevelId: careerCompassLevelId,
        withoutBatch: withoutBatch,
        emptyMessage: emptyMessage,
      );
    },
  );
}

class _TeacherSearchDialog extends StatefulWidget {
  const _TeacherSearchDialog({
    required this.title,
    required this.repo,
    this.role,
    this.highlightLevelId,
    this.excludeLevelId,
    this.excludeTeacherIds,
    this.emptyMessage,
  });

  final String title;
  final AcademicRepository repo;
  final String? role;
  final String? highlightLevelId;
  final String? excludeLevelId;
  final Set<String>? excludeTeacherIds;
  final String? emptyMessage;

  @override
  State<_TeacherSearchDialog> createState() => _TeacherSearchDialogState();
}

class _TeacherSearchDialogState extends State<_TeacherSearchDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  var _loading = true;
  var _error = false;
  var _page = 1;
  var _total = 0;
  List<TeacherDto> _items = [];

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await widget.repo.adminTeachers(
        search: _search.text.trim(),
        status: 'active',
        role: widget.role,
        excludeLevelId: widget.excludeLevelId,
        page: page,
      );
      if (!mounted) {
        return;
      }
      final parsed = widget.repo.parseTeachers(result);
      final filtered = widget.excludeTeacherIds != null && widget.excludeTeacherIds!.isNotEmpty
          ? parsed.where((t) => !widget.excludeTeacherIds!.contains(t.id)).toList()
          : parsed;
      setState(() {
        _page = page;
        _total = widget.excludeTeacherIds != null && widget.excludeTeacherIds!.isNotEmpty
            ? filtered.length
            : result.total;
        _items = filtered;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(page: 1));
  }

  int get _lastPage => _total == 0 ? 1 : (_total / 25).ceil();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search name, phone, or email',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Could not load teachers.'),
                              const SizedBox(height: 8),
                              FilledButton(onPressed: () => _load(page: _page), child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                widget.emptyMessage ?? 'No teachers match your search.',
                                style: const TextStyle(color: Brand.muted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final teacher = _items[index];
                                final teachesLevel = widget.highlightLevelId != null &&
                                    teacher.careerCompassLevels.any((level) => level.id == widget.highlightLevelId);
                                return _PickerTeacherTile(
                                  teacher: teacher,
                                  highlighted: teachesLevel,
                                  onTap: () => Navigator.of(context).pop(teacher),
                                );
                              },
                            ),
            ),
            if (!_loading && !_error && _total > 25)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Text(
                      '$_total total · page $_page of $_lastPage',
                      style: const TextStyle(color: Brand.muted, fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: _page < _lastPage ? () => _load(page: _page + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudentSearchDialog extends StatefulWidget {
  const _StudentSearchDialog({
    required this.title,
    required this.repo,
    this.careerCompassLevelId,
    this.withoutBatch = false,
    this.emptyMessage,
  });

  final String title;
  final AcademicRepository repo;
  final String? careerCompassLevelId;
  final bool withoutBatch;
  final String? emptyMessage;

  @override
  State<_StudentSearchDialog> createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<_StudentSearchDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  var _loading = true;
  var _error = false;
  var _page = 1;
  var _total = 0;
  List<StudentDto> _items = [];

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await widget.repo.adminStudents(
        search: _search.text.trim(),
        careerCompassLevelId: widget.careerCompassLevelId,
        status: 'active',
        withoutBatch: widget.withoutBatch,
        page: page,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _page = page;
        _total = result.total;
        _items = widget.repo.parseStudents(result);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(page: 1));
  }

  int get _lastPage => _total == 0 ? 1 : (_total / 25).ceil();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search name, Student ID, phone, or email',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Could not load students.'),
                              const SizedBox(height: 8),
                              FilledButton(onPressed: () => _load(page: _page), child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                widget.emptyMessage ?? 'No students match your search.',
                                style: const TextStyle(color: Brand.muted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final student = _items[index];
                                return _PickerStudentTile(
                                  student: student,
                                  onTap: () => Navigator.of(context).pop(student),
                                );
                              },
                            ),
            ),
            if (!_loading && !_error && _total > 25)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Text(
                      '$_total total · page $_page of $_lastPage',
                      style: const TextStyle(color: Brand.muted, fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: _page < _lastPage ? () => _load(page: _page + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerTeacherTile extends StatelessWidget {
  const _PickerTeacherTile({
    required this.teacher,
    required this.onTap,
    this.highlighted = false,
  });

  final TeacherDto teacher;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFFE8F5E9) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: highlighted ? const Color(0xFF81C784) : const Color(0xFFE6DCCB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Brand.navy,
                child: Text(
                  _initials(teacher.fullName),
                  style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher.email.isEmpty ? 'No email on file' : teacher.email,
                      style: const TextStyle(color: Brand.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.layers_outlined, size: 14, color: Brand.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            teacher.levelsLabel,
                            style: const TextStyle(color: Brand.navy, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (highlighted) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Already teaches this level',
                        style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerStudentTile extends StatelessWidget {
  const _PickerStudentTile({required this.student, required this.onTap});

  final StudentDto student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = student.careerCompassLevel;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6DCCB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Brand.navy,
                child: Text(
                  _initials(student.fullName),
                  style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.email.isEmpty ? 'No email on file' : student.email,
                      style: const TextStyle(color: Brand.muted, fontSize: 13),
                    ),
                    if (student.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(student.phone, style: const TextStyle(color: Brand.muted, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (level != null)
                          _PickerChip(label: level.displayName, tone: _PickerChipTone.level)
                        else
                          const _PickerChip(label: 'No Career Compass level', tone: _PickerChipTone.muted),
                        _PickerChip(label: student.studentCode, tone: _PickerChipTone.muted),
                        if (student.classGrade > 0)
                          _PickerChip(label: 'Class ${student.classGrade}', tone: _PickerChipTone.muted),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PickerChipTone { commonTeacher, masterTeacher, level, muted }

class _PickerChip extends StatelessWidget {
  const _PickerChip({required this.label, required this.tone});

  final String label;
  final _PickerChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, border, text) = switch (tone) {
      _PickerChipTone.commonTeacher => (const Color(0xFFFBF6EA), Brand.gold, Brand.goldDark),
      _PickerChipTone.masterTeacher => (const Color(0xFFE8EAF6), const Color(0xFF7986CB), const Color(0xFF3949AB)),
      _PickerChipTone.level => (const Color(0xFFE3F2FD), const Color(0xFF90CAF9), const Color(0xFF1565C0)),
      _PickerChipTone.muted => (const Color(0xFFF5F5F5), const Color(0xFFE0E0E0), Brand.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first[0].toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String? validateRequiredPhone(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 10) {
    return 'Enter a valid 10-digit phone number.';
  }
  return null;
}

String? validateOptionalPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return validateRequiredPhone(value);
}

class AppFormPage extends StatelessWidget {
  const AppFormPage({
    super.key,
    required this.title,
    required this.child,
    this.backTo,
  });

  final String title;
  final Widget child;
  final String? backTo;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      backTo: backTo,
      body: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: child,
        ),
      ),
    );
  }
}
