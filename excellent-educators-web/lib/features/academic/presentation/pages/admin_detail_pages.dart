import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/admin_student_feedback_section.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/master_teacher_progress_panel.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/teacher_availability_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminStudentDetailPage extends ConsumerStatefulWidget {
  const AdminStudentDetailPage({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<AdminStudentDetailPage> createState() => _AdminStudentDetailPageState();
}

class _AdminStudentDetailPageState extends ConsumerState<AdminStudentDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  String? _status;
  int? _classGrade;
  String? _boundStudentId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    super.dispose();
  }

  void _bind(StudentDto student) {
    if (_boundStudentId == student.id) {
      return;
    }
    _boundStudentId = student.id;
    _name.text = student.fullName;
    _phone.text = student.phone;
    _whatsapp.text = student.whatsappNumber ?? '';
    _address.text = student.address ?? '';
    _guardianName.text = student.guardianName ?? '';
    _guardianPhone.text = student.guardianPhone ?? '';
    _status = student.status;
    _classGrade = student.classGrade;
  }

  void _scheduleBind(StudentDto student) {
    if (_boundStudentId == student.id) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _boundStudentId == student.id) {
        return;
      }
      setState(() => _bind(student));
    });
  }

  Future<void> _save(StudentDto student) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).updateStudent(widget.studentId, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp_number': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'guardian_name': _guardianName.text.trim().isEmpty ? null : _guardianName.text.trim(),
        'guardian_phone': _guardianPhone.text.trim().isEmpty ? null : _guardianPhone.text.trim(),
        'status': _status,
        if (_classGrade != null) 'class_grade': _classGrade,
      });
      ref.invalidate(adminStudentProvider(widget.studentId));
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated.')));
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
    final studentValue = ref.watch(adminStudentProvider(widget.studentId));

    return AppScaffold(
      title: 'Student',
      backTo: RoutePaths.adminStudents,
      body: AsyncBody(
        value: studentValue,
        onRetry: () => ref.invalidate(adminStudentProvider(widget.studentId)),
        builder: (student) {
          _scheduleBind(student);
          final compass = student.careerCompassLevel;
          final classOptions = compass == null
              ? <int>[]
              : [for (var g = compass.classFrom; g <= compass.classTo; g++) g];

          return ListView(
            children: [
              StudentCard(student: student),
              const SizedBox(height: 12),
              _StudentAdminWorkflow(
                student: student,
                onReviewResults: student.hasSubmittedAptitudeAssessment
                    ? () => context.go(RoutePaths.adminStudentResultsFor(student.id))
                    : null,
                onOpenBatch: student.batch != null && !student.batch!.isEmpty
                    ? () => context.go(RoutePaths.adminBatch(student.batch!.id))
                    : null,
              ),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Aptitude assessment',
                children: [
                  if (student.hasSubmittedAptitudeAssessment) ...[
                    DetailRow(
                      label: 'Status',
                      value: 'Submitted',
                    ),
                    if (student.aptitudeAssessmentTitle != null && student.aptitudeAssessmentTitle!.isNotEmpty)
                      DetailRow(label: 'Assessment', value: student.aptitudeAssessmentTitle!),
                    if (student.aptitudeAssessmentSubmittedAt != null)
                      DetailRow(
                        label: 'Submitted on',
                        value: formatDisplayDateTime(student.aptitudeAssessmentSubmittedAt),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go(RoutePaths.adminStudentJournalFor(student.id)),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Learning journal'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go(RoutePaths.adminStudentResultsFor(student.id)),
                      icon: const Icon(Icons.insights),
                      label: const Text('View aptitude results'),
                    ),
                  ] else ...[
                    const DetailRow(label: 'Status', value: 'Not submitted yet'),
                    const SizedBox(height: 8),
                    Text(
                      'The student will see the assessment on their dashboard once it is active for their Career Compass level.',
                      style: TextStyle(color: Brand.muted.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              AdminStudentFeedbackSection(student: student),
              const SizedBox(height: 12),
              _PromoteStudentCard(studentId: student.id, currentLevelId: student.level?.id),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Profile details',
                children: [
                  DetailRow(label: 'Student ID', value: student.studentCode),
                  DetailRow(label: 'Email', value: student.email),
                  if (student.phone.isNotEmpty) DetailRow(label: 'Phone', value: student.phone),
                  if (student.whatsappNumber != null && student.whatsappNumber!.isNotEmpty)
                    DetailRow(label: 'WhatsApp', value: student.whatsappNumber!),
                  if (student.createdAt != null)
                    DetailRow(label: 'Registered', value: formatDisplayDateTime(student.createdAt)),
                  if (compass != null)
                    DetailRow(
                      label: 'Career Compass',
                      value: '${compass.name} · Classes ${compass.classFrom}–${compass.classTo}',
                    ),
                  if (student.batch != null && !student.batch!.isEmpty)
                    DetailRow(label: 'Batch', value: student.batch!.label),
                ],
              ),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Edit student',
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone', prefixText: '+91  '),
                          validator: validateRequiredPhone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _whatsapp,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp number (optional)',
                            prefixText: '+91  ',
                          ),
                          validator: validateOptionalPhone,
                        ),
                        const SizedBox(height: 12),
                        if (classOptions.isNotEmpty)
                          DropdownButtonFormField<int>(
                            key: ValueKey(_classGrade),
                            initialValue: _classGrade,
                            decoration: const InputDecoration(labelText: 'Class'),
                            items: [
                              for (final grade in classOptions)
                                DropdownMenuItem(value: grade, child: Text('Class $grade')),
                            ],
                            onChanged: (value) => setState(() => _classGrade = value),
                          ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_status),
                          initialValue: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          ],
                          onChanged: (value) => setState(() => _status = value),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _address,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Address', alignLabelWithHint: true),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _guardianName,
                          decoration: const InputDecoration(labelText: 'Guardian name'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _guardianPhone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Guardian phone'),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : () => _save(student),
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save changes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }
}

class _StudentAdminWorkflow extends StatelessWidget {
  const _StudentAdminWorkflow({
    required this.student,
    this.onReviewResults,
    this.onOpenBatch,
  });

  final StudentDto student;
  final VoidCallback? onReviewResults;
  final VoidCallback? onOpenBatch;

  bool get _inBatch => student.batch != null && !student.batch!.isEmpty;

  @override
  Widget build(BuildContext context) {
    final steps = <_WorkflowStep>[
      _WorkflowStep(
        number: 1,
        title: 'Create student login',
        subtitle: '${student.email} · ID ${student.studentCode}',
        state: _WorkflowStepState.done,
      ),
      _WorkflowStep(
        number: 2,
        title: 'Student completes aptitude test',
        subtitle: student.hasSubmittedAptitudeAssessment
            ? 'Submitted ${student.aptitudeAssessmentSubmittedAt != null ? formatDisplayDateTime(student.aptitudeAssessmentSubmittedAt) : ''}'
            : 'Waiting for student to log in and submit',
        state: student.hasSubmittedAptitudeAssessment ? _WorkflowStepState.done : _WorkflowStepState.waiting,
      ),
      _WorkflowStep(
        number: 3,
        title: 'Admin reviews results',
        subtitle: student.hasSubmittedAptitudeAssessment
            ? 'Review dimension scores before assigning teachers'
            : 'Available after the student submits',
        state: student.hasSubmittedAptitudeAssessment ? _WorkflowStepState.action : _WorkflowStepState.locked,
        actionLabel: 'Review results',
        onAction: onReviewResults,
      ),
      _WorkflowStep(
        number: 4,
        title: 'Enroll in level & batch',
        subtitle: _inBatch
            ? student.batch!.label
            : 'Add student to a level (Levels → Enroll student)',
        state: _inBatch ? _WorkflowStepState.done : _WorkflowStepState.action,
        actionLabel: _inBatch ? 'Open level' : 'Go to levels',
        onAction: _inBatch ? onOpenBatch : () => context.go(RoutePaths.adminBatches),
      ),
    ];

    return DetailSection(
      title: 'Admin workflow',
      children: [
        Text(
          'Follow these steps in order: create login → student submits → you review → enroll in level & batch.',
          style: TextStyle(color: Brand.muted.withValues(alpha: 0.95), fontSize: 13),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++) ...[
          _WorkflowStepTile(step: steps[i]),
          if (i < steps.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

enum _WorkflowStepState { done, waiting, action, locked }

class _WorkflowStep {
  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.state,
    this.actionLabel,
    this.onAction,
  });

  final int number;
  final String title;
  final String subtitle;
  final _WorkflowStepState state;
  final String? actionLabel;
  final VoidCallback? onAction;
}

class _WorkflowStepTile extends StatelessWidget {
  const _WorkflowStepTile({required this.step});

  final _WorkflowStep step;

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, bgColor) = switch (step.state) {
      _WorkflowStepState.done => (Icons.check_circle, const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      _WorkflowStepState.waiting => (Icons.hourglass_top, const Color(0xFFF57F17), const Color(0xFFFFF8E1)),
      _WorkflowStepState.action => (Icons.radio_button_checked, Brand.goldDark, const Color(0xFFFBF6EA)),
      _WorkflowStepState.locked => (Icons.lock_outline, Brand.muted, const Color(0xFFF5F5F5)),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6DCCB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.number}. ${step.title}',
                  style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(step.subtitle, style: const TextStyle(color: Brand.muted, fontSize: 12)),
                if (step.state == _WorkflowStepState.action &&
                    step.actionLabel != null &&
                    step.onAction != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonal(
                      onPressed: step.onAction,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(step.actionLabel!),
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

class AdminTeacherDetailPage extends ConsumerWidget {
  const AdminTeacherDetailPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherValue = ref.watch(adminTeacherProvider(teacherId));

    return AppScaffold(
      title: 'Teacher',
      backTo: RoutePaths.adminTeachers,
      body: AsyncBody(
        value: teacherValue,
        onRetry: () => ref.invalidate(adminTeacherProvider(teacherId)),
        builder: (teacher) {
          return ListView(
            children: [
              TeacherCard(
                teacher: teacher,
                trailing: IconButton(
                  tooltip: 'Edit teacher',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.go(RoutePaths.adminTeacherEditFor(teacherId)),
                ),
              ),
              const SizedBox(height: 10),
              TeacherAvailabilitySummary(teacherId: teacherId),
              if (teacher.isMasterTeacher) ...[
                const SizedBox(height: 12),
                _AdminTeacherProgressSection(teacherId: teacherId),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PromoteStudentCard extends ConsumerStatefulWidget {
  const _PromoteStudentCard({required this.studentId, this.currentLevelId});

  final String studentId;
  final String? currentLevelId;

  @override
  ConsumerState<_PromoteStudentCard> createState() => _PromoteStudentCardState();
}

class _PromoteStudentCardState extends ConsumerState<_PromoteStudentCard> {
  String? _levelId;
  var _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(adminLevelsProvider);
    return DetailSection(
      title: 'Promote student',
      children: [
        AsyncBody(
          value: levels,
          onRetry: () => ref.invalidate(adminLevelsProvider),
          builder: (items) {
            final options = items.where((level) => level.id != widget.currentLevelId).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('The new level starts from its own Week 1. Previous level history stays in the journal.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _levelId,
                  decoration: const InputDecoration(labelText: 'New level'),
                  items: [
                    for (final level in options)
                      DropdownMenuItem(value: level.id, child: Text(level.name)),
                  ],
                  onChanged: (value) => setState(() => _levelId = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving || _levelId == null
                      ? null
                      : () async {
                          setState(() {
                            _saving = true;
                            _error = null;
                          });
                          try {
                            await ref.read(learningRepositoryProvider).promoteStudent(
                                  studentId: widget.studentId,
                                  levelId: _levelId!,
                                );
                            ref.invalidate(adminStudentProvider(widget.studentId));
                          } catch (error) {
                            setState(() => _error = error.toString());
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: Text(_saving ? 'Promoting…' : 'Promote'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdminTeacherProgressSection extends ConsumerWidget {
  const _AdminTeacherProgressSection({required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(adminTeacherDashboardProvider(teacherId));

    return AsyncBody(
      value: progress,
      onRetry: () => ref.invalidate(adminTeacherDashboardProvider(teacherId)),
      builder: (data) {
        return MasterTeacherProgressPanel(
          data: data,
          showPendingStudents: true,
          onPendingStudentTap: (student) => context.go(RoutePaths.adminStudent(student.id)),
          onRateStudent: (student) => context.go(RoutePaths.adminFeedbackNewFor(student.id)),
          onEditStudentRating: (student) {
            final id = student.monthlyFeedbackId;
            if (id == null || id.isEmpty) {
              return;
            }
            context.go(RoutePaths.adminFeedbackEditFor(student.id, id));
          },
        );
      },
    );
  }
}
