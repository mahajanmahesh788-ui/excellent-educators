class AdminRequestStudentRefDto {
  const AdminRequestStudentRefDto({
    required this.id,
    required this.fullName,
    required this.studentCode,
  });

  factory AdminRequestStudentRefDto.fromJson(Map<String, dynamic> json) {
    return AdminRequestStudentRefDto(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      studentCode: json['student_code'] as String? ?? '',
    );
  }

  final String id;
  final String fullName;
  final String studentCode;
}

class AdminRequestBatchRefDto {
  const AdminRequestBatchRefDto({
    required this.id,
    required this.name,
  });

  factory AdminRequestBatchRefDto.fromJson(Map<String, dynamic> json) {
    return AdminRequestBatchRefDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String name;
}

class AdminRequestDto {
  const AdminRequestDto({
    required this.id,
    required this.subtitle,
    required this.description,
    required this.status,
    required this.requesterType,
    required this.requestType,
    this.student,
    this.batch,
    this.requesterName,
    this.requesterEmail,
    this.requesterPhone,
    this.resolvedAt,
    this.resolvedByName,
    required this.createdAt,
  });

  factory AdminRequestDto.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'];
    final resolvedBy = json['resolved_by'];
    final studentJson = json['student'];
    final batchJson = json['batch'];

    return AdminRequestDto(
      id: json['id'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      requesterType: json['requester_type'] as String? ?? '',
      requestType: json['request_type'] as String? ?? 'general',
      student: studentJson is Map
          ? AdminRequestStudentRefDto.fromJson(Map<String, dynamic>.from(studentJson))
          : null,
      batch: batchJson is Map ? AdminRequestBatchRefDto.fromJson(Map<String, dynamic>.from(batchJson)) : null,
      requesterName: requester is Map ? requester['name'] as String? : null,
      requesterEmail: requester is Map ? requester['email'] as String? : null,
      requesterPhone: requester is Map ? requester['phone'] as String? : null,
      resolvedAt: json['resolved_at'] as String?,
      resolvedByName: resolvedBy is Map ? resolvedBy['name'] as String? : null,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String id;
  final String subtitle;
  final String description;
  final String status;
  final String requesterType;
  final String requestType;
  final AdminRequestStudentRefDto? student;
  final AdminRequestBatchRefDto? batch;
  final String? requesterName;
  final String? requesterEmail;
  final String? requesterPhone;
  final String? resolvedAt;
  final String? resolvedByName;
  final String createdAt;

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';

  bool get isRemoveMentee => requestType == 'remove_mentee';
  bool get isRemoveBatchStudent => requestType == 'remove_batch_student';
  bool get isActionable => isRemoveMentee || isRemoveBatchStudent;

  String get statusLabel => isPending ? 'Pending' : 'Completed';

  String get requesterTypeLabel {
    return switch (requesterType) {
      'student' => 'Student',
      'teacher' => 'Teacher',
      _ => requesterType,
    };
  }

  String get requestTypeLabel {
    return switch (requestType) {
      'remove_mentee' => 'Remove student',
      'remove_batch_student' => 'Remove student',
      _ => 'General',
    };
  }
}
