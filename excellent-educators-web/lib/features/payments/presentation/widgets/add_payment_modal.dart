import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt_actions.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> showAddPaymentModal(
  BuildContext context,
  WidgetRef ref, {
  required String studentId,
  double? suggestedAmount,
  double? totalAmount,
  double? pendingAmount,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _AddPaymentDialog(
        studentId: studentId,
        suggestedAmount: suggestedAmount,
        totalAmount: totalAmount,
        pendingAmount: pendingAmount,
      );
    },
  );
  return saved == true;
}

class _AddPaymentDialog extends ConsumerStatefulWidget {
  const _AddPaymentDialog({
    required this.studentId,
    this.suggestedAmount,
    this.totalAmount,
    this.pendingAmount,
  });

  final String studentId;
  final double? suggestedAmount;
  final double? totalAmount;
  final double? pendingAmount;

  @override
  ConsumerState<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<_AddPaymentDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  var _mode = 'offline';
  var _saving = false;
  String? _deltaMessage;

  @override
  void initState() {
    super.initState();
    final suggested = widget.suggestedAmount;
    _amount = TextEditingController(
      text: suggested != null && suggested > 0
          ? suggested.round().toString()
          : '',
    );
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final parsed = double.tryParse(_amount.text.trim());
    if (parsed == null || parsed <= 0) {
      showFailure(context, AppStrings.enterAValidAmount);
      return;
    }
    final pending = widget.pendingAmount;
    if (pending != null && parsed > pending + 0.001) {
      showFailure(
        context,
        AppStrings.onlyAmountLeft(formatRupee(pending)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final result = await repo.recordPayment(widget.studentId, {
        'amount': parsed,
        'payment_mode': _mode,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      try {
        await persistPaymentReceipt(
          repository: repo,
          studentId: widget.studentId,
          persistAsAdmin: true,
          data: PaymentReceiptData(
            payment: result.payment,
            student: PaymentReceiptStudent.fromPlanRef(result.plan.student),
            totalAmount: result.plan.totalAmount,
            paidAmount: result.plan.paidAmount,
            pendingAmount: result.plan.pendingAmount,
            paymentTypeLabel: result.plan.paymentTypeLabel,
          ),
        );
      } catch (_) {
        // Payment already saved; receipt can be stored later from history.
      }

      if (!mounted) return;
      setState(() {
        _deltaMessage =
            '${AppStrings.previousPending}: ${formatRupee(result.previousPending)}\n'
            '${AppStrings.paymentReceived}: ${formatRupee(result.paymentReceived)}\n'
            '${AppStrings.newPending}: ${formatRupee(result.newPending)}';
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.addPayment),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.totalAmount != null || widget.pendingAmount != null) ...[
                Text(
                  [
                    if (widget.totalAmount != null)
                      '${AppStrings.totalAmount}: ${formatRupee(widget.totalAmount!)}',
                    if (widget.pendingAmount != null)
                      '${AppStrings.pendingAmount}: ${formatRupee(widget.pendingAmount!)}',
                  ].join('  ·  '),
                  style: const TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _amount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '${AppStrings.paymentAmount} *',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _mode,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.paymentMode} *',
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
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _mode = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                enabled: !_saving,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: AppStrings.notesOptional,
                ),
              ),
              if (_deltaMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _deltaMessage!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? AppStrings.saving : AppStrings.save),
        ),
      ],
    );
  }
}
