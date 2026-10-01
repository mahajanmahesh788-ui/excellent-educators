import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/add_payment_modal.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_history.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_plan_form.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_reminder_actions.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class AdminStudentPaymentsPage extends ConsumerStatefulWidget {
  const AdminStudentPaymentsPage({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<AdminStudentPaymentsPage> createState() =>
      _AdminStudentPaymentsPageState();
}

class _AdminStudentPaymentsPageState
    extends ConsumerState<AdminStudentPaymentsPage> {
  final _createPlanForm = PaymentPlanFormController();
  var _savingPlan = false;

  String get _backTo {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from == 'payments') {
      return RoutePaths.adminPayments;
    }
    return RoutePaths.adminStudent(widget.studentId);
  }

  Future<void> _createPlan() async {
    final payload = _createPlanForm.toPayload();
    if (payload == null) {
      showFailure(context, AppStrings.selectAPaymentPlan);
      return;
    }
    setState(() => _savingPlan = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .savePlan(widget.studentId, payload);
      ref.invalidate(adminStudentPaymentPlanProvider(widget.studentId));
      ref.invalidate(adminStudentProvider(widget.studentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.paymentPlanSaved)),
        );
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _savingPlan = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planValue = ref.watch(adminStudentPaymentPlanProvider(widget.studentId));
    final studentValue = ref.watch(adminStudentProvider(widget.studentId));
    final user = ref.watch(authControllerProvider).user;
    final canRecord = user?.canAnyAdmin(const [
          AdminPermission.paymentsRecord,
          AdminPermission.paymentsManage,
        ]) ??
        false;
    final canManage =
        user?.canAdmin(AdminPermission.paymentsManage) ?? false;

    return AppScaffold(
      title: AppStrings.payments,
      backTo: _backTo,
      body: AsyncBody(
        value: planValue,
        onRetry: () =>
            ref.invalidate(adminStudentPaymentPlanProvider(widget.studentId)),
        builder: (plan) {
          final studentName = studentValue.maybeWhen(
            data: (s) => s.fullName,
            orElse: () => null,
          );
          final phone = studentValue.maybeWhen(
            data: (s) => s.phone,
            orElse: () => null,
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Text(
                studentName ?? '—',
                style: TextStyle(
                  color: studentName == null ? Brand.muted : Brand.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              if (plan != null) ...[
                PaymentSummaryCard(plan: plan),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (plan.pendingAmount > 0)
                        PaymentReminderActions(
                          studentId: widget.studentId,
                          phone: phone,
                        ),
                      if (canRecord && plan.pendingAmount > 0)
                        FilledButton.icon(
                          onPressed: () async {
                            final ok = await showAddPaymentModal(
                              context,
                              ref,
                              studentId: widget.studentId,
                              suggestedAmount:
                                  plan.nextDueAmount ?? plan.pendingAmount,
                              totalAmount: plan.totalAmount,
                              pendingAmount: plan.pendingAmount,
                            );
                            if (!mounted) return;
                            if (ok) {
                              await Future<void>.delayed(Duration.zero);
                              if (!mounted) return;
                              ref.invalidate(
                                adminStudentPaymentPlanProvider(widget.studentId),
                              );
                              ref.invalidate(
                                adminStudentProvider(widget.studentId),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text(AppStrings.addPayment),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PaymentHistoryList(
                  payments: plan.payments,
                  pendingAmount: plan.pendingAmount,
                  totalAmount: plan.totalAmount,
                  paidAmount: plan.paidAmount,
                  paymentTypeLabel: plan.paymentTypeLabel,
                  receiptStudent: studentValue.maybeWhen(
                    data: (s) => PaymentReceiptStudent.fromStudent(
                      fullName: s.fullName,
                      studentCode: s.studentCode,
                      phone: s.phone,
                      email: s.email,
                      whatsappNumber: s.whatsappNumber,
                      levelName: s.level?.label,
                      batchName: s.batch?.label,
                    ),
                    orElse: () =>
                        PaymentReceiptStudent.fromPlanRef(plan.student),
                  ),
                  repository: ref.read(paymentRepositoryProvider),
                  studentId: widget.studentId,
                  persistAsAdmin: true,
                  onReceiptUpdated: () => ref.invalidate(
                    adminStudentPaymentPlanProvider(widget.studentId),
                  ),
                ),
              ] else ...[
                const Text(
                  AppStrings.noPaymentPlanYet,
                  style: TextStyle(color: Brand.muted),
                ),
                const SizedBox(height: 16),
                if (canManage) ...[
                  PaymentPlanFormFields(controller: _createPlanForm),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: _savingPlan ? null : _createPlan,
                      child: Text(
                        _savingPlan
                            ? AppStrings.saving
                            : AppStrings.createPaymentPlan,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
