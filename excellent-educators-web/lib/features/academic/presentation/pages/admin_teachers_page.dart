import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/assessment_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminTeachersPage extends ConsumerWidget {
  const AdminTeachersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminTeachersFilterProvider);
    final teachers = ref.watch(adminTeachersProvider(filter));
    final repo = ref.watch(academicRepositoryProvider);
    final page = teachers.asData?.value;

    return AppScaffold(
      title: 'Teachers',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.adminTeacherNew),
        icon: const Icon(Icons.add),
        label: const Text('Add teacher'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DirectoryToolbar(
            key: const ValueKey('admin-teachers-toolbar'),
            searchHint: 'Search name, employee code, phone, or email',
            searchQuery: filter.search,
            onSearchChanged: (value) {
              ref.read(adminTeachersFilterProvider.notifier).state =
                  filter.copyWith(search: value, page: 1);
            },
            total: page?.total,
            page: page?.page ?? filter.page,
            perPage: page?.perPage,
            onPageChanged: (nextPage) {
              ref.read(adminTeachersFilterProvider.notifier).state = filter.copyWith(page: nextPage);
            },
            statusItems: statusFilterItems,
            selectedStatus: filter.status,
            onStatusChanged: (value) {
              ref.read(adminTeachersFilterProvider.notifier).state = filter.copyWith(
                    status: value,
                    page: 1,
                    clearStatus: value == null,
                  );
            },
          ),
          Expanded(
            child: AsyncBody(
              value: teachers,
              onRetry: () => ref.invalidate(adminTeachersProvider(filter)),
              builder: (page) {
                final items = repo.parseTeachers(page);

                if (items.isEmpty && filter.search.isEmpty && filter.status == null) {
                  return const EmptyHint(
                    'No teachers yet',
                    icon: EmptyIcons.teachers,
                    subtitle: 'Add teachers and assign Common or Master Teacher roles.',
                  );
                }

                if (items.isEmpty) {
                  return const EmptyHint(
                    'No teachers match your filters',
                    icon: EmptyIcons.search,
                    subtitle: 'Try a different search term or filter.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 72),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return DirectoryHeader(
                        countLabel: page.total == 1 ? '1 teacher' : '${page.total} teachers',
                      );
                    }
                    final teacher = items[index - 1];
                    return TeacherCard(
                      teacher: teacher,
                      onTap: () => context.go(RoutePaths.adminTeacher(teacher.id)),
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
  ConsumerState<AdminCreateTeacherPage> createState() => _AdminCreateTeacherPageState();
}

class _AdminCreateTeacherPageState extends ConsumerState<AdminCreateTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _employeeCode = TextEditingController();
  final _roles = <String>{'common_teacher'};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _employeeCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _roles.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).createTeacher({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'whatsapp_number': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'employee_code': _employeeCode.text.trim().isEmpty ? null : _employeeCode.text.trim(),
        'roles': _roles.toList(),
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
      title: 'Add teacher',
      backTo: RoutePaths.adminTeachers,
      child: Form(
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
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Temporary password'),
              validator: _required,
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
            TextFormField(
              controller: _employeeCode,
              decoration: const InputDecoration(labelText: 'Employee code (optional)'),
            ),
            const SizedBox(height: 16),
            Text('Roles', style: Theme.of(context).textTheme.titleSmall),
            CheckboxListTile(
              value: _roles.contains('common_teacher'),
              title: const Text('Common Teacher'),
              subtitle: const Text('Assigned to a batch. Can view student profiles only.'),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _roles.add('common_teacher');
                } else {
                  _roles.remove('common_teacher');
                }
              }),
            ),
            CheckboxListTile(
              value: _roles.contains('master_teacher'),
              title: const Text('Master Teacher'),
              subtitle: const Text('Assigned to students. Writes monthly development feedback later.'),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _roles.add('master_teacher');
                } else {
                  _roles.remove('master_teacher');
                }
              }),
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
                  : const Text('Create teacher'),
            ),
          ],
        ),
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
