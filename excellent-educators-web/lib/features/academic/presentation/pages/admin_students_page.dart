import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/phone_whatsapp_address_fields.dart';
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
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_plan_form.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_qr_popup.dart';

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
      searchHint: AppStrings.searchNameStudentIdPhoneOrEmail,
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
      countNoun: 'student',
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

    final user = ref.watch(authControllerProvider).user;
    final canCreate = user?.canAdmin(AdminPermission.studentsCreate) ?? false;

    return AppScaffold(
      title: AppStrings.students,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.go(RoutePaths.adminStudentNew),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addStudent),
            )
          : null,
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
                    AppStrings.noStudentsYet,
                    icon: EmptyIcons.students,
                    subtitle: AppStrings.addAStudentToGenerateAStudentIdAndStart,
                  );
                }

                if (items.isEmpty) {
                  return const EmptyHint(
                    AppStrings.noStudentsMatchYourFilters,
                    icon: EmptyIcons.search,
                    subtitle: AppStrings.tryADifferentSearchTermOrFilter,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 72),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = items[index];
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
  final _paymentForm = PaymentPlanFormController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _guardianName = TextEditingController();
  int? _classGrade;
  String? _gender;
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

  Future<void> _onCreatePressed() async {
    if (!_formKey.currentState!.validate() ||
        _classGrade == null ||
        _gender == null) {
      return;
    }

    final payment = _paymentForm.toPayload();
    final amount = _paymentAmountFromPayload(payment);
    final paid = await showEnrolmentPaymentQrPopup(
      context,
      amount: amount,
    );
    if (!paid || !mounted) {
      return;
    }
    await _submit();
  }

  double? _paymentAmountFromPayload(Map<String, dynamic>? payment) {
    if (payment == null) {
      return null;
    }
    final raw = payment['payment_amount'] ??
        payment['initial_amount'] ??
        payment['total_amount'];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse('$raw');
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final payment = _paymentForm.toPayload();
      await ref.read(academicRepositoryProvider).createStudent({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp_number': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'class_grade': _classGrade,
        'gender': _gender,
        'guardian_name': _guardianName.text.trim().isEmpty ? null : _guardianName.text.trim(),
        if (payment != null) 'payment': payment,
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
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 960;
    final isMobile = width < 700;

    final content = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _IntroPanel(selectedClassGrade: _classGrade),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 7,
                child: _formCard(isMobile: false),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IntroPanel(
                selectedClassGrade: _classGrade,
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 12 : 20),
              _formCard(isMobile: isMobile),
            ],
          );

    return AppScaffold(
      title: AppStrings.addStudent,
      backTo: RoutePaths.adminStudents,
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        child: content,
      ),
    );
  }

  Widget _formCard({required bool isMobile}) {
    final fieldGap = isMobile ? 10.0 : 14.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: isMobile ? 3 : 4,
            decoration: BoxDecoration(
              color: Brand.gold,
              borderRadius: BorderRadius.vertical(top: Radius.circular(isMobile ? 14 : 18)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 14 : 22,
              isMobile ? 16 : 24,
              isMobile ? 18 : 28,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.enrolmentRequest,
                    style: TextStyle(
                      color: Brand.goldDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: isMobile ? 1.4 : 1.8,
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    AppStrings.studentDetails,
                    style: TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 20 : 26,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    AppStrings.submittingThisFormCreatesTheStudentAndIssuesAStudent,
                    style: TextStyle(
                      color: Brand.muted,
                      height: 1.35,
                      fontSize: isMobile ? 12.5 : 14,
                    ),
                  ),
                  SizedBox(height: isMobile ? 14 : 20),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_classGrade),
                    value: _classGrade,
                    decoration: InputDecoration(
                      labelText: AppStrings.classLabel,
                      hintText: AppStrings.selectStudentClass,
                      isDense: isMobile,
                      contentPadding: isMobile
                          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                          : null,
                    ),
                    items: [
                      for (final grade in [5, 6, 7, 8, 9, 10, 11, 12])
                        DropdownMenuItem(
                          value: grade,
                          child: Text('Class $grade (${_classOrdinal(grade)} Class)'),
                        ),
                    ],
                    validator: (value) => value == null ? AppStrings.pleaseSelectAClass : null,
                    onChanged: (value) => setState(() => _classGrade = value),
                  ),
                  SizedBox(height: fieldGap),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: AppStrings.fullName,
                      isDense: isMobile,
                      contentPadding: isMobile
                          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                          : null,
                    ),
                    validator: validateRequired,
                  ),
                  SizedBox(height: fieldGap),
                  GenderDropdown(
                    value: _gender,
                    isDense: isMobile,
                    contentPadding: isMobile
                        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                        : null,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  SizedBox(height: fieldGap),
                  PhoneWhatsappAddressFields(
                    phone: _phone,
                    whatsapp: _whatsapp,
                    address: _address,
                    addressHint: AppStrings.enterStudentAddress,
                    fieldSpacing: fieldGap,
                    isDense: isMobile,
                    contentPadding: isMobile
                        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                        : null,
                  ),
                  SizedBox(height: fieldGap),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      isDense: isMobile,
                      contentPadding: isMobile
                          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                          : null,
                    ),
                    validator: (value) {
                      if (validateRequired(value) != null) {
                        return AppStrings.enterAnEmail;
                      }
                      if (!value!.contains('@')) {
                        return AppStrings.enterAValidEmail;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: fieldGap),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: AppStrings.temporaryPassword,
                      isDense: isMobile,
                      contentPadding: isMobile
                          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                          : null,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: validateRequired,
                  ),
                  SizedBox(height: fieldGap),
                  TextFormField(
                    controller: _guardianName,
                    decoration: InputDecoration(
                      labelText: AppStrings.guardianNameOptional,
                      isDense: isMobile,
                      contentPadding: isMobile
                          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                          : null,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  PaymentPlanFormFields(controller: _paymentForm),
                  SizedBox(height: isMobile ? 16 : 24),
                  FilledButton(
                    style: isMobile
                        ? FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          )
                        : null,
                    onPressed: _saving ? null : _onCreatePressed,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Brand.navy),
                          )
                        : const Text(AppStrings.createStudent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({
    required this.selectedClassGrade,
    this.isMobile = false,
  });

  final int? selectedClassGrade;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isMobile ? 2 : 8,
        right: isMobile ? 0 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.enrolment,
            style: TextStyle(
              color: Brand.goldDark,
              fontWeight: FontWeight.w700,
              letterSpacing: isMobile ? 1.4 : 2,
              fontSize: isMobile ? 11 : 12,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 12),
          Text(
            AppStrings.letSStartWithAStudent,
            style: TextStyle(
              color: Brand.navy,
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 22 : 36,
              height: 1.15,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 14),
          Text(
            AppStrings.selectTheStudentSClassThenEnterContactAndAddress,
            style: TextStyle(
              color: Brand.muted,
              fontSize: isMobile ? 13 : 16,
              height: 1.35,
            ),
          ),
          SizedBox(height: isMobile ? 10 : 28),
          if (selectedClassGrade != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 12 : 18),
              decoration: BoxDecoration(
                color: Brand.navy,
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.selectedEnrolment,
                    style: TextStyle(
                      color: Brand.gold,
                      letterSpacing: 1.4,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    'Class $selectedClassGrade (${_classOrdinal(selectedClassGrade!)} Class)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w700,
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

String _classOrdinal(int grade) {
  switch (grade) {
    case 5:
      return AppStrings.n5th;
    case 6:
      return AppStrings.n6th;
    case 7:
      return AppStrings.n7th;
    case 8:
      return AppStrings.n8th;
    case 9:
      return AppStrings.n9th;
    case 10:
      return AppStrings.n10th;
    case 11:
      return AppStrings.n11th;
    case 12:
      return AppStrings.n12th;
    default:
      return '${grade}th';
  }
}
