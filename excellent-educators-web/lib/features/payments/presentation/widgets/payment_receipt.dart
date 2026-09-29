import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PaymentReceiptStudent {
  const PaymentReceiptStudent({
    required this.fullName,
    this.studentCode,
    this.phone,
    this.email,
    this.whatsappNumber,
    this.levelName,
    this.batchName,
  });

  final String fullName;
  final String? studentCode;
  final String? phone;
  final String? email;
  final String? whatsappNumber;
  final String? levelName;
  final String? batchName;

  factory PaymentReceiptStudent.fromPlanRef(PaymentPlanStudentRef? ref) {
    return PaymentReceiptStudent(
      fullName: ref?.fullName ?? 'Student',
      studentCode: ref?.studentCode,
      phone: ref?.phone,
      email: ref?.email,
      whatsappNumber: ref?.whatsappNumber,
      levelName: ref?.levelName,
      batchName: ref?.batchName,
    );
  }

  factory PaymentReceiptStudent.fromStudent({
    required String fullName,
    String? studentCode,
    String? phone,
    String? email,
    String? whatsappNumber,
    String? levelName,
    String? batchName,
  }) {
    return PaymentReceiptStudent(
      fullName: fullName,
      studentCode: studentCode,
      phone: phone,
      email: email,
      whatsappNumber: whatsappNumber,
      levelName: levelName,
      batchName: batchName,
    );
  }
}

class PaymentReceiptData {
  const PaymentReceiptData({
    required this.payment,
    required this.student,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    this.paymentTypeLabel,
  });

  final StudentPaymentDto payment;
  final PaymentReceiptStudent student;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String? paymentTypeLabel;

  PaymentReceiptData copyWith({
    StudentPaymentDto? payment,
    PaymentReceiptStudent? student,
    double? totalAmount,
    double? paidAmount,
    double? pendingAmount,
    String? paymentTypeLabel,
  }) {
    return PaymentReceiptData(
      payment: payment ?? this.payment,
      student: student ?? this.student,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      paymentTypeLabel: paymentTypeLabel ?? this.paymentTypeLabel,
    );
  }

  String get receiptNo {
    final id = payment.id;
    if (id.length <= 10) {
      return id.toUpperCase();
    }
    return id.substring(id.length - 10).toUpperCase();
  }

  String get modeLabel {
    if (payment.paymentMode == 'online') {
      return AppStrings.online;
    }
    if (payment.paymentMode == 'offline') {
      return AppStrings.offline;
    }
    return '—';
  }
}

class PaymentReceiptBuilder {
  static Future<Uint8List> build(PaymentReceiptData data) async {
    final logo = await rootBundle.load(AppLogo.assetPath);
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    // Helvetica lacks ₹ — embed Noto Sans so rupee amounts and text render flawlessly.
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final italicFont = await PdfGoogleFonts.notoSansItalic();
    final boldItalicFont = await PdfGoogleFonts.notoSansBoldItalic();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: italicFont,
        boldItalic: boldItalicFont,
      ),
    );

    const primaryNavy = PdfColor.fromInt(0xFF03162B);
    const accentGold = PdfColor.fromInt(0xFFD97706);
    const textPrimary = PdfColor.fromInt(0xFF0F172A);
    const textMuted = PdfColor.fromInt(0xFF475569);
    const textSubtle = PdfColor.fromInt(0xFF64748B);
    const surfaceBg = PdfColor.fromInt(0xFFF8FAFC);
    const tableSubtotalBg = PdfColor.fromInt(0xFFF1F5F9);
    const borderLine = PdfColor.fromInt(0xFFCBD5E1);
    const successGreen = PdfColor.fromInt(0xFF15803D);
    const amberColor = PdfColor.fromInt(0xFFB45309);

    final courseParts = <String>[
      if ((data.student.levelName ?? '').trim().isNotEmpty)
        data.student.levelName!.trim(),
      if ((data.student.batchName ?? '').trim().isNotEmpty)
        data.student.batchName!.trim(),
    ];
    final course = courseParts.join(' · ');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Top Brand Color Bar
              pw.Container(
                height: 4,
                decoration: const pw.BoxDecoration(
                  color: primaryNavy,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.Container(
                height: 2,
                margin: const pw.EdgeInsets.only(top: 1.5, bottom: 14),
                decoration: const pw.BoxDecoration(
                  color: accentGold,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(1)),
                ),
              ),

              // Header Row: Organization Info & Receipt Metadata
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EXCELLENT EDUCATORS',
                          style: pw.TextStyle(
                            color: primaryNavy,
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Center for Academic Excellence & Professional Coaching',
                          style: pw.TextStyle(
                            color: textMuted,
                            fontSize: 8.5,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Certified Educational Institution · contact@excellenteducators.com',
                          style: pw.TextStyle(
                            color: textSubtle,
                            fontSize: 7.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: primaryNavy,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'FEES RECEIPT',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Receipt No: ${data.receiptNo}',
                        style: pw.TextStyle(
                          color: primaryNavy,
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date: ${formatDisplayDate(data.payment.createdAt ?? data.payment.paymentDate)}',
                        style: pw.TextStyle(
                          color: textMuted,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Container(height: 0.8, color: borderLine),
              pw.SizedBox(height: 12),

              // Student Details & Transaction Details (Two-Column Balanced Cards)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Card: Student Info
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: surfaceBg,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: borderLine, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'STUDENT INFORMATION (BILLED TO)',
                                style: pw.TextStyle(
                                  color: textMuted,
                                  fontSize: 7.2,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if ((data.student.studentCode ?? '')
                                  .isNotEmpty)
                                pw.Text(
                                  'ID: ${data.student.studentCode}',
                                  style: pw.TextStyle(
                                    color: primaryNavy,
                                    fontSize: 7.8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          pw.Container(
                            margin: const pw.EdgeInsets.symmetric(vertical: 5),
                            height: 0.5,
                            color: borderLine,
                          ),
                          pw.Text(
                            data.student.fullName,
                            style: pw.TextStyle(
                              color: primaryNavy,
                              fontSize: 11.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (course.isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            _fieldRow(
                              'Course / Class:',
                              course,
                              textMuted: textMuted,
                              primaryNavy: primaryNavy,
                            ),
                          ],
                          if ((data.student.phone ?? '').isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            _fieldRow(
                              'Phone:',
                              data.student.phone!,
                              textMuted: textMuted,
                              primaryNavy: primaryNavy,
                            ),
                          ],
                          if ((data.student.email ?? '').isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            _fieldRow(
                              'Email:',
                              data.student.email!,
                              textMuted: textMuted,
                              primaryNavy: primaryNavy,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Right Card: Transaction Details
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: surfaceBg,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: borderLine, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'TRANSACTION DETAILS',
                                style: pw.TextStyle(
                                  color: textMuted,
                                  fontSize: 7.2,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: const PdfColor.fromInt(0xFFDCFCE7),
                                  borderRadius: pw.BorderRadius.circular(3),
                                ),
                                child: pw.Text(
                                  'COMPLETED',
                                  style: pw.TextStyle(
                                    color: successGreen,
                                    fontSize: 6.8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Container(
                            margin: const pw.EdgeInsets.symmetric(vertical: 5),
                            height: 0.5,
                            color: borderLine,
                          ),
                          _fieldRow(
                            'Payment Mode:',
                            data.modeLabel,
                            boldValue: true,
                            textMuted: textMuted,
                            primaryNavy: primaryNavy,
                          ),
                          pw.SizedBox(height: 2.5),
                          _fieldRow(
                            'Date & Time:',
                            formatDisplayDateTime(
                              data.payment.createdAt ?? data.payment.paymentDate,
                            ),
                            textMuted: textMuted,
                            primaryNavy: primaryNavy,
                          ),
                          if ((data.paymentTypeLabel ?? '').isNotEmpty) ...[
                            pw.SizedBox(height: 2.5),
                            _fieldRow(
                              'Payment Plan:',
                              data.paymentTypeLabel!,
                              textMuted: textMuted,
                              primaryNavy: primaryNavy,
                            ),
                          ],
                          if ((data.payment.transactionId ?? '').isNotEmpty) ...[
                            pw.SizedBox(height: 2.5),
                            _fieldRow(
                              'Txn ID / Ref:',
                              data.payment.transactionId!,
                              textMuted: textMuted,
                              primaryNavy: primaryNavy,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // Fee Particulars Itemized Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderLine, width: 0.8),
                ),
                child: pw.Column(
                  children: [
                    // Table Header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: primaryNavy,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5.2),
                          topRight: pw.Radius.circular(5.2),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 24,
                            child: pw.Text(
                              '#',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 7.8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                              'PARTICULARS / FEE ITEM',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 7.8,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'PAYMENT MODE',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 7.8,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'PLAN / TYPE',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 7.8,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          pw.SizedBox(
                            width: 90,
                            child: pw.Text(
                              'AMOUNT PAID',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 7.8,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Item Row
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 24,
                            child: pw.Text(
                              '01',
                              style: pw.TextStyle(
                                color: textMuted,
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 5,
                            child: pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Academic Coaching & Course Tuition Fee',
                                  style: pw.TextStyle(
                                    color: primaryNavy,
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  course.isNotEmpty
                                      ? 'Course: $course'
                                      : 'Student: ${data.student.fullName}',
                                  style: pw.TextStyle(
                                    color: textMuted,
                                    fontSize: 8.0,
                                  ),
                                ),
                                if ((data.payment.notes ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  pw.SizedBox(height: 3),
                                  pw.Text(
                                    'Remarks: ${data.payment.notes!.trim()}',
                                    style: pw.TextStyle(
                                      color: textSubtle,
                                      fontSize: 7.5,
                                      fontStyle: pw.FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              data.modeLabel,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                color: textPrimary,
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              (data.paymentTypeLabel ?? '').isNotEmpty
                                  ? data.paymentTypeLabel!
                                  : 'Installment',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                color: textPrimary,
                                fontSize: 8.5,
                              ),
                            ),
                          ),
                          pw.SizedBox(
                            width: 90,
                            child: pw.Text(
                              formatRupee(data.payment.amount),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                color: primaryNavy,
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Subtotal Row
                    pw.Container(
                      height: 0.8,
                      color: borderLine,
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: tableSubtotalBg,
                        borderRadius: pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(5.2),
                          bottomRight: pw.Radius.circular(5.2),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL AMOUNT RECEIVED IN THIS RECEIPT',
                            style: pw.TextStyle(
                              color: primaryNavy,
                              fontSize: 8.2,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                          pw.Text(
                            formatRupee(data.payment.amount),
                            style: pw.TextStyle(
                              color: primaryNavy,
                              fontSize: 12.0,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),

              // Amount in Words Bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: surfaceBg,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                  border: pw.Border.all(color: borderLine, width: 0.8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Amount in Words: ',
                      style: pw.TextStyle(
                        color: textMuted,
                        fontSize: 7.8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        _amountToWords(data.payment.amount),
                        style: pw.TextStyle(
                          color: primaryNavy,
                          fontSize: 8.2,
                          fontWeight: pw.FontWeight.bold,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Fee Ledger & Account Summary Cards
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STUDENT ACCOUNT SUMMARY & FEE LEDGER',
                    style: pw.TextStyle(
                      color: primaryNavy,
                      fontSize: 7.8,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _ledgerTile(
                          title: 'TOTAL COURSE FEE',
                          amount: formatRupee(data.totalAmount),
                          caption: 'Total agreed fee structure',
                          accentColor: primaryNavy,
                          surfaceBg: surfaceBg,
                          borderLine: borderLine,
                          textMuted: textMuted,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: _ledgerTile(
                          title: 'TOTAL PAID TO DATE',
                          amount: formatRupee(data.paidAmount),
                          caption: 'Cumulative fee received',
                          accentColor: successGreen,
                          surfaceBg: surfaceBg,
                          borderLine: borderLine,
                          textMuted: textMuted,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: _ledgerTile(
                          title: 'BALANCE OUTSTANDING',
                          amount: formatRupee(data.pendingAmount),
                          caption: data.pendingAmount <= 0
                              ? '✔ Fully Settled (No Dues)'
                              : 'Payment pending',
                          accentColor: data.pendingAmount <= 0
                              ? successGreen
                              : amberColor,
                          surfaceBg: surfaceBg,
                          borderLine: borderLine,
                          textMuted: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Institutional Terms & Guidelines (Left) & Official Stamp + Signatory (Right)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Left: Terms & Conditions
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TERMS & INSTITUTIONAL GUIDELINES',
                          style: pw.TextStyle(
                            color: primaryNavy,
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _termBullet(
                          '1. This receipt is an official computer-generated fee acknowledgement issued by Excellent Educators.',
                          textSubtle,
                        ),
                        _termBullet(
                          '2. Fees once deposited are non-refundable and non-transferable under any circumstances.',
                          textSubtle,
                        ),
                        _termBullet(
                          '3. All offline/cheque transactions are subject to realization and bank settlement.',
                          textSubtle,
                        ),
                        _termBullet(
                          '4. Please preserve this receipt and quote the Receipt Number for all future academic references.',
                          textSubtle,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Support & Inquiries: accounts@excellenteducators.com | Tel: +91 98765 43210',
                          style: pw.TextStyle(
                            color: textSubtle,
                            fontSize: 6.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  // Right: Stamp & Signature Block
                  pw.Expanded(
                    flex: 4,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _companyStamp(),
                        pw.SizedBox(width: 12),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'Munish Sharma',
                              style: pw.TextStyle(
                                color: primaryNavy,
                                fontSize: 13.5,
                                fontWeight: pw.FontWeight.bold,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              width: 105,
                              height: 1,
                              color: primaryNavy,
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'MUNISH SHARMA',
                              style: pw.TextStyle(
                                color: primaryNavy,
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            pw.Text(
                              'Co-founder & Director',
                              style: pw.TextStyle(
                                color: textMuted,
                                fontSize: 7.2,
                              ),
                            ),
                            pw.Text(
                              'Excellent Educators',
                              style: pw.TextStyle(
                                color: textMuted,
                                fontSize: 6.8,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: pw.BoxDecoration(
                                color: const PdfColor.fromInt(0xFFF1F5F9),
                                borderRadius: pw.BorderRadius.circular(3),
                                border: pw.Border.all(
                                  color: borderLine,
                                  width: 0.6,
                                ),
                              ),
                              child: pw.Text(
                                'AUTHORIZED SIGNATORY',
                                style: pw.TextStyle(
                                  color: primaryNavy,
                                  fontSize: 5.8,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Page Footer Bar
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 5),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: borderLine, width: 0.6),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Excellent Educators · Dedicated to Academic Distinction & Student Success',
                      style: pw.TextStyle(color: textSubtle, fontSize: 6.8),
                    ),
                    pw.Text(
                      'Official Authenticated Fee Voucher · Page 1 of 1',
                      style: pw.TextStyle(color: textSubtle, fontSize: 6.8),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static String _amountToWords(num amount) {
    final intAmount = amount.round();
    if (intAmount <= 0) return 'Rupees Zero Only';

    const units = <String>[
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];
    const tens = <String>[
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String convertChunk(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) {
        final t = tens[n ~/ 10];
        final u = units[n % 10];
        return u.isEmpty ? t : '$t $u';
      }
      final h = units[n ~/ 100];
      final rest = convertChunk(n % 100);
      return rest.isEmpty ? '$h Hundred' : '$h Hundred $rest';
    }

    var numVal = intAmount;
    final parts = <String>[];

    if (numVal >= 10000000) {
      final crores = numVal ~/ 10000000;
      parts.add('${convertChunk(crores)} Crore');
      numVal %= 10000000;
    }
    if (numVal >= 100000) {
      final lakhs = numVal ~/ 100000;
      parts.add('${convertChunk(lakhs)} Lakh');
      numVal %= 100000;
    }
    if (numVal >= 1000) {
      final thousands = numVal ~/ 1000;
      parts.add('${convertChunk(thousands)} Thousand');
      numVal %= 1000;
    }
    if (numVal > 0) {
      parts.add(convertChunk(numVal));
    }

    final words = parts.join(' ').trim();
    return 'Rupees $words Only';
  }

  static pw.Widget _fieldRow(
    String label,
    String value, {
    bool boldValue = false,
    required PdfColor textMuted,
    required PdfColor primaryNavy,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 78,
          child: pw.Text(
            label,
            style: pw.TextStyle(color: textMuted, fontSize: 7.8),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              color: primaryNavy,
              fontSize: 8.2,
              fontWeight:
                  boldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _ledgerTile({
    required String title,
    required String amount,
    required String caption,
    required PdfColor accentColor,
    required PdfColor surfaceBg,
    required PdfColor borderLine,
    required PdfColor textMuted,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: surfaceBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderLine, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: textMuted,
              fontSize: 6.8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            amount,
            style: pw.TextStyle(
              color: accentColor,
              fontSize: 12.0,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            caption,
            style: pw.TextStyle(
              color: textMuted,
              fontSize: 6.8,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _termBullet(String text, PdfColor textMuted) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: textMuted,
          fontSize: 6.6,
          lineSpacing: 1.15,
        ),
      ),
    );
  }

  /// Official institutional seal stamp with clean, normal, ultra-clear text.
  static pw.Widget _companyStamp() {
    const stampInk = PdfColor.fromInt(0xFF0F3664); // Deep Navy Stamp Ink

    const size = 118.0;

    return pw.Transform.rotate(
      angle: -0.04, // Very subtle realistic stamp tilt (~2.3 degrees)
      child: pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: stampInk, width: 2.2),
        ),
        child: pw.Center(
          child: pw.Container(
            width: 108.0,
            height: 108.0,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: stampInk, width: 0.8),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'EXCELLENT EDUCATORS',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: stampInk,
                      fontSize: 7.2,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 1.5),
                  pw.Text(
                    'ACCOUNTS DEPT',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: stampInk,
                      fontSize: 5.0,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: 68,
                    height: 1.0,
                    color: stampInk,
                  ),
                  pw.SizedBox(height: 2.5),
                  pw.Text(
                    'PAID',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: stampInk,
                      fontSize: 18.0,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  pw.SizedBox(height: 1.5),
                  pw.Container(
                    width: 68,
                    height: 1.0,
                    color: stampInk,
                  ),
                  pw.SizedBox(height: 3.5),
                  pw.Text(
                    'FEES RECEIVED',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: stampInk,
                      fontSize: 6.0,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'OFFICIAL SEAL',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: stampInk,
                      fontSize: 4.8,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
