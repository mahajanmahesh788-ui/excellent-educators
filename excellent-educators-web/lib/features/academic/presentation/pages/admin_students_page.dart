import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/assessment_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_dashboard_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/utils/admin_list_route_sync.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_cards.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminStudentsPage extends ConsumerStatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  ConsumerState<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends ConsumerState<AdminStudentsPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scheduleStudentsFilterFromRoute(
      ref,
      GoRouterState.of(context),
      isMounted: () => mounted,
    );
  }

  void _setFilter(AdminListFilter filter) {
    ref.read(adminStudentsFilterProvider.notifier).state = filter;
  }

  Widget _buildStudentsToolbar({
    required AdminListFilter filter,
    required List<DropdownMenuItem<String>> levelItems,
    PagedResult? page,
  }) {
    return DirectoryToolbar(
      key: const ValueKey('admin-students-toolbar'),
      searchHint: 'Search name, Student ID, phone, or email',
      searchQuery: filter.search,
      onSearchChanged: (value) => _setFilter(filter.copyWith(search: value, page: 1)),
      levelItems: levelItems.isEmpty ? null : levelItems,
      selectedLevelId: filter.levelId,
      onLevelChanged: levelItems.isEmpty
          ? null
          : (value) => _setFilter(filter.copyWith(levelId: value, page: 1, clearLevel: value == null)),
      statusItems: statusFilterItems,
      selectedStatus: filter.status,
      onStatusChanged: (value) => _setFilter(filter.copyWith(status: value, page: 1, clearStatus: value == null)),
      attentionItems: studentAttentionFilterItems,
      selectedAttention: filter.attentionKey,
      onAttentionChanged: (value) {
        _setFilter(filter.copyWith(attentionKey: value, page: 1, clearAttention: value == null));
        if (value == null && GoRouterState.of(context).uri.queryParameters.containsKey('attention')) {
          context.go(RoutePaths.adminStudents);
        }
      },
      total: page?.total,
      page: page?.page ?? filter.page,
      perPage: page?.perPage,
      onPageChanged: (nextPage) => _setFilter(filter.copyWith(page: nextPage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(adminStudentsFilterProvider);
    final students = ref.watch(adminStudentsProvider(filter));
    final levels = ref.watch(careerCompassLevelsProvider);
    final repo = ref.watch(academicRepositoryProvider);
    final levelItems = levels.maybeWhen(
      data: careerCompassDropdownItems,
      orElse: () => <DropdownMenuItem<String>>[],
    );
    final page = students.asData?.value;

    return AppScaffold(
      title: 'Students',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.adminStudentNew),
        icon: const Icon(Icons.add),
        label: const Text('Add student'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStudentsToolbar(filter: filter, levelItems: levelItems, page: page),
          if (filter.attentionLabel != null) ...[
            const SizedBox(height: 8),
            ActiveFilterBanner(
              label: filter.attentionLabel!,
              onClear: () => clearStudentsAttentionRoute(context, ref, filter),
            ),
          ],
          Expanded(
            child: AsyncBody(
              value: students,
              onRetry: () => ref.invalidate(adminStudentsProvider(filter)),
              builder: (page) {
                final items = repo.parseStudents(page);

                if (items.isEmpty &&
                    filter.search.isEmpty &&
                    filter.levelId == null &&
                    filter.status == null &&
                    filter.attentionKey == null) {
                  return const EmptyHint(
                    'No students yet',
                    icon: EmptyIcons.students,
                    subtitle: 'Add a student to generate a Student ID and start tracking progress.',
                  );
                }

                if (items.isEmpty) {
                  return const EmptyHint(
                    'No students match your filters',
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
                        countLabel: page.total == 1 ? '1 student' : '${page.total} students',
                      );
                    }
                    final student = items[index - 1];
                    return StudentCard(
                      student: student,
                      onTap: () => context.go(RoutePaths.adminStudent(student.id)),
                      action: OutlinedButton(
                        onPressed: () => _assignMentor(context, student),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Brand.navy,
                          side: const BorderSide(color: Brand.gold),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: Text(
                          student.masterTeacher == null || student.masterTeacher!.isEmpty
                              ? 'Assign Master Teacher'
                              : 'Change Master Teacher',
                        ),
                      ),
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
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }
}

class AdminCreateStudentPage extends ConsumerStatefulWidget {
  const AdminCreateStudentPage({super.key});

  @override
  ConsumerState<AdminCreateStudentPage> createState() => _AdminCreateStudentPageState();
}

class _AdminCreateStudentPageState extends ConsumerState<AdminCreateStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _guardianName = TextEditingController();
  String? _levelId;
  bool _saving = false;
  bool _obscure = true;
  bool _attempted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _password.dispose();
    _guardianName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _attempted = true);
    if (!_formKey.currentState!.validate() || _levelId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).createStudent({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp_number': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'career_compass_level_id': _levelId,
        'guardian_name': _guardianName.text.trim().isEmpty ? null : _guardianName.text.trim(),
      });
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        context.go(RoutePaths.adminStudents);
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
    final levels = ref.watch(careerCompassLevelsProvider);
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return AppScaffold(
      title: 'Add student',
      backTo: RoutePaths.adminStudents,
      body: AsyncBody(
        value: levels,
        onRetry: () => ref.invalidate(careerCompassLevelsProvider),
        builder: (items) {
          final content = wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _IntroPanel(selectedId: _levelId, levels: items)),
                    const SizedBox(width: 28),
                    Expanded(flex: 7, child: _formCard(items)),
                  ],
                )
              : Column(
                  children: [
                    _IntroPanel(selectedId: _levelId, levels: items),
                    const SizedBox(height: 20),
                    _formCard(items),
                  ],
                );

          return SingleChildScrollView(child: content);
        },
      ),
    );
  }

  Widget _formCard(List<CareerCompassLevelDto> items) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Brand.gold,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ENROLMENT REQUEST',
                    style: TextStyle(
                      color: Brand.goldDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Student details',
                    style: TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Submitting this form creates the student and issues a Student ID. Confirmation is immediate.',
                    style: TextStyle(color: Brand.muted, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Career Compass',
                    style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Class range is already defined by the selected level.',
                    style: TextStyle(color: Brand.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ...items.map((level) {
                    final selected = _levelId == level.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: selected ? const Color(0xFFFBF6EA) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: selected ? Brand.gold : const Color(0xFFD7CDBB),
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _levelId = level.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Text(
                                  '✦',
                                  style: TextStyle(
                                    color: selected ? Brand.goldDark : Brand.muted,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${level.shortCode}  ${level.name}',
                                        style: const TextStyle(
                                          color: Brand.navy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Classes ${level.classFrom}–${level.classTo}',
                                        style: const TextStyle(color: Brand.muted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected ? Icons.check_circle : Icons.circle_outlined,
                                  color: selected ? Brand.goldDark : Brand.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_attempted && _levelId == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Select a Career Compass level.',
                        style: TextStyle(color: Color(0xFFB42318), fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixText: '+91  ',
                    ),
                    validator: validateRequiredPhone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp number (optional)',
                      prefixText: '+91  ',
                    ),
                    validator: validateOptionalPhone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (_required(value) != null) {
                        return 'Enter an email.';
                      }
                      if (!value!.contains('@')) {
                        return 'Enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Temporary password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guardianName,
                    decoration: const InputDecoration(labelText: 'Guardian name (optional)'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Brand.navy),
                          )
                        : const Text('Create student'),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.selectedId, required this.levels});

  final String? selectedId;
  final List<CareerCompassLevelDto> levels;

  @override
  Widget build(BuildContext context) {
    final selected = levels.where((level) => level.id == selectedId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENROLMENT',
            style: TextStyle(
              color: Brand.goldDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Let’s start with a student',
            style: TextStyle(
              color: Brand.navy,
              fontWeight: FontWeight.w700,
              fontSize: 36,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Choose a Career Compass level, then add contact details. The class band is already part of that level, and the Student ID is generated after you save.',
            style: TextStyle(color: Brand.muted, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 28),
          if (selected != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Brand.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✦  SELECTED LEVEL', style: TextStyle(color: Brand.gold, letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    selected.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Classes ${selected.classFrom}–${selected.classTo}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
