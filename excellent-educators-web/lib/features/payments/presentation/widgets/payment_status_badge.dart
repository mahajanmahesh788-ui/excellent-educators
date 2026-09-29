import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status, this.label});

  final String status;
  final String? label;

  Color get _color {
    switch (status) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'partial':
        return const Color(0xFFEF6C00);
      case 'overdue':
        return const Color(0xFFC62828);
      case 'pending':
        return const Color(0xFFF9A825);
      case 'successful':
        return const Color(0xFF2E7D32);
      case 'failed':
        return const Color(0xFFC62828);
      case 'refunded':
        return const Color(0xFF546E7A);
      default:
        return Brand.muted;
    }
  }

  String get _text {
    if (label != null && label!.isNotEmpty) {
      return label!;
    }
    switch (status) {
      case 'paid':
        return AppStrings.paid;
      case 'partial':
        return AppStrings.partialPayment;
      case 'overdue':
        return AppStrings.overdue;
      case 'pending':
        return AppStrings.pending;
      case 'successful':
        return AppStrings.successful;
      case 'failed':
        return AppStrings.failed;
      case 'refunded':
        return AppStrings.refunded;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

String formatRupee(num amount) {
  final value = amount.round();
  final digits = value.toString();
  final buffer = StringBuffer('₹');
  final len = digits.length;
  if (len <= 3) {
    buffer.write(digits);
    return buffer.toString();
  }
  final last3 = digits.substring(len - 3);
  var rest = digits.substring(0, len - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) {
    parts.insert(0, rest);
  }
  buffer.write(parts.join(','));
  buffer.write(',');
  buffer.write(last3);
  return buffer.toString();
}
