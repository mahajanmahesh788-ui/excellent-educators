import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminEditStudentPage extends ConsumerStatefulWidget {
  const AdminEditStudentPage({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<AdminEditStudentPage> createState() => _AdminEditStudentPageState();
}

class _AdminEditStudentPageState extends ConsumerState<AdminEditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  String? _status;
  int? _classGrade;
  String? _gender;
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
    _classGrade = student.classGrade > 0 ? student.classGrade : null;
    _gender = student.gender;
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
        'gender': _gender,
      });
      ref.invalidate(adminStudentProvider(widget.studentId));
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.studentUpdatedSuccessfully)),
        );
        context.go(RoutePaths.adminStudent(widget.studentId));
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

    return AppFormPage(
      title: AppStrings.editStudent,
      backTo: RoutePaths.adminStudent(widget.studentId),
      child: AsyncBody(
        value: studentValue,
        onRetry: () => ref.invalidate(adminStudentProvider(widget.studentId)),
        builder: (student) {
          if (_boundStudentId != student.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _bind(student));
            });
            return const Center(child: CircularProgressIndicator());
          }

          const classOptions = [5, 6, 7, 8, 9, 10, 11, 12];

          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: AppStrings.fullName),
                    validator: validateRequired,
                  ),
                  const SizedBox(height: 14),
                  GenderDropdown(
                    value: _gender,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: AppStrings.phoneNumber,
                      prefixText: '+91  ',
                    ),
                    validator: validateRequiredPhone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: AppStrings.whatsappNumberOptional,
                      prefixText: '+91  ',
                    ),
                    validator: validateOptionalPhone,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_classGrade),
                    value: _classGrade,
                    decoration: const InputDecoration(labelText: AppStrings.classLabel),
                    items: [
                      for (final grade in classOptions)
                        DropdownMenuItem(
                          value: grade,
                          child: Text('Class $grade'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _classGrade = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_status),
                    value: _status,
                    decoration: const InputDecoration(labelText: AppStrings.status2),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text(AppStrings.active)),
                      DropdownMenuItem(value: 'inactive', child: Text(AppStrings.inactive)),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _address,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: AppStrings.address,
                      hintText: AppStrings.enterStudentAddress,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guardianName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: AppStrings.guardianNameOptional),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guardianPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: AppStrings.guardianPhoneOptional,
                      prefixText: '+91  ',
                    ),
                    validator: validateOptionalPhone,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(student),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Brand.navy),
                          )
                        : const Text(AppStrings.saveChanges),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
