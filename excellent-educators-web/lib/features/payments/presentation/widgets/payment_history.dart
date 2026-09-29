import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/data/payment_repository.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt_actions.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';

class PaymentHistoryList extends StatefulWidget {
  const PaymentHistoryList({
    super.key,
    required this.payments,
    this.pendingAmount,
    this.showReceipt = true,
    this.receiptStudent,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.paymentTypeLabel,
    this.repository,
    this.studentId,
    this.persistAsAdmin = true,
    this.onReceiptUpdated,
  });

  final List<StudentPaymentDto> payments;
  final double? pendingAmount;
  final bool showReceipt;
  final PaymentReceiptStudent? receiptStudent;
  final double totalAmount;
  final double paidAmount;
  final String? paymentTypeLabel;
  final PaymentRepository? repository;
  final String? studentId;
  final bool persistAsAdmin;
  final VoidCallback? onReceiptUpdated;

  @override
  State<PaymentHistoryList> createState() => _PaymentHistoryListState();
}

class _PaymentHistoryListState extends State<PaymentHistoryList> {
  var _expanded = false;
  late Map<String, StudentPaymentDto> _overrides;

  @override
  void initState() {
    super.initState();
    _overrides = {};
  }

  @override
  void didUpdateWidget(covariant PaymentHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.payments, widget.payments)) {
      _overrides = {};
    }
  }

  List<StudentPaymentDto> get _ordered {
    final items = widget.payments
        .map((payment) => _overrides[payment.id] ?? payment)
        .toList();
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

  void _handleReceiptUpdated(StudentPaymentDto updated) {
    setState(() => _overrides[updated.id] = updated);
    widget.onReceiptUpdated?.call();
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
            receiptStudent: widget.receiptStudent,
            totalAmount: widget.totalAmount,
            paidAmount: widget.paidAmount,
            pendingAmount: widget.pendingAmount ?? 0,
            paymentTypeLabel: widget.paymentTypeLabel,
            repository: widget.repository,
            studentId: widget.studentId,
            persistAsAdmin: widget.persistAsAdmin,
            onReceiptUpdated: _handleReceiptUpdated,
          ),
          if (_expanded && older.isNotEmpty) ...[
            for (final payment in older) ...[
              const Divider(height: 1, color: Color(0xFFE8E6E0)),
              _PaymentHistoryTile(
                payment: payment,
                showReceipt: false,
                receiptStudent: widget.receiptStudent,
                totalAmount: widget.totalAmount,
                paidAmount: widget.paidAmount,
                pendingAmount: widget.pendingAmount ?? 0,
                paymentTypeLabel: widget.paymentTypeLabel,
                repository: widget.repository,
                studentId: widget.studentId,
                persistAsAdmin: widget.persistAsAdmin,
                onReceiptUpdated: _handleReceiptUpdated,
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
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.persistAsAdmin,
    this.receiptStudent,
    this.paymentTypeLabel,
    this.repository,
    this.studentId,
    this.onReceiptUpdated,
  });

  final StudentPaymentDto payment;
  final bool showReceipt;
  final PaymentReceiptStudent? receiptStudent;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String? paymentTypeLabel;
  final PaymentRepository? repository;
  final String? studentId;
  final bool persistAsAdmin;
  final ValueChanged<StudentPaymentDto>? onReceiptUpdated;

  bool get _canShowReceipt {
    if (!showReceipt || receiptStudent == null || repository == null) {
      return false;
    }
    switch (payment.status) {
      case 'successful':
      case 'paid':
        return true;
      default:
        return false;
    }
  }

  bool get _hasStoredReceipt =>
      (payment.receiptUrl ?? '').trim().isNotEmpty;

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
              Text(
                '${AppStrings.receiptNo}: $_receiptNo',
                style: const TextStyle(
                  color: Brand.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              if (persistAsAdmin &&
                  studentId != null &&
                  repository != null &&
                  payment.status == 'successful')
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'void') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(AppStrings.voidPayment),
                          content: const Text(AppStrings.voidPaymentHelp),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(AppStrings.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(AppStrings.voidPayment),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) {
                        return;
                      }
                      try {
                        await repository!.voidPayment(studentId!, payment.id);
                        onReceiptUpdated?.call(payment.copyWith(status: 'failed'));
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$error')),
                          );
                        }
                      }
                    } else if (value == 'edit') {
                      final amountCtrl = TextEditingController(
                        text: payment.amount.toStringAsFixed(0),
                      );
                      final notesCtrl = TextEditingController(
                        text: payment.notes ?? '',
                      );
                      var mode = payment.paymentMode ?? 'offline';
                      final dateCtrl = TextEditingController(
                        text: (payment.paymentDate ?? '').length >= 10
                            ? payment.paymentDate!.substring(0, 10)
                            : '',
                      );
                      final saved = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) => StatefulBuilder(
                          builder: (ctx, setDialogState) => AlertDialog(
                            title: const Text(AppStrings.editPayment),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: amountCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.paymentAmount,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: mode,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.paymentMode,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'offline',
                                        child: Text(AppStrings.offline),
                                      ),
                                      DropdownMenuItem(
                                        value: 'online',
                                        child: Text(AppStrings.online),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setDialogState(() => mode = value);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: dateCtrl,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.paymentDate,
                                      hintText: 'YYYY-MM-DD',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: notesCtrl,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.notesOptional,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(AppStrings.cancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, {
                                  'amount': double.tryParse(
                                        amountCtrl.text.trim(),
                                      ) ??
                                      payment.amount,
                                  'payment_mode': mode,
                                  'payment_date': dateCtrl.text.trim().isEmpty
                                      ? null
                                      : dateCtrl.text.trim(),
                                  'notes': notesCtrl.text.trim().isEmpty
                                      ? null
                                      : notesCtrl.text.trim(),
                                }),
                                child: const Text(AppStrings.save),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (saved == null) {
                        return;
                      }
                      try {
                        await repository!.updatePayment(
                          studentId!,
                          payment.id,
                          saved,
                        );
                        onReceiptUpdated?.call(
                          payment.copyWith(
                            amount: (saved['amount'] as num?)?.toDouble() ??
                                payment.amount,
                            paymentMode: saved['payment_mode'] as String? ??
                                payment.paymentMode,
                            paymentDate: saved['payment_date'] as String? ??
                                payment.paymentDate,
                            notes: saved['notes'] as String? ?? payment.notes,
                          ),
                        );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$error')),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text(AppStrings.editPayment)),
                    PopupMenuItem(value: 'void', child: Text(AppStrings.voidPayment)),
                  ],
                ),
            ],
          ),
          if (hasNote || _canShowReceipt) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: hasNote
                      ? Text(
                          '${AppStrings.note}: $note',
                          style: const TextStyle(
                            color: Brand.muted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (_canShowReceipt) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => showPaymentReceiptActions(
                      context,
                      data: PaymentReceiptData(
                        payment: payment,
                        student: receiptStudent!,
                        totalAmount: totalAmount,
                        paidAmount: paidAmount,
                        pendingAmount: pendingAmount,
                        paymentTypeLabel: paymentTypeLabel,
                      ),
                      repository: repository!,
                      studentId: studentId,
                      persistAsAdmin: persistAsAdmin,
                      onReceiptUpdated: onReceiptUpdated,
                    ),
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 15,
                    ),
                    label: Text(
                      _hasStoredReceipt
                          ? AppStrings.receiptSaved
                          : AppStrings.receipt,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Brand.navy,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _receiptNo {
    final id = payment.id;
    if (id.isEmpty) {
      return '—';
    }
    if (id.length <= 10) {
      return id.toUpperCase();
    }
    return id.substring(id.length - 10).toUpperCase();
  }
}
