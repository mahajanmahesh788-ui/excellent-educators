import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentHistoryList extends StatefulWidget {
  const PaymentHistoryList({
    super.key,
    required this.payments,
    this.pendingAmount,
    this.showReceipt = true,
  });

  final List<StudentPaymentDto> payments;
  final double? pendingAmount;
  final bool showReceipt;

  @override
  State<PaymentHistoryList> createState() => _PaymentHistoryListState();
}

class _PaymentHistoryListState extends State<PaymentHistoryList> {
  var _expanded = false;

  List<StudentPaymentDto> get _ordered {
    final items = List<StudentPaymentDto>.from(widget.payments);
    items.sort((a, b) {
      final aDate = a.paymentDate ?? '';
      final bDate = b.paymentDate ?? '';
      final byDate = bDate.compareTo(aDate);
      if (byDate != 0) {
        return byDate;
      }
      return b.id.compareTo(a.id);
    });
    return items;
  }

  Widget _buildHeader({required bool canExpand}) {
    final pending = widget.pendingAmount;
    final hasPending = pending != null && pending > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              AppStrings.paymentHistory,
              style: TextStyle(
                color: Brand.navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          if (hasPending) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFECACA), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${AppStrings.pendingAmount}: ${formatRupee(pending)}',
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (pending != null && pending <= 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: Color(0xFF16A34A),
                  ),
                  SizedBox(width: 5),
                  Text(
                    AppStrings.paid,
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canExpand) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: _expanded
                  ? AppStrings.showLess
                  : AppStrings.showAllHistory,
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered;
    final canExpand = ordered.length > 1;

    if (ordered.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E6E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(canExpand: false),
            const Divider(height: 1, color: Color(0xFFE8E6E0)),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  AppStrings.noPaymentHistoryYet,
                  style: TextStyle(color: Brand.muted),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final latest = ordered.first;
    final older = ordered.skip(1).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E6E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(canExpand: canExpand),
          const Divider(height: 1, color: Color(0xFFE8E6E0)),
          _PaymentHistoryTile(
            payment: latest,
            showReceipt: widget.showReceipt,
          ),
          if (_expanded && older.isNotEmpty) ...[
            for (final payment in older) ...[
              const Divider(height: 1, color: Color(0xFFE8E6E0)),
              _PaymentHistoryTile(
                payment: payment,
                showReceipt: widget.showReceipt,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  const _PaymentHistoryTile({
    required this.payment,
    required this.showReceipt,
  });

  final StudentPaymentDto payment;
  final bool showReceipt;

  @override
  Widget build(BuildContext context) {
    final mode = payment.paymentMode == null
        ? '—'
        : payment.paymentMode == 'online'
            ? AppStrings.online
            : AppStrings.offline;
    final note = payment.notes?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final dateStr = formatDisplayDateTime(payment.createdAt ?? payment.paymentDate);
    final line = [
      dateStr,
      formatRupee(payment.amount),
      mode,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PaymentStatusBadge(
                status: _historyTagStatus,
                label: _historyTagLabel,
              ),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 4),
            Text(
              '${AppStrings.note}: $note',
              style: const TextStyle(
                color: Brand.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          if (showReceipt &&
              payment.receiptUrl != null &&
              payment.receiptUrl!.isNotEmpty) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(payment.receiptUrl!),
                webOnlyWindowName: AppStrings.blank,
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text(AppStrings.viewReceipt),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _historyTagStatus {
    switch (payment.status) {
      case 'successful':
      case 'paid':
        return 'paid';
      case 'pending':
        return 'pending';
      default:
        return payment.status;
    }
  }

  String get _historyTagLabel {
    switch (payment.status) {
      case 'successful':
      case 'paid':
        return AppStrings.paid;
      case 'pending':
        return AppStrings.pending;
      default:
        return payment.statusLabel ?? payment.status;
    }
  }
}
