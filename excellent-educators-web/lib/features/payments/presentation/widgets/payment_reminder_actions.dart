import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentReminderActions extends ConsumerWidget {
  const PaymentReminderActions({
    super.key,
    required this.studentId,
    this.phone,
    this.compact = false,
  });

  final String studentId;
  final String? phone;
  final bool compact;

  Future<void> _whatsApp(BuildContext context, WidgetRef ref) async {
    try {
      final reminder =
          await ref.read(paymentRepositoryProvider).reminder(studentId);
      final url = reminder.whatsappUrl;
      if (url == null || url.isEmpty) {
        if (context.mounted) {
          showFailure(context, AppStrings.noWhatsappNumberAvailable);
        }
        return;
      }
      await launchUrl(Uri.parse(url), webOnlyWindowName: AppStrings.blank);
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  Future<void> _call(BuildContext context) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      showFailure(context, AppStrings.noPhoneNumberAvailable);
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: digits));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: AppStrings.whatsappReminder,
            onPressed: () => _whatsApp(context, ref),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            iconSize: 17,
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF128C7E),
              backgroundColor: const Color(0xFFE8F5E9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFA5D6A7), width: 0.8),
              ),
            ),
            icon: const Icon(Icons.chat_outlined),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: AppStrings.callStudent,
            onPressed: () => _call(context),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            iconSize: 17,
            style: IconButton.styleFrom(
              foregroundColor: Brand.navy,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
              ),
            ),
            icon: const Icon(Icons.call_outlined),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _whatsApp(context, ref),
          icon: const Icon(Icons.chat_outlined, size: 16),
          label: const Text(AppStrings.whatsappReminder),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF128C7E),
            backgroundColor: const Color(0xFFE8F5E9),
            side: const BorderSide(color: Color(0xFFA5D6A7), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _call(context),
          icon: const Icon(Icons.call_outlined, size: 16),
          label: const Text(AppStrings.callStudent),
          style: OutlinedButton.styleFrom(
            foregroundColor: Brand.navy,
            backgroundColor: const Color(0xFFF1F5F9),
            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
