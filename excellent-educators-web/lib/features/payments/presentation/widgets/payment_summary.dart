import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.plan,
    this.compact = false,
  });

  final StudentPaymentPlanDto plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasPending = plan.pendingAmount > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E6E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        AppStrings.paymentSummary,
                        style: TextStyle(
                          color: Brand.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 15 : 17,
                        ),
                      ),
                      if (hasPending) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFECACA),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            AppStrings.pending,
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PaymentStatusBadge(
                  status: plan.status,
                  label: plan.statusLabel,
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 580;
                final tiles = [
                  _SummaryStatTile(
                    label: AppStrings.totalAmount,
                    value: formatRupee(plan.totalAmount),
                    bgColor: const Color(0xFFF8FAFC),
                    borderColor: const Color(0xFFE2E8F0),
                    textColor: Brand.navy,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _SummaryStatTile(
                    label: AppStrings.paidAmount,
                    value: formatRupee(plan.paidAmount),
                    bgColor: const Color(0xFFF0FDF4),
                    borderColor: const Color(0xFFBBF7D0),
                    textColor: const Color(0xFF16A34A),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  _SummaryStatTile(
                    label: AppStrings.pendingAmount,
                    value: formatRupee(plan.pendingAmount),
                    bgColor: hasPending
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    borderColor: hasPending
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFBBF7D0),
                    textColor: hasPending
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                    isHighlighted: hasPending,
                    icon: hasPending
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (int i = 0; i < tiles.length; i++) ...[
                        Expanded(child: tiles[i]),
                        if (i < tiles.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i < tiles.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F1EF)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DetailItem(
                  label: AppStrings.paymentPlan,
                  value: plan.paymentTypeLabel ??
                      (plan.paymentType == 'partial'
                          ? AppStrings.partialPayment
                          : AppStrings.fullPayment),
                ),
                if (plan.lastPaymentDate != null)
                  _DetailItem(
                    label: AppStrings.lastPaymentDate,
                    value: formatDisplayDate(plan.lastPaymentDate),
                  ),
                if (plan.nextDueDate != null)
                  _DetailItem(
                    label: AppStrings.nextDueDate,
                    value: formatDisplayDate(plan.nextDueDate),
                  ),
                if (plan.nextDueAmount != null && plan.pendingAmount > 0)
                  _DetailItem(
                    label: AppStrings.nextDueAmount,
                    value: formatRupee(plan.nextDueAmount!),
                    accent: const Color(0xFFDC2626),
                  ),
                if (plan.overdueAmount > 0)
                  _DetailItem(
                    label: AppStrings.overdueAmount,
                    value: formatRupee(plan.overdueAmount),
                    accent: const Color(0xFFB91C1C),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: isHighlighted
                        ? const Color(0xFFDC2626)
                        : Brand.muted,
                    fontSize: 10.5,
                    fontWeight: isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
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

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Brand.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: accent ?? Brand.navy,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
