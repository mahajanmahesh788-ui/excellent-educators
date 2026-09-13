class NamedRef {
  const NamedRef({required this.id, required this.label});

  factory NamedRef.fromJson(Map<String, dynamic>? json, {String labelKey = 'full_name'}) {
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

class CareerCompassLevelDto {
  const CareerCompassLevelDto({
    required this.id,
    required this.code,
    required this.name,
    required this.classFrom,
    required this.classTo,
  });

  factory CareerCompassLevelDto.fromJson(Map<String, dynamic> json) {
    return CareerCompassLevelDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      classFrom: (json['class_from'] as num).toInt(),
      classTo: (json['class_to'] as num).toInt(),
    );
  }

  final String id;
  final String code;
  final String name;
  final int classFrom;
  final int classTo;

  String get displayName => '$name · Classes $classFrom–$classTo';
  String get shortCode => code.toUpperCase();
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
    this.guardianName,
    this.guardianPhone,
    this.careerCompassLevel,
    this.level,
    this.batch,
    this.commonTeacher,
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
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      careerCompassLevel: json['career_compass_level'] is Map
          ? CareerCompassLevelDto.fromJson(
              Map<String, dynamic>.from(json['career_compass_level'] as Map),
            )
          : null,
      level: json['level'] is Map
          ? NamedRef.fromJson(Map<String, dynamic>.from(json['level'] as Map), labelKey: 'name')
          : null,
      batch: json['batch'] is Map
          ? NamedRef.fromJson(Map<String, dynamic>.from(json['batch'] as Map), labelKey: 'name')
          : null,
      commonTeacher: json['common_teacher'] is Map
          ? NamedRef.fromJson(Map<String, dynamic>.from(json['common_teacher'] as Map))
          : null,
      masterTeacher: json['master_teacher'] is Map
          ? NamedRef.fromJson(Map<String, dynamic>.from(json['master_teacher'] as Map))
          : null,
      masterTeachers: (json['master_teachers'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => TeacherDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      aptitudeAssessmentStatus: aptitude?['status'] as String?,
      aptitudeAssessmentSubmittedAt: aptitude?['submitted_at'] as String?,
      aptitudeAssessmentTitle: aptitude?['assessment_title'] as String?,
      createdAt: json['created_at'] as String?,
      feedbackTotalSessions: (feedback?['total_sessions'] as num?)?.toInt() ?? 0,
      feedbackCurrentMonthSessions: (feedback?['current_month_sessions'] as num?)?.toInt() ?? 0,
      feedbackCurrentMonthCompleted: feedback?['current_month_completed'] == true,
      feedbackFilterYear: (feedback?['filter_year'] as num?)?.toInt(),
      feedbackFilterMonth: (feedback?['filter_month'] as num?)?.toInt(),
      feedbackFilterMonthCompleted: feedback?['filter_month_completed'] == true,
      feedbackOverallAverage: (feedback?['overall_average'] as num?)?.toDouble(),
      canRateThisMonth: feedback?['can_rate'] == true,
      canEditRatingThisMonth: feedback?['can_edit_rating'] == true,
      monthlyFeedbackId: feedback?['monthly_feedback_id'] as String?,
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
  final String? guardianName;
  final String? guardianPhone;
  final CareerCompassLevelDto? careerCompassLevel;
  final NamedRef? level;
  final NamedRef? batch;
  final NamedRef? commonTeacher;
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

  bool get hasSubmittedAptitudeAssessment => aptitudeAssessmentStatus == 'submitted';

  bool get hasMasterTeacher => masterTeachers.isNotEmpty || (masterTeacher != null && !masterTeacher!.isEmpty);

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
          .map((item) => NamedRef.fromJson(Map<String, dynamic>.from(item), labelKey: 'name'))
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
    this.activeBatchCount,
    this.activeMenteeCount,
    this.careerCompassLevels = const [],
    this.assignedLevels = const [],
    this.assignedLevelsCount,
    this.createdAt,
  });

  factory TeacherDto.fromJson(Map<String, dynamic> json) {
    return TeacherDto(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      roles: (json['roles'] as List<dynamic>? ?? const []).map((role) => role.toString()).toList(),
      employeeCode: json['employee_code'] as String?,
      phone: json['phone'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      address: json['address'] as String?,
      activeBatchCount: (json['active_batch_count'] as num?)?.toInt(),
      activeMenteeCount: (json['active_mentee_count'] as num?)?.toInt(),
      careerCompassLevels: (json['career_compass_levels'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => CareerCompassLevelDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
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
  final int? activeBatchCount;
  final int? activeMenteeCount;
  final List<CareerCompassLevelDto> careerCompassLevels;
  final List<String> assignedLevels;
  final int? assignedLevelsCount;
  final String? createdAt;

  bool get isCommonTeacher => roles.contains('common_teacher');
  bool get isMasterTeacher => roles.contains('master_teacher');

  String get roleLabel => roles.join(', ');

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
    if (careerCompassLevels.isNotEmpty) {
      return careerCompassLevels.map((level) => level.displayName).join(' · ');
    }
    return 'No levels assigned';
  }
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
  });

  factory AcademicLevelDto.fromJson(Map<String, dynamic> json) {
    final batchesList = (json['batches'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => BatchDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final masterTeachersList = (json['master_teachers'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => TeacherDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final parsedBatchesCount = (json['batches_count'] as num?)?.toInt() ??
        (json['batch_count'] as num?)?.toInt() ??
        batchesList.length;

    final batchStudentsSum = batchesList.fold<int>(0, (sum, b) => sum + b.activeStudentCount);

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
    this.careerCompassLevel,
    this.commonTeacher,
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
      careerCompassLevel: json['career_compass_level'] is Map
          ? CareerCompassLevelDto.fromJson(
              Map<String, dynamic>.from(json['career_compass_level'] as Map),
            )
          : null,
      commonTeacher: json['common_teacher'] is Map
          ? NamedRef.fromJson(Map<String, dynamic>.from(json['common_teacher'] as Map))
          : null,
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
  final CareerCompassLevelDto? careerCompassLevel;
  final NamedRef? commonTeacher;

  bool get isActive => status == 'active';
  bool get isFull => activeStudentCount >= maxActiveStudents;

  String get monthName {
    if (month == null || month! < 1 || month! > 12) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month! - 1];
  }
}

class AdminDashboardDto {
  const AdminDashboardDto({
    required this.counts,
    required this.careerCompass,
  });

  factory AdminDashboardDto.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};
    final compass = (json['career_compass'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => AdminDashboardCompassDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return AdminDashboardDto(
      counts: AdminDashboardCountsDto.fromJson(countsJson),
      careerCompass: compass,
    );
  }

  final AdminDashboardCountsDto counts;
  final List<AdminDashboardCompassDto> careerCompass;
}

class AdminDashboardCountsDto {
  const AdminDashboardCountsDto({
    required this.activeStudents,
    required this.inactiveStudents,
    required this.activeTeachers,
    required this.activeBatches,
    required this.studentsWithoutBatch,
    required this.studentsWithoutMasterTeacher,
    required this.batchesWithoutCommonTeacher,
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
  });

  factory AdminDashboardCountsDto.fromJson(Map<String, dynamic> json) {
    return AdminDashboardCountsDto(
      activeStudents: (json['active_students'] as num?)?.toInt() ?? 0,
      inactiveStudents: (json['inactive_students'] as num?)?.toInt() ?? 0,
      activeTeachers: (json['active_teachers'] as num?)?.toInt() ?? 0,
      activeBatches: (json['active_batches'] as num?)?.toInt() ?? 0,
      studentsWithoutBatch: (json['students_without_batch'] as num?)?.toInt() ?? 0,
      studentsWithoutMasterTeacher: (json['students_without_master_teacher'] as num?)?.toInt() ?? 0,
      batchesWithoutCommonTeacher: (json['batches_without_common_teacher'] as num?)?.toInt() ?? 0,
      fullBatches: (json['full_batches'] as num?)?.toInt() ?? 0,
      studentsAssessmentPending: (json['students_assessment_pending'] as num?)?.toInt() ?? 0,
      studentsWithoutRatingThisMonth: (json['students_without_rating_this_month'] as num?)?.toInt() ?? 0,
      totalClasses: (json['total_classes'] as num?)?.toInt() ?? 0,
      completedClasses: (json['completed_classes'] as num?)?.toInt() ?? 0,
      pendingVerification: (json['pending_verification'] as num?)?.toInt() ?? 0,
      studentAttendanceReports: (json['student_attendance_reports'] as num?)?.toInt() ?? 0,
      teacherAttendanceReports: (json['teacher_attendance_reports'] as num?)?.toInt() ?? 0,
      verifiedTeacherAbsence: (json['verified_teacher_absence'] as num?)?.toInt() ?? 0,
      verifiedStudentAbsence: (json['verified_student_absence'] as num?)?.toInt() ?? 0,
      technicalIssues: (json['technical_issues'] as num?)?.toInt() ?? 0,
      rebookingsGiven: (json['rebookings_given'] as num?)?.toInt() ?? 0,
    );
  }

  final int activeStudents;
  final int inactiveStudents;
  final int activeTeachers;
  final int activeBatches;
  final int studentsWithoutBatch;
  final int studentsWithoutMasterTeacher;
  final int batchesWithoutCommonTeacher;
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
}

class AdminDashboardCompassDto {
  const AdminDashboardCompassDto({
    required this.id,
    required this.code,
    required this.name,
    required this.classFrom,
    required this.classTo,
    required this.activeStudents,
    required this.activeBatches,
  });

  factory AdminDashboardCompassDto.fromJson(Map<String, dynamic> json) {
    return AdminDashboardCompassDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      classFrom: (json['class_from'] as num).toInt(),
      classTo: (json['class_to'] as num).toInt(),
      activeStudents: (json['active_students'] as num?)?.toInt() ?? 0,
      activeBatches: (json['active_batches'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String code;
  final String name;
  final int classFrom;
  final int classTo;
  final int activeStudents;
  final int activeBatches;

  String get shortCode => code.toUpperCase();
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
    final student = json['student'] is Map ? Map<String, dynamic>.from(json['student'] as Map) : null;
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
    final currentMonthJson = json['current_month'] as Map<String, dynamic>? ?? {};
    final byMonth = (json['by_month'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => MasterTeacherDashboardMonthDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final pending = (json['pending_students'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => MasterTeacherPendingStudentDto.fromJson(Map<String, dynamic>.from(item)))
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
      studentsAssessmentPending: (json['students_assessment_pending'] as num?)?.toInt() ?? 0,
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
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
