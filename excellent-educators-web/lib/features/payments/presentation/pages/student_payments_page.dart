import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_history.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_qr_popup.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentPaymentsPage extends ConsumerWidget {
  const StudentPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(studentOwnPaymentsProvider);
    final profile = ref.watch(studentProfileProvider);

    return StudentScaffold(
      title: AppStrings.payments,
      backTo: RoutePaths.studentProfile,
      body: AsyncBody(
        value: payments,
        onRetry: () => ref.invalidate(studentOwnPaymentsProvider),
        builder: (data) {
          final plan = data.plan;
          if (plan == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  AppStrings.noPaymentPlanAssigned,
                  style: TextStyle(color: Brand.muted, fontSize: 15),
                ),
              ),
            );
          }
          final profileStudent = profile.asData?.value;
          final receiptStudent = profileStudent != null
              ? PaymentReceiptStudent.fromStudent(
                  fullName: profileStudent.fullName,
                  studentCode: profileStudent.studentCode,
                  phone: profileStudent.phone,
                  email: profileStudent.email,
                  whatsappNumber: profileStudent.whatsappNumber,
                  levelName: profileStudent.level?.label,
                  batchName: profileStudent.batch?.label,
                )
              : PaymentReceiptStudent.fromPlanRef(plan.student);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 640;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 16 : 24,
                      vertical: 20,
                    ),
                    children: [
                      StudentPaymentStatusCard(
                        plan: plan,
                        onlineEnabled: data.onlineEnabled,
                        onPayNow: data.onlineEnabled && plan.pendingAmount > 0
                            ? () => _payNow(context, ref, plan)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      PaymentHistoryList(
                        payments: plan.payments,
                        pendingAmount: plan.pendingAmount,
                        totalAmount: plan.totalAmount,
                        paidAmount: plan.paidAmount,
                        paymentTypeLabel: plan.paymentTypeLabel,
                        receiptStudent: receiptStudent,
                        repository: ref.read(paymentRepositoryProvider),
                        persistAsAdmin: false,
                        onReceiptUpdated: () =>
                            ref.invalidate(studentOwnPaymentsProvider),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _payNow(
    BuildContext context,
    WidgetRef ref,
    StudentPaymentPlanDto plan,
  ) async {
    try {
      final initiated = await ref
          .read(paymentRepositoryProvider)
          .initiateOnline(amount: plan.nextDueAmount ?? plan.pendingAmount);
      final orderId = initiated['order_id'] as String?;
      if (orderId == null) {
        if (context.mounted) {
          showFailure(context, AppStrings.unableToStartPayment);
        }
        return;
      }
      final amount = (initiated['amount'] as num?)?.toDouble() ?? 0;
      if (!context.mounted) {
        return;
      }
      final paid = await showEnrolmentPaymentQrPopup(
        context,
        amount: amount,
      );
      if (paid != true) {
        return;
      }
      await ref.read(paymentRepositoryProvider).confirmOnline(orderId: orderId);
      ref.invalidate(studentOwnPaymentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.paymentSuccessful)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }
}

class StudentPaymentStatusCard extends StatelessWidget {
  const StudentPaymentStatusCard({
    super.key,
    required this.plan,
    this.onlineEnabled = false,
    this.onPayNow,
    this.onOpenHistory,
  });

  final StudentPaymentPlanDto plan;
  final bool onlineEnabled;
  final VoidCallback? onPayNow;
  final VoidCallback? onOpenHistory;

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required bool isOverdue,
    String? subtext,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Brand.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Brand.navy,
              letterSpacing: -0.3,
            ),
          ),
          if (subtext != null && subtext.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isOverdue && subtext == AppStrings.overdue
                    ? const Color(0xFFDC2626)
                    : Brand.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = plan.isPaid;
    final isOverdue = plan.isOverdue;
    final total = plan.totalAmount;
    final paid = plan.paidAmount;
    final ratio = total > 0 ? (paid / total).clamp(0.0, 1.0) : (isPaid ? 1.0 : 0.0);
    final percent = (ratio * 100).round();

    final planTypeTitle = plan.paymentTypeLabel ??
        (plan.paymentType == 'instalment'
            ? AppStrings.partialPayment
            : AppStrings.fullPayment);
    final courseLabel = plan.student?.courseLabel;
    final hasCourseLabel =
        courseLabel != null && courseLabel.isNotEmpty && courseLabel != '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFECACA)
              : isPaid
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top accent strip
          Container(
            height: 3,
            color: isPaid
                ? const Color(0xFF16A34A)
                : isOverdue
                    ? const Color(0xFFDC2626)
                    : Brand.navy,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Brand.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Brand.gold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.paymentStatus,
                            style: const TextStyle(
                              color: Brand.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                planTypeTitle,
                                style: const TextStyle(
                                  color: Brand.muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasCourseLabel) ...[
                                const Text(
                                  '  •  ',
                                  style: TextStyle(
                                    color: Brand.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    courseLabel,
                                    style: const TextStyle(
                                      color: Brand.muted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PaymentStatusBadge(
                      status: plan.status,
                      label: plan.statusLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Settlement Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Settlement Progress',
                          style: TextStyle(
                            color: Brand.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$percent% Settled',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPaid
                                  ? const Color(0xFF15803D)
                                  : Brand.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${formatRupee(paid)} of ${formatRupee(total)}',
                      style: const TextStyle(
                        color: Brand.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid
                          ? const Color(0xFF16A34A)
                          : isOverdue
                              ? const Color(0xFFDC2626)
                              : Brand.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Financial Metrics Grid (Responsive 4-column or 2x2)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tile1 = _buildMetricTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFE0F2FE),
                      label: AppStrings.totalAmount,
                      value: formatRupee(total),
                      isOverdue: isOverdue,
                      subtext: planTypeTitle,
                    );
                    final tile2 = _buildMetricTile(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFDCFCE7),
                      label: AppStrings.paidAmount,
                      value: formatRupee(paid),
                      valueColor: const Color(0xFF15803D),
                      isOverdue: isOverdue,
                      subtext: plan.payments.isEmpty
                          ? 'No receipts yet'
                          : '${plan.payments.length} ${plan.payments.length == 1 ? "receipt" : "receipts"}',
                    );
                    final tile3 = _buildMetricTile(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: isOverdue
                          ? const Color(0xFFDC2626)
                          : (plan.pendingAmount > 0
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A)),
                      iconBg: isOverdue
                          ? const Color(0xFFFEE2E2)
                          : (plan.pendingAmount > 0
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7)),
                      label: AppStrings.pendingAmount,
                      value: formatRupee(plan.pendingAmount),
                      valueColor: isOverdue
                          ? const Color(0xFFDC2626)
                          : (plan.pendingAmount > 0
                              ? const Color(0xFFB45309)
                              : const Color(0xFF15803D)),
                      isOverdue: isOverdue,
                      subtext: isOverdue
                          ? AppStrings.overdue
                          : (plan.pendingAmount <= 0
                              ? 'Fully cleared'
                              : 'Remaining balance'),
                    );
                    final tile4 = _buildMetricTile(
                      icon: Icons.calendar_today_outlined,
                      iconColor: const Color(0xFF4F46E5),
                      iconBg: const Color(0xFFEEF2FF),
                      label: AppStrings.nextPayment,
                      value: plan.nextDueAmount != null
                          ? formatRupee(plan.nextDueAmount!)
                          : (plan.pendingAmount > 0
                              ? formatRupee(plan.pendingAmount)
                              : '—'),
                      isOverdue: isOverdue,
                      subtext: plan.nextDueDate != null
                          ? '${AppStrings.due}: ${formatDisplayDate(plan.nextDueDate)}'
                          : (plan.pendingAmount <= 0
                              ? 'None scheduled'
                              : 'Upcoming instalment'),
                    );

                    if (constraints.maxWidth >= 620) {
                      return Row(
                        children: [
                          Expanded(child: tile1),
                          const SizedBox(width: 12),
                          Expanded(child: tile2),
                          const SizedBox(width: 12),
                          Expanded(child: tile3),
                          const SizedBox(width: 12),
                          Expanded(child: tile4),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: tile1),
                              const SizedBox(width: 10),
                              Expanded(child: tile2),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: tile3),
                              const SizedBox(width: 10),
                              Expanded(child: tile4),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Action / Informational Callout
                if (isPaid) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF16A34A),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All fee payments have been fully cleared and verified. Thank you!',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (onPayNow != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final narrow = c.maxWidth < 460;
                        final infoBlock = Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Brand.navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Brand.navy,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppStrings.nextPayment}: ${formatRupee(plan.nextDueAmount ?? plan.pendingAmount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Brand.navy,
                                    ),
                                  ),
                                  if (plan.nextDueDate != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${AppStrings.due}: ${formatDisplayDate(plan.nextDueDate)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Brand.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );

                        final payButton = FilledButton.icon(
                          onPressed: onPayNow,
                          style: FilledButton.styleFrom(
                            backgroundColor: Brand.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.credit_card_rounded, size: 16),
                          label: const Text(
                            AppStrings.payNow,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );

                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              infoBlock,
                              const SizedBox(height: 12),
                              payButton,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: infoBlock),
                            const SizedBox(width: 16),
                            payButton,
                          ],
                        );
                      },
                    ),
                  ),
                ] else if (plan.pendingAmount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Brand.navy,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Fee Settlement',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Brand.navy,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                AppStrings.contactInstituteToPay,
                                style: TextStyle(
                                  color: Brand.muted,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // History shortcut (when used in dashboard card)
                if (onOpenHistory != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onOpenHistory,
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppStrings.viewPaymentHistory),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
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

/// Compact card for student dashboard.
class StudentPaymentDashboardCard extends ConsumerWidget {
  const StudentPaymentDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(studentOwnPaymentsProvider);
    return payments.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final plan = data.plan;
        if (plan == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: StudentPaymentStatusCard(
            plan: plan,
            onlineEnabled: data.onlineEnabled,
            onPayNow: data.onlineEnabled && plan.pendingAmount > 0
                ? () => context.go(RoutePaths.studentPayments)
                : null,
            onOpenHistory: () => context.go(RoutePaths.studentPayments),
          ),
        );
      },
    );
  }
}
