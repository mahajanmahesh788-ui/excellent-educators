import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_history.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentPaymentsPage extends ConsumerWidget {
  const StudentPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(studentOwnPaymentsProvider);

    return StudentScaffold(
      title: AppStrings.payments,
      body: AsyncBody(
        value: payments,
        onRetry: () => ref.invalidate(studentOwnPaymentsProvider),
        builder: (data) {
          final plan = data.plan;
          if (plan == null) {
            return const Center(
              child: Text(
                AppStrings.noPaymentPlanAssigned,
                style: TextStyle(color: Brand.muted),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              StudentPaymentStatusCard(
                plan: plan,
                onlineEnabled: data.onlineEnabled,
                onPayNow: data.onlineEnabled && plan.pendingAmount > 0
                    ? () => _payNow(context, ref, plan)
                    : null,
              ),
              const SizedBox(height: 16),
              PaymentHistoryList(
                payments: plan.payments,
                pendingAmount: plan.pendingAmount,
              ),
            ],
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(AppStrings.confirmOnlinePayment),
          content: Text(
            '${AppStrings.paymentAmount}: ${formatRupee((initiated['amount'] as num?)?.toDouble() ?? 0)}\n\n'
            '${AppStrings.manualGatewayConfirmHelp}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.confirmPayment),
            ),
          ],
        ),
      );
      if (confirmed != true) {
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

  @override
  Widget build(BuildContext context) {
    final isPaid = plan.isPaid;
    final isOverdue = plan.isOverdue;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFFCDD2)
              : isPaid
                  ? const Color(0xFFC8E6C9)
                  : const Color(0xFFE8E6E0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.paymentStatus,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Brand.navy,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                PaymentStatusBadge(
                  status: plan.status,
                  label: plan.statusLabel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isPaid) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.paymentCompleted,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${formatRupee(plan.paidAmount)} ${AppStrings.paid.toLowerCase()}',
                style: const TextStyle(color: Brand.navy, fontSize: 15),
              ),
              const Text(
                AppStrings.noPendingPayment,
                style: TextStyle(color: Brand.muted),
              ),
            ] else ...[
              Text(
                '${formatRupee(plan.paidAmount)} ${AppStrings.paid.toLowerCase()}',
                style: const TextStyle(
                  color: Brand.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${formatRupee(plan.pendingAmount)} ${AppStrings.pending.toLowerCase()}',
                style: TextStyle(
                  color: isOverdue ? const Color(0xFFC62828) : Brand.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (plan.nextDueAmount != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.nextPayment}: ${formatRupee(plan.nextDueAmount!)}',
                  style: const TextStyle(color: Brand.muted),
                ),
              ],
              if (plan.nextDueDate != null)
                Text(
                  '${AppStrings.due}: ${formatDisplayDate(plan.nextDueDate)}',
                  style: const TextStyle(color: Brand.muted),
                ),
              if (onPayNow != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onPayNow,
                  child: const Text(AppStrings.payNow),
                ),
              ],
            ],
            if (onOpenHistory != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onOpenHistory,
                child: const Text(AppStrings.viewPaymentHistory),
              ),
            ],
          ],
        ),
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
