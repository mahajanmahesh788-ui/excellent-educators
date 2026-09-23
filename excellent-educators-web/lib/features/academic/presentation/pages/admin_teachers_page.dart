import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/assessment_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminTeachersPage extends ConsumerWidget {
  const AdminTeachersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminTeachersFilterProvider);
    final teachers = ref.watch(adminTeachersProvider(filter));
    final repo = ref.watch(academicRepositoryProvider);
    final page = teachers.asData?.value;

    final user = ref.watch(authControllerProvider).user;
    final canCreate = user?.canAdmin(AdminPermission.teachersCreate) ?? false;

    return AppScaffold(
      title: AppStrings.teachers,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.go(RoutePaths.adminTeacherNew),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addTeacher),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DirectoryToolbar(
            key: const ValueKey('admin-teachers-toolbar'),
            searchHint: AppStrings.searchNamePhoneAddressOrEmail,
            searchQuery: filter.search,
            onSearchChanged: (value) {
              ref.read(adminTeachersFilterProvider.notifier).state = filter
                  .copyWith(search: value, page: 1);
            },
            total: page?.total,
            page: page?.page ?? filter.page,
            perPage: page?.perPage,
            onPageChanged: (nextPage) {
              ref.read(adminTeachersFilterProvider.notifier).state = filter
                  .copyWith(page: nextPage);
            },
            statusItems: statusFilterItems,
            selectedStatus: filter.status,
            onStatusChanged: (value) {
              ref.read(adminTeachersFilterProvider.notifier).state = filter
                  .copyWith(status: value, page: 1, clearStatus: value == null);
            },
          ),
          Expanded(
            child: AsyncBody(
              value: teachers,
              onRetry: () => ref.invalidate(adminTeachersProvider(filter)),
              builder: (page) {
                final items = repo.parseTeachers(page);

                if (items.isEmpty &&
                    filter.search.isEmpty &&
                    filter.status == null) {
                  return const EmptyHint(
                    AppStrings.noTeachersYet,
                    icon: EmptyIcons.teachers,
                    subtitle: AppStrings.addMasterTeachersToMentorStudents,
                  );
                }

                if (items.isEmpty) {
                  return const EmptyHint(
                    AppStrings.noTeachersMatchYourFilters,
                    icon: EmptyIcons.search,
                    subtitle: AppStrings.tryADifferentSearchTermOrFilter,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 72),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return DirectoryHeader(
                        countLabel: page.total == 1
                            ? AppStrings.n1Teacher
                            : '${page.total} teachers',
                      );
                    }
                    final teacher = items[index - 1];
                    return TeacherCard(
                      teacher: teacher,
                      onTap: () =>
                          context.go(RoutePaths.adminTeacher(teacher.id)),
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

class AdminCreateTeacherPage extends ConsumerStatefulWidget {
  const AdminCreateTeacherPage({super.key});

  @override
  ConsumerState<AdminCreateTeacherPage> createState() =>
      _AdminCreateTeacherPageState();
}

class _AdminCreateTeacherPageState
    extends ConsumerState<AdminCreateTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  late final MentorProfileDraft _mentor = MentorProfileDraft();
  String? _gender;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _mentor.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).createTeacher({
        'name': _name.text.trim(),
        'gender': _gender,
        'email': _email.text.trim(),
        'password': _password.text,
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'whatsapp_number': _whatsapp.text.trim().isEmpty
            ? null
            : _whatsapp.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'roles': ['master_teacher'],
        ..._mentor.toPayload(),
      });
      ref.invalidate(adminTeachersProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        context.go(RoutePaths.adminTeachers);
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
      title: AppStrings.addTeacher,
      backTo: RoutePaths.adminTeachers,
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
            const SizedBox(height: 12),
            GenderDropdown(
              value: _gender,
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: AppStrings.email),
              validator: validateRequired,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: AppStrings.temporaryPassword,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: validateRequired,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppStrings.phoneNumber,
                prefixText: '+91  ',
              ),
              validator: validateOptionalPhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppStrings.whatsappNumberOptional,
                prefixText: '+91  ',
              ),
              validator: validateOptionalPhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: AppStrings.address,
                hintText: AppStrings.enterTeacherAddress,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            MentorProfileEditor(
              draft: _mentor,
              onChanged: () => setState(() {}),
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
                  : const Text(AppStrings.createTeacher),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminEditTeacherPage extends ConsumerStatefulWidget {
  const AdminEditTeacherPage({super.key, required this.teacherId});

  final String teacherId;

  @override
  ConsumerState<AdminEditTeacherPage> createState() =>
      _AdminEditTeacherPageState();
}

class _AdminEditTeacherPageState extends ConsumerState<AdminEditTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  MentorProfileDraft? _mentor;
  String? _status;
  String? _gender;
  String? _boundTeacherId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _mentor?.dispose();
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
    _address.text = teacher.address ?? '';
    _status = teacher.status;
    _gender = teacher.gender;
    _mentor?.dispose();
    _mentor = MentorProfileDraft.fromTeacher(teacher);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _mentor == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).updateTeacher(
        widget.teacherId,
        {
          'name': _name.text.trim(),
          'gender': _gender,
          'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          'whatsapp_number': _whatsapp.text.trim().isEmpty
              ? null
              : _whatsapp.text.trim(),
          'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
          'status': _status,
          'roles': ['master_teacher'],
          ..._mentor!.toPayload(),
        },
      );
      ref.invalidate(adminTeacherProvider(widget.teacherId));
      ref.invalidate(adminTeachersProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        context.go(RoutePaths.adminTeacher(widget.teacherId));
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

    return AppFormPage(
      title: AppStrings.editTeacher,
      backTo: RoutePaths.adminTeacher(widget.teacherId),
      child: AsyncBody(
        value: teacherValue,
        onRetry: () => ref.invalidate(adminTeacherProvider(widget.teacherId)),
        builder: (teacher) {
          if (_boundTeacherId != teacher.id || _mentor == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _bind(teacher));
            });
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: AppStrings.fullName,
                    ),
                    validator: validateRequired,
                  ),
                  const SizedBox(height: 12),
                  GenderDropdown(
                    value: _gender,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: AppStrings.address,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: AppStrings.phoneNumber,
                      prefixText: '+91  ',
                    ),
                    validator: validateOptionalPhone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: AppStrings.whatsappNumberOptional,
                      prefixText: '+91  ',
                    ),
                    validator: validateOptionalPhone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_status),
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: AppStrings.status2,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text(AppStrings.active),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text(AppStrings.inactive),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 28),
                  MentorProfileEditor(
                    draft: _mentor!,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
