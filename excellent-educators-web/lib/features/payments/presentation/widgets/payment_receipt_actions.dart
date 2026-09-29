import 'dart:typed_data';

import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/data/payment_repository.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showPaymentReceiptActions(
  BuildContext context, {
  required PaymentReceiptData data,
  required PaymentRepository repository,
  String? studentId,
  bool persistAsAdmin = true,
  void Function(StudentPaymentDto updated)? onReceiptUpdated,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final hasStored =
          (data.payment.receiptUrl ?? '').trim().isNotEmpty;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.paymentReceipt,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatDisplayDate(data.payment.paymentDate)} · ${formatRupee(data.payment.amount)}',
                style: const TextStyle(color: Colors.black54),
              ),
              if (hasStored) ...[
                const SizedBox(height: 6),
                Text(
                  AppStrings.receiptSaved,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text(AppStrings.viewReceipt),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _viewReceipt(
                    context,
                    data: data,
                    repository: repository,
                    studentId: studentId,
                    persistAsAdmin: persistAsAdmin,
                    onReceiptUpdated: onReceiptUpdated,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text(AppStrings.downloadReceipt),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _downloadReceipt(
                    context,
                    data: data,
                    repository: repository,
                    studentId: studentId,
                    persistAsAdmin: persistAsAdmin,
                    onReceiptUpdated: onReceiptUpdated,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined, color: Color(0xFF128C7E)),
                title: const Text(AppStrings.sendReceiptOnWhatsapp),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _whatsAppReceipt(
                    context,
                    data: data,
                    repository: repository,
                    studentId: studentId,
                    persistAsAdmin: persistAsAdmin,
                    onReceiptUpdated: onReceiptUpdated,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<({PaymentReceiptData data, Uint8List bytes})> _prepareReceipt(
  BuildContext context, {
  required PaymentReceiptData data,
  required PaymentRepository repository,
  String? studentId,
  required bool persistAsAdmin,
  void Function(StudentPaymentDto updated)? onReceiptUpdated,
}) async {
  final bytes = await PaymentReceiptBuilder.build(data);
  var next = data;

  try {
    final filename = _fileName(data);
    final updated = persistAsAdmin && studentId != null
        ? await repository.uploadAdminPaymentReceipt(
            studentId: studentId,
            paymentId: data.payment.id,
            bytes: bytes,
            filename: filename,
          )
        : await repository.uploadOwnPaymentReceipt(
            paymentId: data.payment.id,
            bytes: bytes,
            filename: filename,
          );
    next = data.copyWith(payment: updated);
    onReceiptUpdated?.call(updated);
  } catch (_) {
    // Viewing/downloading still works offline even if persist fails.
  }

  return (data: next, bytes: bytes);
}

Future<void> _viewReceipt(
  BuildContext context, {
  required PaymentReceiptData data,
  required PaymentRepository repository,
  String? studentId,
  required bool persistAsAdmin,
  void Function(StudentPaymentDto updated)? onReceiptUpdated,
}) async {
  try {
    final prepared = await _prepareReceipt(
      context,
      data: data,
      repository: repository,
      studentId: studentId,
      persistAsAdmin: persistAsAdmin,
      onReceiptUpdated: onReceiptUpdated,
    );
    if (!context.mounted) {
      return;
    }

    final storedUrl = (prepared.data.payment.receiptUrl ?? '').trim();
    if (storedUrl.isNotEmpty) {
      final uri = Uri.parse(storedUrl);
      final cacheBustedUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'v': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final opened = await launchUrl(
        cacheBustedUri,
        webOnlyWindowName: AppStrings.blank,
      );
      if (opened) {
        return;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 720,
            height: MediaQuery.sizeOf(dialogContext).height * 0.85,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          AppStrings.paymentReceipt,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.downloadReceipt,
                        onPressed: () => Printing.sharePdf(
                          bytes: prepared.bytes,
                          filename: _fileName(prepared.data),
                        ),
                        icon: const Icon(Icons.download_outlined),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PdfPreview(
                    build: (_) async => prepared.bytes,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowPrinting: true,
                    allowSharing: true,
                    pdfFileName: _fileName(prepared.data),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } catch (error) {
    if (context.mounted) {
      showFailure(context, error);
    }
  }
}

Future<void> _downloadReceipt(
  BuildContext context, {
  required PaymentReceiptData data,
  required PaymentRepository repository,
  String? studentId,
  required bool persistAsAdmin,
  void Function(StudentPaymentDto updated)? onReceiptUpdated,
}) async {
  try {
    final prepared = await _prepareReceipt(
      context,
      data: data,
      repository: repository,
      studentId: studentId,
      persistAsAdmin: persistAsAdmin,
      onReceiptUpdated: onReceiptUpdated,
    );
    await Printing.sharePdf(
      bytes: prepared.bytes,
      filename: _fileName(prepared.data),
    );
  } catch (error) {
    if (context.mounted) {
      showFailure(context, error);
    }
  }
}

Future<void> _whatsAppReceipt(
  BuildContext context, {
  required PaymentReceiptData data,
  required PaymentRepository repository,
  String? studentId,
  required bool persistAsAdmin,
  void Function(StudentPaymentDto updated)? onReceiptUpdated,
}) async {
  try {
    // Persist receipt so it is available when the student downloads from Settings.
    final prepared = await _prepareReceipt(
      context,
      data: data,
      repository: repository,
      studentId: studentId,
      persistAsAdmin: persistAsAdmin,
      onReceiptUpdated: onReceiptUpdated,
    );

    final digits = (prepared.data.student.whatsappNumber ??
            prepared.data.student.phone ??
            '')
        .replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (context.mounted) {
        showFailure(context, AppStrings.noWhatsappNumberAvailable);
      }
      return;
    }

    final phone = digits.length == 10 ? '91$digits' : digits;
    final studentName = prepared.data.student.fullName;
    final amount = formatRupee(prepared.data.payment.amount);
    final date = formatDisplayDate(
      prepared.data.payment.createdAt ?? prepared.data.payment.paymentDate,
    );
    final receiptNo = prepared.data.receiptNo;

    final message = Uri.encodeComponent(
      'Dear $studentName,\n\n'
      'Greetings from ${AppStrings.excellentEducators}.\n\n'
      'We are pleased to confirm that we have successfully received your payment.\n\n'
      'Payment details:\n'
      '• ${AppStrings.receiptNo}: $receiptNo\n'
      '• ${AppStrings.paymentAmount}: $amount\n'
      '• ${AppStrings.paymentDate}: $date\n\n'
      'Thank you for your payment and for trusting ${AppStrings.excellentEducators}.\n\n'
      '${AppStrings.whatsappReceiptDownloadHint}\n\n'
      'Warm regards,\n'
      '${AppStrings.excellentEducators}',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    await launchUrl(uri, webOnlyWindowName: AppStrings.blank);
  } catch (error) {
    if (context.mounted) {
      showFailure(context, error);
    }
  }
}

String _fileName(PaymentReceiptData data) {
  final rawDate =
      data.payment.createdAt ?? data.payment.paymentDate;
  final parsed = DateTime.tryParse(rawDate ?? '');
  final month = parsed == null
      ? 'Unknown'
      : _fullMonthName(parsed.toLocal().month);
  final safeName = data.student.fullName
      .trim()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^A-Za-z0-9\-]+'), '')
      .replaceAll(RegExp(r'^-|-$'), '');
  final name = safeName.isEmpty ? 'Student' : safeName;
  return 'EE-Receipt-${data.receiptNo}_$month-$name.pdf';
}

String _fullMonthName(int month) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  if (month < 1 || month > 12) {
    return 'Unknown';
  }
  return months[month - 1];
}

/// Generates and stores a receipt PDF after a payment is recorded.
Future<StudentPaymentDto?> persistPaymentReceipt({
  required PaymentRepository repository,
  required PaymentReceiptData data,
  String? studentId,
  bool persistAsAdmin = true,
}) async {
  final bytes = await PaymentReceiptBuilder.build(data);
  final filename = _fileName(data);
  if (persistAsAdmin && studentId != null) {
    return repository.uploadAdminPaymentReceipt(
      studentId: studentId,
      paymentId: data.payment.id,
      bytes: bytes,
      filename: filename,
    );
  }
  return repository.uploadOwnPaymentReceipt(
    paymentId: data.payment.id,
    bytes: bytes,
    filename: filename,
  );
}
