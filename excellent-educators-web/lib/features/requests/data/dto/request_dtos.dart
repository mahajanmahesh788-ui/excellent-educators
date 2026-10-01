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

class AdminRequestLevelRefDto {
  const AdminRequestLevelRefDto({
    required this.id,
    required this.name,
  });

  factory AdminRequestLevelRefDto.fromJson(Map<String, dynamic> json) {
    return AdminRequestLevelRefDto(
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
    this.fromLevel,
    this.targetLevel,
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
    final fromLevelJson = json['from_level'];
    final targetLevelJson = json['target_level'];

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
      fromLevel: fromLevelJson is Map
          ? AdminRequestLevelRefDto.fromJson(Map<String, dynamic>.from(fromLevelJson))
          : null,
      targetLevel: targetLevelJson is Map
          ? AdminRequestLevelRefDto.fromJson(Map<String, dynamic>.from(targetLevelJson))
          : null,
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
  final AdminRequestLevelRefDto? fromLevel;
  final AdminRequestLevelRefDto? targetLevel;
  final String? requesterName;
  final String? requesterEmail;
  final String? requesterPhone;
  final String? resolvedAt;
  final String? resolvedByName;
  final String createdAt;

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  bool get isRemoveMentee => requestType == 'remove_mentee';
  bool get isRemoveBatchStudent => requestType == 'remove_batch_student';
  bool get isPromoteStudent => requestType == 'promote_student';
  bool get isActionable => isRemoveMentee || isRemoveBatchStudent || isPromoteStudent;

  String get statusLabel => switch (status) {
        'pending' => 'Pending',
        'rejected' => 'Rejected',
        _ => 'Completed',
      };

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
      'promote_student' => 'Level upgrade',
      _ => 'General',
    };
  }

  String get levelUpgradeLabel {
    final from = fromLevel?.name ?? 'Level';
    final to = targetLevel?.name ?? 'Level';
    return '$from → $to';
  }
}
