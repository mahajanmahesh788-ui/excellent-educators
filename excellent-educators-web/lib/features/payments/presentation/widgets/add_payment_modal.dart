import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
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
  final amount = TextEditingController(
    text: suggestedAmount != null && suggestedAmount > 0
        ? suggestedAmount.round().toString()
        : '',
  );
  final notes = TextEditingController();
  var mode = 'offline';
  var saving = false;
  String? deltaMessage;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(AppStrings.addPayment),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (totalAmount != null || pendingAmount != null) ...[
                      Text(
                        [
                          if (totalAmount != null)
                            '${AppStrings.totalAmount}: ${formatRupee(totalAmount)}',
                          if (pendingAmount != null)
                            '${AppStrings.pendingAmount}: ${formatRupee(pendingAmount)}',
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
                      controller: amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: '${AppStrings.paymentAmount} *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: 'offline',
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => mode = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notesOptional,
                      ),
                    ),
                    if (deltaMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        deltaMessage!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final parsed = double.tryParse(amount.text.trim());
                        if (parsed == null || parsed <= 0) {
                          showFailure(
                            context,
                            AppStrings.enterAValidAmount,
                          );
                          return;
                        }
                        if (pendingAmount != null &&
                            parsed > pendingAmount + 0.001) {
                          showFailure(
                            context,
                            AppStrings.onlyAmountLeft(
                              formatRupee(pendingAmount),
                            ),
                          );
                          return;
                        }
                        setState(() => saving = true);
                        try {
                          final result = await ref
                              .read(paymentRepositoryProvider)
                              .recordPayment(studentId, {
                            'amount': parsed,
                            'payment_mode': mode,
                            'notes': notes.text.trim().isEmpty
                                ? null
                                : notes.text.trim(),
                          });
                          setState(() {
                            deltaMessage =
                                '${AppStrings.previousPending}: ${formatRupee(result.previousPending)}\n'
                                '${AppStrings.paymentReceived}: ${formatRupee(result.paymentReceived)}\n'
                                '${AppStrings.newPending}: ${formatRupee(result.newPending)}';
                          });
                          await Future<void>.delayed(
                            const Duration(milliseconds: 700),
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        } catch (error) {
                          if (context.mounted) {
                            showFailure(context, error);
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => saving = false);
                          }
                        }
                      },
                child: Text(saving ? AppStrings.saving : AppStrings.save),
              ),
            ],
          );
        },
      );
    },
  );

  amount.dispose();
  notes.dispose();
  return saved == true;
}
