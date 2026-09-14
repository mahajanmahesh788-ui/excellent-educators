import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/assessment_providers.dart';
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
    PagedResult? page,
  }) {
    return DirectoryToolbar(
      key: const ValueKey('admin-students-toolbar'),
      searchHint: 'Search name, Student ID, phone, or email',
      searchQuery: filter.search,
      onSearchChanged: (value) => _setFilter(filter.copyWith(search: value, page: 1)),
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
    final repo = ref.watch(academicRepositoryProvider);
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
          _buildStudentsToolbar(filter: filter, page: page),
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
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _guardianName = TextEditingController();
  int? _classGrade;
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _email.dispose();
    _password.dispose();
    _guardianName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _classGrade == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(academicRepositoryProvider).createStudent({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp_number': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'class_grade': _classGrade,
        'guardian_name': _guardianName.text.trim().isEmpty ? null : _guardianName.text.trim(),
      });
      ref.invalidate(adminStudentsProvider);
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
    final wide = MediaQuery.sizeOf(context).width >= 960;

    final content = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _IntroPanel(selectedClassGrade: _classGrade)),
              const SizedBox(width: 28),
              Expanded(flex: 7, child: _formCard()),
            ],
          )
        : Column(
            children: [
              _IntroPanel(selectedClassGrade: _classGrade),
              const SizedBox(height: 20),
              _formCard(),
            ],
          );

    return AppScaffold(
      title: 'Add student',
      backTo: RoutePaths.adminStudents,
      body: SingleChildScrollView(child: content),
    );
  }

  Widget _formCard() {
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
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_classGrade),
                    value: _classGrade,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      hintText: 'Select student class',
                    ),
                    items: [
                      for (final grade in [5, 6, 7, 8, 9, 10, 11, 12])
                        DropdownMenuItem(
                          value: grade,
                          child: Text('Class $grade (${_classOrdinal(grade)} Class)'),
                        ),
                    ],
                    validator: (value) => value == null ? 'Please select a class.' : null,
                    onChanged: (value) => setState(() => _classGrade = value),
                  ),
                  const SizedBox(height: 14),
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
                    controller: _address,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter student address',
                      alignLabelWithHint: true,
                    ),
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
  const _IntroPanel({required this.selectedClassGrade});

  final int? selectedClassGrade;

  @override
  Widget build(BuildContext context) {
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
            'Select the student’s class, then enter contact and address details. The Student ID is generated automatically after you save.',
            style: TextStyle(color: Brand.muted, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 28),
          if (selectedClassGrade != null)
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
                  const Text('✦  SELECTED ENROLMENT', style: TextStyle(color: Brand.gold, letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Class $selectedClassGrade (${_classOrdinal(selectedClassGrade!)} Class)',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _classOrdinal(int grade) {
  switch (grade) {
    case 5:
      return '5th';
    case 6:
      return '6th';
    case 7:
      return '7th';
    case 8:
      return '8th';
    case 9:
      return '9th';
    case 10:
      return '10th';
    case 11:
      return '11th';
    case 12:
      return '12th';
    default:
      return '${grade}th';
  }
}
