class GeneratedBillDto {
  const GeneratedBillDto({
    required this.id,
    required this.billNumber,
    required this.fullName,
    required this.phone,
    required this.classGrade,
    required this.gender,
    required this.paymentType,
    required this.paymentMode,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    this.email,
    this.whatsappNumber,
    this.address,
    this.guardianName,
    this.guardianPhone,
    this.paymentTypeLabel,
    this.notes,
    this.billDate,
    this.createdAt,
  });

  factory GeneratedBillDto.fromJson(Map<String, dynamic> json) {
    return GeneratedBillDto(
      id: json['id'] as String? ?? '',
      billNumber: json['bill_number'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      whatsappNumber: json['whatsapp_number'] as String?,
      address: json['address'] as String?,
      classGrade: (json['class_grade'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? '',
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      paymentType: json['payment_type'] as String? ?? 'full',
      paymentTypeLabel: json['payment_type_label'] as String?,
      paymentMode: json['payment_mode'] as String? ?? 'offline',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      billDate: json['bill_date'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String billNumber;
  final String fullName;
  final String? email;
  final String phone;
  final String? whatsappNumber;
  final String? address;
  final int classGrade;
  final String gender;
  final String? guardianName;
  final String? guardianPhone;
  final String paymentType;
  final String? paymentTypeLabel;
  final String paymentMode;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String? notes;
  final String? billDate;
  final String? createdAt;
}
