import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_confirm_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/phone_whatsapp_address_fields.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/payments/data/dto/generated_bill_dto.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_plan_form.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_qr_popup.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt_actions.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminGenerateBillsPanel extends ConsumerStatefulWidget {
  const AdminGenerateBillsPanel({super.key});

  @override
  ConsumerState<AdminGenerateBillsPanel> createState() =>
      _AdminGenerateBillsPanelState();
}

class _AdminGenerateBillsPanelState
    extends ConsumerState<AdminGenerateBillsPanel> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({GeneratedBillDto? bill}) async {
    final saved = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => _GenerateBillDialog(bill: bill),
    );
    if (saved == true && mounted) {
      ref.invalidate(generatedBillsProvider);
    }
  }

  Future<void> _delete(GeneratedBillDto bill) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete bill?',
      message:
          'Delete bill ${bill.billNumber} for ${bill.fullName}? This cannot be undone.',
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(paymentRepositoryProvider).deleteGeneratedBill(bill.id);
      ref.invalidate(generatedBillsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill deleted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _openReceipt(GeneratedBillDto bill) async {
    final data = generatedBillToReceiptData(bill);
    await showPaymentReceiptActions(
      context,
      data: data,
      repository: ref.read(paymentRepositoryProvider),
      persistAsAdmin: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(generatedBillsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Search name, phone, bill no…',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref.read(generatedBillsSearchProvider.notifier).state = value;
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Generate bill'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter student details and payment info to generate a bill without creating a student account.',
          style: TextStyle(color: Brand.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AsyncBody(
            value: bills,
            onRetry: () => ref.invalidate(generatedBillsProvider),
            builder: (items) {
              if (items.isEmpty) {
                return const EmptyHint(
                  'No bills yet',
                  subtitle:
                      'Generate a bill using the same details as enrol a student.',
                  icon: Icons.receipt_long_outlined,
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final bill = items[index];
                  return _BillCard(
                    bill: bill,
                    onEdit: () => _openForm(bill: bill),
                    onDelete: () => _delete(bill),
                    onReceipt: () => _openReceipt(bill),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.onEdit,
    required this.onDelete,
    required this.onReceipt,
  });

  final GeneratedBillDto bill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E2D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.fullName,
                        style: const TextStyle(
                          color: Brand.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bill.billNumber} · Class ${bill.classGrade}',
                        style: const TextStyle(
                          color: Brand.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                PaymentStatusBadge(
                  status: bill.pendingAmount <= 0 ? 'paid' : 'pending',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _MetaChip(
                  icon: Icons.payments_outlined,
                  label: formatRupee(bill.totalAmount),
                ),
                _MetaChip(
                  icon: Icons.check_circle_outline,
                  label: 'Paid ${formatRupee(bill.paidAmount)}',
                ),
                _MetaChip(
                  icon: Icons.phone_outlined,
                  label: bill.phone,
                ),
                if ((bill.billDate ?? '').isNotEmpty)
                  _MetaChip(
                    icon: Icons.event_outlined,
                    label: formatDisplayDate(bill.billDate),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onReceipt,
                  icon: const Icon(Icons.receipt_outlined, size: 18),
                  label: const Text('Receipt'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: AppStrings.edit,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: AppStrings.delete,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFF9A3F3F),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Brand.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Brand.navy,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _GenerateBillDialog extends ConsumerStatefulWidget {
  const _GenerateBillDialog({this.bill});

  final GeneratedBillDto? bill;

  @override
  ConsumerState<_GenerateBillDialog> createState() =>
      _GenerateBillDialogState();
}

class _GenerateBillDialogState extends ConsumerState<_GenerateBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paymentForm = PaymentPlanFormController();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _address;
  late final TextEditingController _email;
  late final TextEditingController _guardianName;
  late final TextEditingController _guardianPhone;
  int? _classGrade;
  String? _gender;
  var _saving = false;

  bool get _editing => widget.bill != null;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _name = TextEditingController(text: bill?.fullName ?? '');
    _phone = TextEditingController(text: bill?.phone ?? '');
    _whatsapp = TextEditingController(text: bill?.whatsappNumber ?? '');
    _address = TextEditingController(text: bill?.address ?? '');
    _email = TextEditingController(text: bill?.email ?? '');
    _guardianName = TextEditingController(text: bill?.guardianName ?? '');
    _guardianPhone = TextEditingController(text: bill?.guardianPhone ?? '');
    _classGrade = bill?.classGrade;
    _gender = bill?.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _email.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _classGrade == null ||
        _gender == null) {
      return;
    }
    final payment = _paymentForm.toPayload();
    if (payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a payment plan.')),
      );
      return;
    }

    final preferredMode = payment['preferred_mode']?.toString();
    final total = _paymentForm.totalAmount ?? 0;
    final paid = _paymentForm.paidAmount ?? 0;
    if (preferredMode == 'online' && !_editing) {
      final confirmed = await showEnrolmentPaymentQrPopup(
        context,
        amount: paid > 0 ? paid : total,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'whatsapp_number':
            _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'class_grade': _classGrade,
        'gender': _gender,
        'guardian_name': _guardianName.text.trim().isEmpty
            ? null
            : _guardianName.text.trim(),
        'guardian_phone': _guardianPhone.text.trim().isEmpty
            ? null
            : _guardianPhone.text.trim(),
        'payment_type': payment['payment_type'],
        'payment_mode': preferredMode ?? 'offline',
        'total_amount': total,
        'paid_amount': paid,
        'notes': payment['notes'],
      };

      final repo = ref.read(paymentRepositoryProvider);
      final bill = _editing
          ? await repo.updateGeneratedBill(widget.bill!.id, payload)
          : await repo.createGeneratedBill(payload);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      await showPaymentReceiptActions(
        context,
        data: generatedBillToReceiptData(bill),
        repository: repo,
        persistAsAdmin: false,
      );
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
    final maxWidth = width < 720 ? width - 24.0 : 640.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? 'Edit bill' : 'Generate bill',
                      style: const TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Same details as enrol a student — generates a bill only, no student login.',
                  style: TextStyle(color: Brand.muted, height: 1.35),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        key: ValueKey(_classGrade),
                        value: _classGrade,
                        decoration: const InputDecoration(
                          labelText: AppStrings.classLabel,
                        ),
                        items: [
                          for (final grade in [5, 6, 7, 8, 9, 10, 11, 12])
                            DropdownMenuItem(
                              value: grade,
                              child: Text('Class $grade'),
                            ),
                        ],
                        validator: (value) => value == null
                            ? AppStrings.pleaseSelectAClass
                            : null,
                        onChanged: (value) =>
                            setState(() => _classGrade = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: AppStrings.fullName,
                        ),
                        validator: validateRequired,
                      ),
                      const SizedBox(height: 12),
                      GenderDropdown(
                        value: _gender,
                        onChanged: (value) => setState(() => _gender = value),
                      ),
                      const SizedBox(height: 12),
                      PhoneWhatsappAddressFields(
                        phone: _phone,
                        whatsapp: _whatsapp,
                        address: _address,
                        addressHint: AppStrings.enterStudentAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                        ),
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) {
                            return null;
                          }
                          if (!raw.contains('@')) {
                            return AppStrings.enterAValidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _guardianName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: AppStrings.guardianNameOptional,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _guardianPhone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: AppStrings.guardianPhoneOptional,
                          prefixText: '+91  ',
                        ),
                        validator: validateOptionalPhone,
                      ),
                      const SizedBox(height: 20),
                      PaymentPlanFormFields(
                        controller: _paymentForm,
                        initialType: widget.bill?.paymentType,
                        initialMode: widget.bill?.paymentMode,
                        initialPaidAmount: widget.bill?.paidAmount,
                        initialNotes: widget.bill?.notes,
                        overrideTotalAmount: widget.bill?.totalAmount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text(AppStrings.cancel),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _editing
                                ? Icons.save_rounded
                                : Icons.receipt_long_rounded,
                          ),
                    label: Text(_editing ? 'Save bill' : 'Generate bill'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

PaymentReceiptData generatedBillToReceiptData(GeneratedBillDto bill) {
  return PaymentReceiptData(
    payment: StudentPaymentDto(
      id: bill.billNumber,
      amount: bill.paidAmount > 0 ? bill.paidAmount : bill.totalAmount,
      status: bill.pendingAmount <= 0 ? 'paid' : 'pending',
      paymentMode: bill.paymentMode,
      paymentDate: bill.billDate ?? bill.createdAt,
      notes: bill.notes,
      statusLabel: bill.pendingAmount <= 0 ? 'Paid' : 'Pending',
    ),
    student: PaymentReceiptStudent(
      fullName: bill.fullName,
      studentCode: bill.billNumber,
      phone: bill.phone,
      email: bill.email,
      whatsappNumber: bill.whatsappNumber,
      levelName: 'Class ${bill.classGrade}',
    ),
    totalAmount: bill.totalAmount,
    paidAmount: bill.paidAmount,
    pendingAmount: bill.pendingAmount,
    paymentTypeLabel: bill.paymentTypeLabel,
  );
}
