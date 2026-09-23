class NamedRef {
  const NamedRef({required this.id, required this.label});

  factory NamedRef.fromJson(
    Map<String, dynamic>? json, {
    String labelKey = 'full_name',
  }) {
    if (json == null) {
      return const NamedRef(id: '', label: '');
    }
    return NamedRef(
      id: json['id'] as String? ?? '',
      label: json[labelKey] as String? ?? json['name'] as String? ?? '',
    );
  }

  final String id;
  final String label;

  bool get isEmpty => id.isEmpty;
}

class StudentDto {
  const StudentDto({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.email,
    required this.classGrade,
    required this.status,
    required this.phone,
    this.whatsappNumber,
    this.address,
    this.gender,
    this.guardianName,
    this.guardianPhone,
    this.level,
    this.batch,
    this.masterTeacher,
    this.masterTeachers = const [],
    this.aptitudeAssessmentStatus,
    this.aptitudeAssessmentSubmittedAt,
    this.aptitudeAssessmentTitle,
    this.createdAt,
    this.feedbackTotalSessions = 0,
    this.feedbackCurrentMonthSessions = 0,
    this.feedbackCurrentMonthCompleted = false,
    this.feedbackFilterYear,
    this.feedbackFilterMonth,
    this.feedbackFilterMonthCompleted = false,
    this.feedbackOverallAverage,
    this.canRateThisMonth = false,
    this.canEditRatingThisMonth = false,
    this.monthlyFeedbackId,
    this.masterClassAllotment = 1,
    this.masterClassRemaining = 0,
    this.masterClassUsed = 0,
    this.masterClassOverride,
  });

  factory StudentDto.fromJson(Map<String, dynamic> json) {
    final aptitude = json['aptitude_assessment'] is Map
        ? Map<String, dynamic>.from(json['aptitude_assessment'] as Map)
        : null;
    final feedback = json['feedback'] is Map
        ? Map<String, dynamic>.from(json['feedback'] as Map)
        : null;

    return StudentDto(
      id: json['id'] as String,
      studentCode: json['student_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      classGrade: (json['class_grade'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      phone: json['phone'] as String? ?? '',
      whatsappNumber: json['whatsapp_number'] as String?,
      address: json['address'] as String?,
      gender: json['gender'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      level: json['level'] is Map
          ? NamedRef.fromJson(
              Map<String, dynamic>.from(json['level'] as Map),
              labelKey: 'name',
            )
          : null,
      batch: json['batch'] is Map
          ? NamedRef.fromJson(
              Map<String, dynamic>.from(json['batch'] as Map),
              labelKey: 'name',
            )
          : null,
      masterTeacher: json['master_teacher'] is Map
          ? NamedRef.fromJson(
              Map<String, dynamic>.from(json['master_teacher'] as Map),
            )
          : null,
      masterTeachers: (json['master_teachers'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => TeacherDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      aptitudeAssessmentStatus: aptitude?['status'] as String?,
      aptitudeAssessmentSubmittedAt: aptitude?['submitted_at'] as String?,
      aptitudeAssessmentTitle: aptitude?['assessment_title'] as String?,
      createdAt: json['created_at'] as String?,
      feedbackTotalSessions:
          (feedback?['total_sessions'] as num?)?.toInt() ?? 0,
      feedbackCurrentMonthSessions:
          (feedback?['current_month_sessions'] as num?)?.toInt() ?? 0,
      feedbackCurrentMonthCompleted:
          feedback?['current_month_completed'] == true,
      feedbackFilterYear: (feedback?['filter_year'] as num?)?.toInt(),
      feedbackFilterMonth: (feedback?['filter_month'] as num?)?.toInt(),
      feedbackFilterMonthCompleted: feedback?['filter_month_completed'] == true,
      feedbackOverallAverage: (feedback?['overall_average'] as num?)
          ?.toDouble(),
      canRateThisMonth: feedback?['can_rate'] == true,
      canEditRatingThisMonth: feedback?['can_edit_rating'] == true,
      monthlyFeedbackId: feedback?['monthly_feedback_id'] as String?,
      masterClassAllotment:
          (json['master_class'] is Map
              ? (json['master_class']['allotment'] as num?)?.toInt()
              : null) ??
          1,
      masterClassRemaining:
          (json['master_class'] is Map
              ? (json['master_class']['remaining'] as num?)?.toInt()
              : null) ??
          0,
      masterClassUsed:
          (json['master_class'] is Map
              ? (json['master_class']['used'] as num?)?.toInt()
              : null) ??
          0,
      masterClassOverride: json['master_class'] is Map
          ? (json['master_class']['override'] as num?)?.toInt()
          : null,
    );
  }

  final String id;
  final String studentCode;
  final String fullName;
  final String email;
  final int classGrade;
  final String status;
  final String phone;
  final String? whatsappNumber;
  final String? address;
  final String? gender;
  final String? guardianName;
  final String? guardianPhone;
  final NamedRef? level;
  final NamedRef? batch;
  final NamedRef? masterTeacher;
  final List<TeacherDto> masterTeachers;
  final String? aptitudeAssessmentStatus;
  final String? aptitudeAssessmentSubmittedAt;
  final String? aptitudeAssessmentTitle;
  final String? createdAt;
  final int feedbackTotalSessions;
  final int feedbackCurrentMonthSessions;
  final bool feedbackCurrentMonthCompleted;
  final int? feedbackFilterYear;
  final int? feedbackFilterMonth;
  final bool feedbackFilterMonthCompleted;
  final double? feedbackOverallAverage;
  final bool canRateThisMonth;
  final bool canEditRatingThisMonth;
  final String? monthlyFeedbackId;
  final int masterClassAllotment;
  final int masterClassRemaining;
  final int masterClassUsed;
  final int? masterClassOverride;

  bool get hasSubmittedAptitudeAssessment =>
      aptitudeAssessmentStatus == 'submitted';

  bool get hasMasterTeacher =>
      masterTeachers.isNotEmpty ||
      (masterTeacher != null && !masterTeacher!.isEmpty);

  bool get hasOverallRating => feedbackOverallAverage != null;
}

class MasterTeacherRosterLevelDto {
  const MasterTeacherRosterLevelDto({
    required this.id,
    required this.name,
    this.batches = const [],
  });

  factory MasterTeacherRosterLevelDto.fromJson(Map<String, dynamic> json) {
    return MasterTeacherRosterLevelDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      batches: (json['batches'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NamedRef.fromJson(
              Map<String, dynamic>.from(item),
              labelKey: 'name',
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String name;
  final List<NamedRef> batches;
}

class MasterTeacherRosterDto {
  const MasterTeacherRosterDto({
    required this.students,
    this.levels = const [],
  });

  final List<StudentDto> students;
  final List<MasterTeacherRosterLevelDto> levels;
}

class TeacherDto {
  const TeacherDto({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    required this.roles,
    this.employeeCode,
    this.phone,
    this.whatsappNumber,
    this.address,
    this.gender,
    this.photoUrl,
    this.professionalTitle,
    this.bio,
    this.experienceSummary,
    this.guidanceAreas = const [],
    this.mentoringApproach = const [],
    this.education = const [],
    this.certifications = const [],
    this.experience = const [],
    this.mentorStats,
    this.activeBatchCount,
    this.activeMenteeCount,
    this.assignedLevels = const [],
    this.assignedLevelsCount,
    this.createdAt,
  });

  factory TeacherDto.fromJson(Map<String, dynamic> json) {
    final stats = json['mentor_stats'];
    return TeacherDto(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((role) => role.toString())
          .toList(),
      employeeCode: json['employee_code'] as String?,
      phone: json['phone'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      address: json['address'] as String?,
      gender: json['gender'] as String?,
      photoUrl: json['photo_url'] as String?,
      professionalTitle: json['professional_title'] as String?,
      bio: json['bio'] as String?,
      experienceSummary: json['experience_summary'] as String?,
      guidanceAreas: (json['guidance_areas'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      mentoringApproach:
          (json['mentoring_approach'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList(),
      education: (json['education'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                MentorEducationDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      certifications: (json['certifications'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => MentorCertificationDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      experience: (json['experience'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                MentorExperienceDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      mentorStats: stats is Map
          ? MentorStatsDto.fromJson(Map<String, dynamic>.from(stats))
          : null,
      activeBatchCount: (json['active_batch_count'] as num?)?.toInt(),
      activeMenteeCount: (json['active_mentee_count'] as num?)?.toInt(),
      assignedLevels: (json['assigned_levels'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      assignedLevelsCount: (json['assigned_levels_count'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String status;
  final List<String> roles;
  final String? employeeCode;
  final String? phone;
  final String? whatsappNumber;
  final String? address;
  final String? gender;
  final String? photoUrl;
  final String? professionalTitle;
  final String? bio;
  final String? experienceSummary;
  final List<String> guidanceAreas;
  final List<String> mentoringApproach;
  final List<MentorEducationDto> education;
  final List<MentorCertificationDto> certifications;
  final List<MentorExperienceDto> experience;
  final MentorStatsDto? mentorStats;
  final int? activeBatchCount;
  final int? activeMenteeCount;
  final List<String> assignedLevels;
  final int? assignedLevelsCount;
  final String? createdAt;

  bool get isCommonTeacher => roles.contains('common_teacher');
  bool get isMasterTeacher => roles.contains('master_teacher');
  bool get hasMentorProfile =>
      (professionalTitle ?? '').trim().isNotEmpty ||
      (bio ?? '').trim().isNotEmpty ||
      (experienceSummary ?? '').trim().isNotEmpty ||
      guidanceAreas.isNotEmpty ||
      mentoringApproach.isNotEmpty;

  String get roleLabel => roles.join(', ');

  String get displayTitle => (professionalTitle ?? '').trim().isNotEmpty
      ? professionalTitle!.trim()
      : 'Student Mentor';

  String get assignedLevelsLabel {
    if (assignedLevels.isEmpty) {
      return 'Not assigned';
    }
    return assignedLevels.join(', ');
  }

  String get levelsLabel {
    if (assignedLevels.isNotEmpty) {
      return assignedLevels.join(' · ');
    }
    return 'No levels assigned';
  }

  Map<String, dynamic> mentorProfilePayload() {
    return {
      'photo_url': (photoUrl ?? '').trim().isEmpty ? null : photoUrl!.trim(),
      'professional_title': (professionalTitle ?? '').trim().isEmpty
          ? null
          : professionalTitle!.trim(),
      'bio': (bio ?? '').trim().isEmpty ? null : bio!.trim(),
      'experience_summary': (experienceSummary ?? '').trim().isEmpty
          ? null
          : experienceSummary!.trim(),
      'guidance_areas': guidanceAreas,
      'mentoring_approach': mentoringApproach,
      'education': education.map((item) => item.toJson()).toList(),
      'certifications': certifications.map((item) => item.toJson()).toList(),
      'experience': experience.map((item) => item.toJson()).toList(),
    };
  }
}

class MentorStatsDto {
  const MentorStatsDto({
    required this.studentsGuided,
    required this.sessionsCompleted,
    this.ratingAverage,
  });

  factory MentorStatsDto.fromJson(Map<String, dynamic> json) {
    return MentorStatsDto(
      studentsGuided: (json['students_guided'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (json['sessions_completed'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['rating_average'] as num?)?.toDouble(),
    );
  }

  final int studentsGuided;
  final int sessionsCompleted;
  final double? ratingAverage;
}

class MentorEducationDto {
  const MentorEducationDto({
    required this.degree,
    required this.institution,
    this.year,
  });

  factory MentorEducationDto.fromJson(Map<String, dynamic> json) {
    return MentorEducationDto(
      degree: json['degree'] as String? ?? '',
      institution: json['institution'] as String? ?? '',
      year: json['year'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'degree': degree,
    'institution': institution,
    if (year != null && year!.trim().isNotEmpty) 'year': year,
  };

  final String degree;
  final String institution;
  final String? year;
}

class MentorCertificationDto {
  const MentorCertificationDto({
    required this.name,
    this.organization,
    this.year,
  });

  factory MentorCertificationDto.fromJson(Map<String, dynamic> json) {
    return MentorCertificationDto(
      name: json['name'] as String? ?? '',
      organization: json['organization'] as String?,
      year: json['year'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (organization != null && organization!.trim().isNotEmpty)
      'organization': organization,
    if (year != null && year!.trim().isNotEmpty) 'year': year,
  };

  final String name;
  final String? organization;
  final String? year;
}

class MentorExperienceDto {
  const MentorExperienceDto({
    required this.organization,
    required this.role,
    this.duration,
  });

  factory MentorExperienceDto.fromJson(Map<String, dynamic> json) {
    return MentorExperienceDto(
      organization: json['organization'] as String? ?? '',
      role: json['role'] as String? ?? '',
      duration: json['duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'organization': organization,
    'role': role,
    if (duration != null && duration!.trim().isNotEmpty) 'duration': duration,
  };

  final String organization;
  final String role;
  final String? duration;
}

class AcademicLevelDto {
  const AcademicLevelDto({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.status,
    this.batches = const [],
    this.masterTeachers = const [],
    this.batchesCount = 0,
    this.studentsCount = 0,
    this.masterClassesPerMonth = 1,
  });

  factory AcademicLevelDto.fromJson(Map<String, dynamic> json) {
    final batchesList = (json['batches'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => BatchDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final masterTeachersList =
        (json['master_teachers'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => TeacherDto.fromJson(Map<String, dynamic>.from(item)))
            .toList();

    final parsedBatchesCount =
        (json['batches_count'] as num?)?.toInt() ??
        (json['batch_count'] as num?)?.toInt() ??
        batchesList.length;

    final batchStudentsSum = batchesList.fold<int>(
      0,
      (sum, b) => sum + b.activeStudentCount,
    );

    final parsedStudentsCount = batchesList.isNotEmpty
        ? batchStudentsSum
        : ((json['students_count'] as num?)?.toInt() ??
              (json['student_count'] as num?)?.toInt() ??
              0);

    return AcademicLevelDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      academicYear: (json['academic_year'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      batches: batchesList,
      masterTeachers: masterTeachersList,
      batchesCount: parsedBatchesCount,
      studentsCount: parsedStudentsCount,
      masterClassesPerMonth:
          (json['master_classes_per_month'] as num?)?.toInt() ?? 1,
    );
  }

  final String id;
  final String name;
  final int academicYear;
  final String status;
  final List<BatchDto> batches;
  final List<TeacherDto> masterTeachers;
  final int batchesCount;
  final int studentsCount;
  final int masterClassesPerMonth;
}

class BatchDto {
  const BatchDto({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.status,
    required this.activeStudentCount,
    required this.maxActiveStudents,
    this.levelId,
    this.year,
    this.month,
    this.enrolledWatermark = 0,
    this.startsOn,
    this.endsOn,
  });

  factory BatchDto.fromJson(Map<String, dynamic> json) {
    return BatchDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      academicYear: (json['academic_year'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      activeStudentCount: (json['active_student_count'] as num?)?.toInt() ?? 0,
      maxActiveStudents: (json['max_active_students'] as num?)?.toInt() ?? 50,
      levelId: json['level_id'] as String?,
      year: (json['year'] as num?)?.toInt(),
      month: (json['month'] as num?)?.toInt(),
      enrolledWatermark: (json['enrolled_watermark'] as num?)?.toInt() ?? 0,
      startsOn: json['starts_on'] as String?,
      endsOn: json['ends_on'] as String?,
    );
  }

  final String id;
  final String name;
  final int academicYear;
  final String status;
  final int activeStudentCount;
  final int maxActiveStudents;
  final String? levelId;
  final int? year;
  final int? month;
  final int enrolledWatermark;
  final String? startsOn;
  final String? endsOn;

  bool get isActive => status == 'active';
  bool get isFull => activeStudentCount >= maxActiveStudents;

  String get monthName {
    if (month == null || month! < 1 || month! > 12) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month! - 1];
  }
}

class AdminDashboardDto {
  const AdminDashboardDto({
    required this.counts,
    this.byLevel = const [],
    this.topStudents = const [],
    this.topTeachers = const [],
  });

  factory AdminDashboardDto.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};

    return AdminDashboardDto(
      counts: AdminDashboardCountsDto.fromJson(countsJson),
      byLevel: (json['by_level'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AdminLevelSnapshotDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      topStudents: (json['top_students'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AdminTopStudentDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      topTeachers: (json['top_teachers'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AdminTopTeacherDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  final AdminDashboardCountsDto counts;
  final List<AdminLevelSnapshotDto> byLevel;
  final List<AdminTopStudentDto> topStudents;
  final List<AdminTopTeacherDto> topTeachers;
}

class AdminDashboardCountsDto {
  const AdminDashboardCountsDto({
    required this.activeStudents,
    required this.inactiveStudents,
    required this.activeTeachers,
    required this.activeBatches,
    required this.studentsWithoutBatch,
    required this.studentsWithoutMasterTeacher,
    required this.fullBatches,
    required this.studentsAssessmentPending,
    required this.studentsWithoutRatingThisMonth,
    this.totalClasses = 0,
    this.completedClasses = 0,
    this.pendingVerification = 0,
    this.studentAttendanceReports = 0,
    this.teacherAttendanceReports = 0,
    this.verifiedTeacherAbsence = 0,
    this.verifiedStudentAbsence = 0,
    this.technicalIssues = 0,
    this.rebookingsGiven = 0,
    this.totalStudents = 0,
    this.interviews = 0,
    this.masterClasses = 0,
    this.promotedStudents = 0,
  });

  factory AdminDashboardCountsDto.fromJson(Map<String, dynamic> json) {
    return AdminDashboardCountsDto(
      activeStudents: (json['active_students'] as num?)?.toInt() ?? 0,
      inactiveStudents: (json['inactive_students'] as num?)?.toInt() ?? 0,
      activeTeachers: (json['active_teachers'] as num?)?.toInt() ?? 0,
      activeBatches: (json['active_batches'] as num?)?.toInt() ?? 0,
      studentsWithoutBatch:
          (json['students_without_batch'] as num?)?.toInt() ?? 0,
      studentsWithoutMasterTeacher:
          (json['students_without_master_teacher'] as num?)?.toInt() ?? 0,
      fullBatches: (json['full_batches'] as num?)?.toInt() ?? 0,
      studentsAssessmentPending:
          (json['students_assessment_pending'] as num?)?.toInt() ?? 0,
      studentsWithoutRatingThisMonth:
          (json['students_without_rating_this_month'] as num?)?.toInt() ?? 0,
      totalClasses: (json['total_classes'] as num?)?.toInt() ?? 0,
      completedClasses: (json['completed_classes'] as num?)?.toInt() ?? 0,
      pendingVerification: (json['pending_verification'] as num?)?.toInt() ?? 0,
      studentAttendanceReports:
          (json['student_attendance_reports'] as num?)?.toInt() ?? 0,
      teacherAttendanceReports:
          (json['teacher_attendance_reports'] as num?)?.toInt() ?? 0,
      verifiedTeacherAbsence:
          (json['verified_teacher_absence'] as num?)?.toInt() ?? 0,
      verifiedStudentAbsence:
          (json['verified_student_absence'] as num?)?.toInt() ?? 0,
      technicalIssues: (json['technical_issues'] as num?)?.toInt() ?? 0,
      rebookingsGiven: (json['rebookings_given'] as num?)?.toInt() ?? 0,
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      interviews: (json['interviews'] as num?)?.toInt() ?? 0,
      masterClasses: (json['master_classes'] as num?)?.toInt() ?? 0,
      promotedStudents: (json['promoted_students'] as num?)?.toInt() ?? 0,
    );
  }

  final int activeStudents;
  final int inactiveStudents;
  final int activeTeachers;
  final int activeBatches;
  final int studentsWithoutBatch;
  final int studentsWithoutMasterTeacher;
  final int fullBatches;
  final int studentsAssessmentPending;
  final int studentsWithoutRatingThisMonth;
  final int totalClasses;
  final int completedClasses;
  final int pendingVerification;
  final int studentAttendanceReports;
  final int teacherAttendanceReports;
  final int verifiedTeacherAbsence;
  final int verifiedStudentAbsence;
  final int technicalIssues;
  final int rebookingsGiven;
  final int totalStudents;
  final int interviews;
  final int masterClasses;
  final int promotedStudents;
}

class AdminLevelSnapshotDto {
  const AdminLevelSnapshotDto({
    required this.id,
    required this.name,
    required this.studentCount,
    required this.batches,
  });

  factory AdminLevelSnapshotDto.fromJson(Map<String, dynamic> json) {
    return AdminLevelSnapshotDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      batches: (json['batches'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AdminBatchSnapshotDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  final String id;
  final String name;
  final int studentCount;
  final List<AdminBatchSnapshotDto> batches;
}

class AdminBatchSnapshotDto {
  const AdminBatchSnapshotDto({
    required this.id,
    required this.name,
    required this.studentCount,
  });

  factory AdminBatchSnapshotDto.fromJson(Map<String, dynamic> json) {
    return AdminBatchSnapshotDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final int studentCount;
}

class AdminTopStudentDto {
  const AdminTopStudentDto({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.monthsWithUs,
    required this.completedMasterClasses,
    this.levelName,
    this.ratingAverage,
    this.reason,
  });

  factory AdminTopStudentDto.fromJson(Map<String, dynamic> json) {
    return AdminTopStudentDto(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      studentCode: json['student_code'] as String? ?? '',
      levelName: json['level_name'] as String?,
      ratingAverage: (json['rating_average'] as num?)?.toDouble(),
      completedMasterClasses:
          (json['completed_master_classes'] as num?)?.toInt() ?? 0,
      monthsWithUs: (json['months_with_us'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String studentCode;
  final String? levelName;
  final double? ratingAverage;
  final int completedMasterClasses;
  final int monthsWithUs;
  final String? reason;
}

class AdminTopTeacherDto {
  const AdminTopTeacherDto({
    required this.id,
    required this.fullName,
    required this.interviews,
    required this.masterClasses,
    required this.promotedStudents,
  });

  factory AdminTopTeacherDto.fromJson(Map<String, dynamic> json) {
    return AdminTopTeacherDto(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      interviews: (json['interviews'] as num?)?.toInt() ?? 0,
      masterClasses: (json['master_classes'] as num?)?.toInt() ?? 0,
      promotedStudents: (json['promoted_students'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String fullName;
  final int interviews;
  final int masterClasses;
  final int promotedStudents;
}

class AssessmentDto {
  const AssessmentDto({
    required this.id,
    required this.batchId,
    required this.title,
    required this.maxScore,
    required this.version,
    required this.status,
    this.description,
    this.scoredCount = 0,
  });

  factory AssessmentDto.fromJson(Map<String, dynamic> json) {
    return AssessmentDto(
      id: json['id'] as String,
      batchId: json['batch_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'draft',
      scoredCount: (json['scored_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String batchId;
  final String title;
  final String? description;
  final double maxScore;
  final int version;
  final String status;
  final int scoredCount;
}

class AssessmentScoreDto {
  const AssessmentScoreDto({
    required this.studentId,
    required this.version,
    this.id,
    this.score,
    this.notes,
    this.studentName,
    this.studentCode,
  });

  factory AssessmentScoreDto.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : null;
    return AssessmentScoreDto(
      id: json['id'] as String?,
      studentId: json['student_id'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      score: (json['score'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      studentName: student?['full_name'] as String?,
      studentCode: student?['student_code'] as String?,
    );
  }

  final String? id;
  final String studentId;
  final int version;
  final double? score;
  final String? notes;
  final String? studentName;
  final String? studentCode;
}

class AssessmentScoresPayload {
  const AssessmentScoresPayload({
    required this.scores,
    required this.version,
    required this.currentVersion,
    this.assessment,
  });

  final List<AssessmentScoreDto> scores;
  final int version;
  final int currentVersion;
  final AssessmentDto? assessment;
}

class MasterTeacherDashboardDto {
  const MasterTeacherDashboardDto({
    required this.currentMonth,
    required this.counts,
    required this.byMonth,
    required this.pendingStudents,
  });

  factory MasterTeacherDashboardDto.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};
    final currentMonthJson =
        json['current_month'] as Map<String, dynamic>? ?? {};
    final byMonth = (json['by_month'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => MasterTeacherDashboardMonthDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    final pending = (json['pending_students'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => MasterTeacherPendingStudentDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return MasterTeacherDashboardDto(
      currentMonth: MasterTeacherDashboardMonthDto(
        year: (currentMonthJson['year'] as num?)?.toInt() ?? 0,
        month: (currentMonthJson['month'] as num?)?.toInt() ?? 0,
      ),
      counts: MasterTeacherDashboardCountsDto.fromJson(countsJson),
      byMonth: byMonth,
      pendingStudents: pending,
    );
  }

  final MasterTeacherDashboardMonthDto currentMonth;
  final MasterTeacherDashboardCountsDto counts;
  final List<MasterTeacherDashboardMonthDto> byMonth;
  final List<MasterTeacherPendingStudentDto> pendingStudents;
}

class MasterTeacherDashboardCountsDto {
  const MasterTeacherDashboardCountsDto({
    required this.assignedStudents,
    required this.ratedThisMonth,
    required this.notRatedThisMonth,
    required this.totalRatings,
    required this.overallAverage,
    required this.completionRate,
    required this.studentsAssessmentPending,
  });

  factory MasterTeacherDashboardCountsDto.fromJson(Map<String, dynamic> json) {
    return MasterTeacherDashboardCountsDto(
      assignedStudents: (json['assigned_students'] as num?)?.toInt() ?? 0,
      ratedThisMonth: (json['rated_this_month'] as num?)?.toInt() ?? 0,
      notRatedThisMonth: (json['not_rated_this_month'] as num?)?.toInt() ?? 0,
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
      overallAverage: (json['overall_average'] as num?)?.toDouble(),
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      studentsAssessmentPending:
          (json['students_assessment_pending'] as num?)?.toInt() ?? 0,
    );
  }

  final int assignedStudents;
  final int ratedThisMonth;
  final int notRatedThisMonth;
  final int totalRatings;
  final double? overallAverage;
  final double completionRate;
  final int studentsAssessmentPending;

  int get completionPercent => (completionRate * 100).round();
}

class MasterTeacherDashboardMonthDto {
  const MasterTeacherDashboardMonthDto({
    required this.year,
    required this.month,
    this.studentsRated = 0,
    this.averageRating,
  });

  factory MasterTeacherDashboardMonthDto.fromJson(Map<String, dynamic> json) {
    return MasterTeacherDashboardMonthDto(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      studentsRated: (json['students_rated'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );
  }

  final int year;
  final int month;
  final int studentsRated;
  final double? averageRating;

  String get monthLabel {
    const names = [
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
      return '$month $year';
    }
    return '${names[month - 1]} $year';
  }

  String get shortLabel {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) {
      return '$month';
    }
    return names[month - 1];
  }
}

class MasterTeacherPendingStudentDto {
  const MasterTeacherPendingStudentDto({
    required this.id,
    required this.fullName,
    required this.studentCode,
    this.monthlyFeedbackId,
    this.canRate = false,
    this.canEditRating = false,
  });

  factory MasterTeacherPendingStudentDto.fromJson(Map<String, dynamic> json) {
    return MasterTeacherPendingStudentDto(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      studentCode: json['student_code'] as String? ?? '',
      monthlyFeedbackId: json['monthly_feedback_id'] as String?,
      canRate: json['can_rate'] as bool? ?? false,
      canEditRating: json['can_edit_rating'] as bool? ?? false,
    );
  }

  final String id;
  final String fullName;
  final String studentCode;
  final String? monthlyFeedbackId;
  final bool canRate;
  final bool canEditRating;
}

class TeacherHistoryDto {
  const TeacherHistoryDto({
    required this.teacherName,
    required this.currentYear,
    required this.currentMonth,
    required this.thisMonth,
    required this.allTime,
    required this.byMonth,
    required this.events,
  });

  factory TeacherHistoryDto.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] as Map<String, dynamic>? ?? {};
    final current = json['current_month'] as Map<String, dynamic>? ?? {};
    return TeacherHistoryDto(
      teacherName: teacher['full_name'] as String? ?? '',
      currentYear: (current['year'] as num?)?.toInt() ?? 0,
      currentMonth: (current['month'] as num?)?.toInt() ?? 0,
      thisMonth: TeacherHistoryCountsDto.fromJson(
        json['this_month'] as Map<String, dynamic>? ?? {},
      ),
      allTime: TeacherHistoryCountsDto.fromJson(
        json['all_time'] as Map<String, dynamic>? ?? {},
      ),
      byMonth: (json['by_month'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => TeacherHistoryMonthDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      events: (json['events'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => TeacherHistoryEventDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  final String teacherName;
  final int currentYear;
  final int currentMonth;
  final TeacherHistoryCountsDto thisMonth;
  final TeacherHistoryCountsDto allTime;
  final List<TeacherHistoryMonthDto> byMonth;
  final List<TeacherHistoryEventDto> events;
}

class TeacherHistoryCountsDto {
  const TeacherHistoryCountsDto({
    required this.interviews,
    required this.interviewsHeld,
    required this.masterClasses,
    required this.masterClassesHeld,
    required this.leaveDays,
    required this.ratingsSubmitted,
    required this.conflictsReported,
    this.ratingAverage,
    this.classesCancelled = 0,
  });

  factory TeacherHistoryCountsDto.fromJson(Map<String, dynamic> json) {
    return TeacherHistoryCountsDto(
      interviews:
          (json['interviews'] as num?)?.toInt() ??
          (json['interviews_held'] as num?)?.toInt() ??
          0,
      interviewsHeld: (json['interviews_held'] as num?)?.toInt() ?? 0,
      masterClasses:
          (json['master_classes'] as num?)?.toInt() ??
          (json['master_classes_held'] as num?)?.toInt() ??
          0,
      masterClassesHeld: (json['master_classes_held'] as num?)?.toInt() ?? 0,
      leaveDays: (json['leave_days'] as num?)?.toInt() ?? 0,
      ratingsSubmitted: (json['ratings_submitted'] as num?)?.toInt() ?? 0,
      conflictsReported: (json['conflicts_reported'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['rating_average'] as num?)?.toDouble(),
      classesCancelled: (json['classes_cancelled'] as num?)?.toInt() ?? 0,
    );
  }

  final int interviews;
  final int interviewsHeld;
  final int masterClasses;
  final int masterClassesHeld;
  final int leaveDays;
  final int ratingsSubmitted;
  final int conflictsReported;
  final double? ratingAverage;
  final int classesCancelled;
}

class TeacherHistoryMonthDto {
  const TeacherHistoryMonthDto({
    required this.year,
    required this.month,
    required this.counts,
  });

  factory TeacherHistoryMonthDto.fromJson(Map<String, dynamic> json) {
    return TeacherHistoryMonthDto(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      counts: TeacherHistoryCountsDto.fromJson(json),
    );
  }

  final int year;
  final int month;
  final TeacherHistoryCountsDto counts;
}

class TeacherHistoryTagDto {
  const TeacherHistoryTagDto({required this.label, required this.tone});

  factory TeacherHistoryTagDto.fromJson(Map<String, dynamic> json) {
    return TeacherHistoryTagDto(
      label: json['label'] as String? ?? '',
      tone: json['tone'] as String? ?? 'muted',
    );
  }

  final String label;
  final String tone;
}

class TeacherHistoryFactDto {
  const TeacherHistoryFactDto({required this.label, required this.value});

  factory TeacherHistoryFactDto.fromJson(Map<String, dynamic> json) {
    return TeacherHistoryFactDto(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  final String label;
  final String value;
}

class TeacherHistoryEventDto {
  const TeacherHistoryEventDto({
    required this.id,
    required this.kind,
    required this.date,
    required this.title,
    required this.detail,
    required this.status,
    required this.tags,
    required this.facts,
    this.time,
    this.endTime,
    this.studentId,
    this.studentName,
    this.studentCode,
    this.levelName,
    this.learningWeek,
    this.attemptNumber,
    this.attemptMax,
    this.conflictStatus,
    this.conflictId,
  });

  factory TeacherHistoryEventDto.fromJson(Map<String, dynamic> json) {
    return TeacherHistoryEventDto(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String?,
      endTime: json['end_time'] as String?,
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      status: json['status'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                TeacherHistoryTagDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      facts: (json['facts'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                TeacherHistoryFactDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String?,
      studentCode: json['student_code'] as String?,
      levelName: json['level_name'] as String?,
      learningWeek: (json['learning_week'] as num?)?.toInt(),
      attemptNumber: (json['attempt_number'] as num?)?.toInt(),
      attemptMax: (json['attempt_max'] as num?)?.toInt(),
      conflictStatus: json['conflict_status'] as String?,
      conflictId: json['conflict_id'] as String?,
    );
  }

  final String id;
  final String kind;
  final String date;
  final String? time;
  final String? endTime;
  final String title;
  final String detail;
  final String status;
  final List<TeacherHistoryTagDto> tags;
  final List<TeacherHistoryFactDto> facts;
  final String? studentId;
  final String? studentName;
  final String? studentCode;
  final String? levelName;
  final int? learningWeek;
  final int? attemptNumber;
  final int? attemptMax;
  final String? conflictStatus;
  final String? conflictId;
}

class StudentActivityDto {
  const StudentActivityDto({
    required this.occurredAt,
    required this.type,
    required this.message,
  });

  factory StudentActivityDto.fromJson(Map<String, dynamic> json) {
    return StudentActivityDto(
      occurredAt: json['occurred_at'] as String? ?? '',
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  final String occurredAt;
  final String type;
  final String message;
}

class PermissionCatalogGroupDto {
  const PermissionCatalogGroupDto({
    required this.group,
    required this.label,
    required this.items,
  });

  factory PermissionCatalogGroupDto.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogGroupDto(
      group: json['group'] as String? ?? '',
      label: json['label'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => PermissionCatalogItemDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  final String group;
  final String label;
  final List<PermissionCatalogItemDto> items;
}

class PermissionCatalogItemDto {
  const PermissionCatalogItemDto({required this.key, required this.label});

  factory PermissionCatalogItemDto.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogItemDto(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  final String key;
  final String label;
}

class SubAdminDto {
  const SubAdminDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.status,
    required this.permissions,
    this.lastLoginAt,
  });

  factory SubAdminDto.fromJson(Map<String, dynamic> json) {
    final raw = json['permissions'];
    final permissions = <String, bool>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        permissions['$key'] = value == true;
      });
    }
    return SubAdminDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      permissions: permissions,
      lastLoginAt: json['last_login_at'] as String?,
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String status;
  final Map<String, bool> permissions;
  final String? lastLoginAt;

  bool get isActive => status == 'active';
}
