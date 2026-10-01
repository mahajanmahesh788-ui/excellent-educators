import 'package:excellent_educators_web/core/utils/json_read.dart';

class PaymentOverviewDto {
  const PaymentOverviewDto({
    required this.allPending,
    required this.dueThisMonth,
    required this.overdue,
    required this.paidThisMonth,
    this.collectedThisMonth = 0,
    this.totalExpected = 0,
    this.totalCollected = 0,
    this.totalPending = 0,
    this.totalOverdue = 0,
    this.totalDead = 0,
  });

  factory PaymentOverviewDto.fromJson(Map<String, dynamic> json) {
    return PaymentOverviewDto(
      allPending: (json['all_pending'] as num?)?.toInt() ?? 0,
      dueThisMonth: (json['due_this_month'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      paidThisMonth: (json['paid_this_month'] as num?)?.toInt() ?? 0,
      collectedThisMonth: (json['collected_this_month'] as num?)?.toDouble() ?? 0,
      totalExpected: (json['total_expected'] as num?)?.toDouble() ?? 0,
      totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0,
      totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0,
      totalOverdue: (json['total_overdue'] as num?)?.toDouble() ?? 0,
      totalDead: (json['total_dead'] as num?)?.toDouble() ?? 0,
    );
  }

  final int allPending;
  final int dueThisMonth;
  final int overdue;
  final int paidThisMonth;
  final double collectedThisMonth;
  final double totalExpected;
  final double totalCollected;
  final double totalPending;
  final double totalOverdue;
  final double totalDead;
}

class AgentDashboardDto {
  const AgentDashboardDto({
    required this.studentsRegistered,
    required this.studentsActive,
    required this.payments,
  });

  factory AgentDashboardDto.fromJson(Map<String, dynamic> json) {
    return AgentDashboardDto(
      studentsRegistered: (json['students_registered'] as num?)?.toInt() ?? 0,
      studentsActive: (json['students_active'] as num?)?.toInt() ?? 0,
      payments: PaymentOverviewDto.fromJson(json),
    );
  }

  final int studentsRegistered;
  final int studentsActive;
  final PaymentOverviewDto payments;
}

class PaymentPlanStudentRef {
  const PaymentPlanStudentRef({
    required this.id,
    required this.fullName,
    this.studentCode,
    this.email,
    this.phone,
    this.whatsappNumber,
    this.levelName,
    this.batchName,
  });

  factory PaymentPlanStudentRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaymentPlanStudentRef(id: '', fullName: '');
    }
    final level = json['level'] is Map
        ? Map<String, dynamic>.from(json['level'] as Map)
        : null;
    final batch = json['batch'] is Map
        ? Map<String, dynamic>.from(json['batch'] as Map)
        : null;
    return PaymentPlanStudentRef(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      studentCode: json['student_code'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      levelName: level?['name'] as String?,
      batchName: batch?['name'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String? studentCode;
  final String? email;
  final String? phone;
  final String? whatsappNumber;
  final String? levelName;
  final String? batchName;

  String get courseLabel {
    final parts = <String>[
      if (levelName != null && levelName!.isNotEmpty) levelName!,
      if (batchName != null && batchName!.isNotEmpty) batchName!,
    ];
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}

class StudentPaymentDto {
  const StudentPaymentDto({
    required this.id,
    required this.amount,
    required this.status,
    this.paymentMode,
    this.paymentDate,
    this.createdAt,
    this.transactionId,
    this.referenceNumber,
    this.notes,
    this.receiptUrl,
    this.statusLabel,
  });

  factory StudentPaymentDto.fromJson(Map<String, dynamic> json) {
    return StudentPaymentDto(
      id: jsonString(json, 'id'),
      amount: jsonOptDouble(json, 'amount') ?? 0,
      paymentMode: jsonOptString(json, 'payment_mode'),
      paymentDate: jsonOptString(json, 'payment_date') ??
          jsonOptString(json, 'created_at'),
      createdAt: jsonOptString(json, 'created_at'),
      transactionId: jsonOptString(json, 'transaction_id'),
      referenceNumber: jsonOptString(json, 'reference_number'),
      status: jsonString(json, 'status', 'pending'),
      statusLabel: jsonOptString(json, 'status_label'),
      notes: jsonOptString(json, 'notes'),
      receiptUrl: jsonOptString(json, 'receipt_url'),
    );
  }

  final String id;
  final double amount;
  final String? paymentMode;
  final String? paymentDate;
  final String? createdAt;
  final String? transactionId;
  final String? referenceNumber;
  final String status;
  final String? statusLabel;
  final String? notes;
  final String? receiptUrl;

  StudentPaymentDto copyWith({
    String? id,
    double? amount,
    String? paymentMode,
    String? paymentDate,
    String? createdAt,
    String? transactionId,
    String? referenceNumber,
    String? status,
    String? statusLabel,
    String? notes,
    String? receiptUrl,
  }) {
    return StudentPaymentDto(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}

class StudentPaymentPlanDto {
  const StudentPaymentPlanDto({
    required this.id,
    required this.studentId,
    required this.paymentType,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    this.advanceAmount = 0,
    this.dueDay,
    this.startDate,
    this.nextDueDate,
    this.nextDueAmount,
    this.overdueAmount = 0,
    this.lastPaymentDate,
    this.preferredMode,
    this.paymentTypeLabel,
    this.statusLabel,
    this.student,
    this.payments = const [],
  });

  factory StudentPaymentPlanDto.fromJson(Map<String, dynamic> json) {
    return StudentPaymentPlanDto(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      paymentType: json['payment_type'] as String? ?? 'full',
      paymentTypeLabel: json['payment_type_label'] as String?,
      preferredMode: json['preferred_mode'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0,
      dueDay: (json['due_day'] as num?)?.toInt(),
      startDate: json['start_date'] as String?,
      nextDueDate: json['next_due_date'] as String?,
      nextDueAmount: (json['next_due_amount'] as num?)?.toDouble(),
      overdueAmount: (json['overdue_amount'] as num?)?.toDouble() ?? 0,
      lastPaymentDate: json['last_payment_date'] as String?,
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String?,
      student: PaymentPlanStudentRef.fromJson(
        json['student'] is Map
            ? Map<String, dynamic>.from(json['student'] as Map)
            : null,
      ),
      payments: (json['payments'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                StudentPaymentDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  final String id;
  final String studentId;
  final String paymentType;
  final String? paymentTypeLabel;
  final String? preferredMode;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final double advanceAmount;
  final int? dueDay;
  final String? startDate;
  final String? nextDueDate;
  final double? nextDueAmount;
  final double overdueAmount;
  final String? lastPaymentDate;
  final String status;
  final String? statusLabel;
  final PaymentPlanStudentRef? student;
  final List<StudentPaymentDto> payments;

  bool get isPaid => status == 'paid' || pendingAmount <= 0;
  bool get isOverdue => status == 'overdue';
  bool get isPartial => status == 'partial';
}

class StudentPaymentSummaryDto {
  const StudentPaymentSummaryDto({
    required this.planId,
    required this.paymentType,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    this.advanceAmount = 0,
    this.nextDueDate,
    this.nextDueAmount,
    this.overdueAmount = 0,
    this.lastPaymentDate,
  });

  factory StudentPaymentSummaryDto.fromJson(Map<String, dynamic> json) {
    return StudentPaymentSummaryDto(
      planId: json['plan_id'] as String? ?? '',
      paymentType: json['payment_type'] as String? ?? 'full',
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0,
      nextDueDate: json['next_due_date'] as String?,
      nextDueAmount: (json['next_due_amount'] as num?)?.toDouble(),
      overdueAmount: (json['overdue_amount'] as num?)?.toDouble() ?? 0,
      lastPaymentDate: json['last_payment_date'] as String?,
    );
  }

  final String planId;
  final String paymentType;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final double advanceAmount;
  final String? nextDueDate;
  final double? nextDueAmount;
  final double overdueAmount;
  final String? lastPaymentDate;
}

class PaymentListResult {
  const PaymentListResult({
    required this.items,
    required this.summary,
    required this.meta,
  });

  final List<StudentPaymentPlanDto> items;
  final PaymentOverviewDto summary;
  final Map<String, dynamic> meta;
}

class PaymentReminderDto {
  const PaymentReminderDto({
    required this.message,
    this.whatsappUrl,
    this.phone,
    this.telUrl,
  });

  factory PaymentReminderDto.fromJson(Map<String, dynamic> json) {
    return PaymentReminderDto(
      message: json['message'] as String? ?? '',
      whatsappUrl: json['whatsapp_url'] as String?,
      phone: json['phone'] as String?,
      telUrl: json['tel_url'] as String?,
    );
  }

  final String message;
  final String? whatsappUrl;
  final String? phone;
  final String? telUrl;
}

class RecordPaymentResult {
  const RecordPaymentResult({
    required this.payment,
    required this.plan,
    required this.previousPending,
    required this.paymentReceived,
    required this.newPending,
  });

  factory RecordPaymentResult.fromJson(Map<String, dynamic> json) {
    final delta = json['delta'] is Map
        ? Map<String, dynamic>.from(json['delta'] as Map)
        : const <String, dynamic>{};
    return RecordPaymentResult(
      payment: StudentPaymentDto.fromJson(
        Map<String, dynamic>.from(json['payment'] as Map? ?? const {}),
      ),
      plan: StudentPaymentPlanDto.fromJson(
        Map<String, dynamic>.from(json['plan'] as Map? ?? const {}),
      ),
      previousPending: (delta['previous_pending'] as num?)?.toDouble() ?? 0,
      paymentReceived: (delta['payment_received'] as num?)?.toDouble() ?? 0,
      newPending: (delta['new_pending'] as num?)?.toDouble() ?? 0,
    );
  }

  final StudentPaymentDto payment;
  final StudentPaymentPlanDto plan;
  final double previousPending;
  final double paymentReceived;
  final double newPending;
}

class StudentSelfPaymentDto {
  const StudentSelfPaymentDto({
    this.plan,
    this.onlineEnabled = false,
  });

  factory StudentSelfPaymentDto.fromJson(Map<String, dynamic> json) {
    return StudentSelfPaymentDto(
      plan: json['plan'] is Map
          ? StudentPaymentPlanDto.fromJson(
              Map<String, dynamic>.from(json['plan'] as Map),
            )
          : null,
      onlineEnabled: json['online_enabled'] == true,
    );
  }

  final StudentPaymentPlanDto? plan;
  final bool onlineEnabled;
}
