import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Real UPI collect details for enrolment payments.
abstract final class EnrolmentPaymentQr {
  static const payeeName = 'Munish Sharma';
  static const upiId = '8198050505@tlaxis';
  static const founderLine = 'Co-founder · Munish Sharma';

  static String payload({double? amount}) {
    final params = <String, String>{
      'pa': upiId,
      'pn': payeeName,
      'cu': 'INR',
      if (amount != null && amount > 0) 'am': amount.toStringAsFixed(2),
    };
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return 'upi://pay?$query';
  }
}

Future<bool> showEnrolmentPaymentQrPopup(
  BuildContext context, {
  double? amount,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x990B1F33),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PaymentQrCard(
                amount: amount,
                onClose: () => Navigator.of(dialogContext).pop(false),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    AppStrings.paymentDone,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}

class _PaymentQrCard extends StatelessWidget {
  const _PaymentQrCard({
    required this.onClose,
    this.amount,
  });

  final VoidCallback onClose;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFCF7),
              Color(0xFFF7F1E6),
              Color(0xFFF3EADF),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
          border: Border.all(color: const Color(0xFFE8DFD0)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _SoftGrainPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const AppLogo(height: 54),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.excellentEducators,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Brand.navy.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFEDE6DA)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          EnrolmentPaymentQr.payeeName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Brand.goldDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${AppStrings.upiId}: ${EnrolmentPaymentQr.upiId}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Brand.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (amount != null && amount! > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            formatRupee(amount!),
                            style: const TextStyle(
                              color: Brand.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8E2D6)),
                          ),
                          child: QrImageView(
                            data: EnrolmentPaymentQr.payload(amount: amount),
                            version: QrVersions.auto,
                            size: 210,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF1A1A1A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          AppStrings.scanAndPayUsingAnyUpiApp,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Brand.muted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 36,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    EnrolmentPaymentQr.founderLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Brand.navy.withValues(alpha: 0.58),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: AppStrings.close,
                onPressed: onClose,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  foregroundColor: Brand.navy,
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A8A7355)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width * 0.5, size.height * 0.42);
    for (var i = 1; i <= 8; i++) {
      canvas.drawCircle(center, 28.0 * i, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
