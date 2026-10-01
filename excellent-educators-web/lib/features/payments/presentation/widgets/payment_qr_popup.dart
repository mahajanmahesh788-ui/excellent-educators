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
      final isMobile = MediaQuery.sizeOf(dialogContext).width < 600;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SingleChildScrollView(
            child: _PaymentQrCard(
              amount: amount,
              isMobile: isMobile,
              onClose: () => Navigator.of(dialogContext).pop(false),
              onPaymentDone: () => Navigator.of(dialogContext).pop(true),
            ),
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
    required this.onPaymentDone,
    this.amount,
    this.isMobile = false,
  });

  final VoidCallback onClose;
  final VoidCallback onPaymentDone;
  final double? amount;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
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
              padding: EdgeInsets.fromLTRB(
                isMobile ? 18 : 22,
                isMobile ? 14 : 18,
                isMobile ? 18 : 22,
                isMobile ? 18 : 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: isMobile ? 4 : 8),
                  AppLogo(height: isMobile ? 44 : 54),
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    AppStrings.excellentEducators,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Brand.navy.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 16 : 18,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 18),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 18,
                      isMobile ? 14 : 20,
                      isMobile ? 14 : 18,
                      isMobile ? 14 : 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
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
                            fontSize: isMobile ? 19 : 22,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.upiId}: ${EnrolmentPaymentQr.upiId}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Brand.muted,
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (amount != null && amount! > 0) ...[
                          SizedBox(height: isMobile ? 6 : 10),
                          Text(
                            formatRupee(amount!),
                            style: TextStyle(
                              color: Brand.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 18 : 20,
                            ),
                          ),
                        ],
                        SizedBox(height: isMobile ? 10 : 16),
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                            border: Border.all(color: const Color(0xFFE8E2D6)),
                          ),
                          child: QrImageView(
                            data: EnrolmentPaymentQr.payload(amount: amount),
                            version: QrVersions.auto,
                            size: isMobile ? 170 : 210,
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
                        SizedBox(height: isMobile ? 10 : 14),
                        Text(
                          AppStrings.scanAndPayUsingAnyUpiApp,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Brand.muted,
                            fontSize: isMobile ? 11.5 : 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 14 : 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Brand.navy,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 13 : 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      onPressed: onPaymentDone,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text(
                        AppStrings.paymentDone,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 10 : 14),
                  Container(
                    width: 32,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: Brand.gold.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    EnrolmentPaymentQr.founderLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Brand.navy.withValues(alpha: 0.58),
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      fontStyle: FontStyle.italic,
                      height: 1.25,
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
                  minimumSize: const Size(36, 36),
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
