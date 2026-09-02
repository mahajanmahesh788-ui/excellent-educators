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
                onAssignMasterTeacher: () => _assignMentor(context, student),
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

  Future<void> _assignMentor(BuildContext context, StudentDto student) async {
    final repo = ref.read(academicRepositoryProvider);
    try {
      final selected = await pickTeacher(
        context: context,
        repo: repo,
        title: 'Assign Master Teacher',
        role: 'master_teacher',
        emptyMessage: 'No Master Teachers found. Add a teacher with the Master Teacher role first.',
      );
      if (selected == null) {
        return;
      }
      await repo.assignMasterTeacher(studentId: student.id, teacherId: selected.id);
      ref.invalidate(adminStudentProvider(widget.studentId));
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
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
    required this.onAssignMasterTeacher,
    this.onOpenBatch,
  });

  final StudentDto student;
  final VoidCallback? onReviewResults;
  final VoidCallback onAssignMasterTeacher;
  final VoidCallback? onOpenBatch;

  bool get _inBatch => student.batch != null && !student.batch!.isEmpty;
  bool get _hasCommonTeacher => student.commonTeacher != null && !student.commonTeacher!.isEmpty;
  bool get _hasMasterTeacher => student.masterTeacher != null && !student.masterTeacher!.isEmpty;

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
        title: 'Enroll in batch',
        subtitle: _inBatch
            ? student.batch!.label
            : 'Add student to a batch (Batches → Enroll student)',
        state: _inBatch ? _WorkflowStepState.done : _WorkflowStepState.action,
        actionLabel: _inBatch ? 'Open batch' : 'Go to batches',
        onAction: _inBatch ? onOpenBatch : () => context.go(RoutePaths.adminBatches),
      ),
      _WorkflowStep(
        number: 5,
        title: 'Assign Common Teacher',
        subtitle: _hasCommonTeacher
            ? student.commonTeacher!.label
            : _inBatch
                ? 'Open the batch and assign a Common Teacher'
                : 'Complete batch enrollment first',
        state: _hasCommonTeacher
            ? _WorkflowStepState.done
            : _inBatch
                ? _WorkflowStepState.action
                : _WorkflowStepState.locked,
        actionLabel: 'Assign on batch',
        onAction: _inBatch ? onOpenBatch : null,
      ),
      _WorkflowStep(
        number: 6,
        title: 'Assign Master Teacher',
        subtitle: _hasMasterTeacher
            ? student.masterTeacher!.label
            : student.hasSubmittedAptitudeAssessment
                ? 'One mentor per student for feedback and guidance'
                : 'Review assessment results first',
        state: _hasMasterTeacher
            ? _WorkflowStepState.done
            : student.hasSubmittedAptitudeAssessment
                ? _WorkflowStepState.action
                : _WorkflowStepState.locked,
        actionLabel: _hasMasterTeacher ? 'Change Master Teacher' : 'Assign Master Teacher',
        onAction: student.hasSubmittedAptitudeAssessment ? onAssignMasterTeacher : null,
      ),
    ];

    return DetailSection(
      title: 'Admin workflow',
      children: [
        Text(
          'Follow these steps in order: create login → student submits → you review → assign teachers.',
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

class AdminTeacherDetailPage extends ConsumerStatefulWidget {
  const AdminTeacherDetailPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  ConsumerState<AdminTeacherDetailPage> createState() => _AdminTeacherDetailPageState();
}

class _AdminTeacherDetailPageState extends ConsumerState<AdminTeacherDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _employeeCode = TextEditingController();
  final _roles = <String>{};
  String? _status;
  String? _boundTeacherId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _employeeCode.dispose();
    super.dispose();
  }

  void _bind(TeacherDto teacher) {
    if (_boundTeacherId == teacher.id) {
      return;
    }
    _boundTeacherId = teacher.id;
    _name.text = teacher.fullName;
    _phone.text = teacher.phone ?? '';
    _whatsapp.text = teacher.whatsappNumber ?? '';
    _employeeCode.text = teacher.employeeCode ?? '';
    _status = teacher.status;
    _roles
      ..clear()
      ..addAll([
        if (teacher.isCommonTeacher) 'common_teacher',
        if (teacher.isMasterTeacher) 'master_teacher',
      ]);
  }

  void _scheduleBind(TeacherDto teacher) {
    if (_boundTeacherId == teacher.id) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _boundTeacherId == teacher.id) {
        return;
      }
      setState(() => _bind(teacher));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _roles.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).updateTeacher(widget.teacherId, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'whatsapp_number': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'employee_code': _employeeCode.text.trim().isEmpty ? null : _employeeCode.text.trim(),
        'status': _status,
        'roles': _roles.toList(),
      });
      ref.invalidate(adminTeacherProvider(widget.teacherId));
      ref.invalidate(adminTeachersProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher updated.')));
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
    final teacherValue = ref.watch(adminTeacherProvider(widget.teacherId));

    return AppScaffold(
      title: 'Teacher',
      backTo: RoutePaths.adminTeachers,
      body: AsyncBody(
        value: teacherValue,
        onRetry: () => ref.invalidate(adminTeacherProvider(widget.teacherId)),
        builder: (teacher) {
          _scheduleBind(teacher);
          return ListView(
            children: [
              TeacherCard(teacher: teacher),
              if (teacher.isMasterTeacher) ...[
                const SizedBox(height: 20),
                const Text(
                  'Rating progress',
                  style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 8),
                _AdminTeacherProgressSection(teacherId: widget.teacherId),
              ],
              const SizedBox(height: 12),
              DetailSection(
                title: 'Account',
                children: [
                  DetailRow(label: 'Email', value: teacher.email),
                  if (teacher.createdAt != null)
                    DetailRow(label: 'Registered', value: formatDisplayDateTime(teacher.createdAt)),
                  if (teacher.employeeCode != null && teacher.employeeCode!.isNotEmpty)
                    DetailRow(label: 'Employee code', value: teacher.employeeCode!),
                  if (teacher.phone != null && teacher.phone!.isNotEmpty)
                    DetailRow(label: 'Phone', value: teacher.phone!),
                  if (teacher.whatsappNumber != null && teacher.whatsappNumber!.isNotEmpty)
                    DetailRow(label: 'WhatsApp', value: teacher.whatsappNumber!),
                ],
              ),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Edit teacher',
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
                          controller: _employeeCode,
                          decoration: const InputDecoration(labelText: 'Employee code'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixText: '+91  ',
                          ),
                          validator: validateOptionalPhone,
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
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _roles.contains('common_teacher'),
                          title: const Text('Common Teacher'),
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              _roles.add('common_teacher');
                            } else {
                              _roles.remove('common_teacher');
                            }
                          }),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _roles.contains('master_teacher'),
                          title: const Text('Master Teacher'),
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              _roles.add('master_teacher');
                            } else {
                              _roles.remove('master_teacher');
                            }
                          }),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _saving ? null : _save,
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
          onPendingStudentTap: (student) => context.go(RoutePaths.adminStudent(student.id)),
        );
      },
    );
  }
}
