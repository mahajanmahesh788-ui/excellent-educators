class AvailabilityRangeDto {
  const AvailabilityRangeDto({required this.start, required this.end, this.id});

  factory AvailabilityRangeDto.fromJson(Map<String, dynamic> json) {
    return AvailabilityRangeDto(
      id: json['id'] as String?,
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
    );
  }

  final String? id;
  final String start;
  final String end;

  Map<String, String> toPayload() => {'start': start, 'end': end};

  AvailabilityRangeDto copyWith({String? start, String? end}) {
    return AvailabilityRangeDto(id: id, start: start ?? this.start, end: end ?? this.end);
  }
}

class AvailabilityDayDto {
  const AvailabilityDayDto({
    required this.dayOfWeek,
    required this.label,
    required this.off,
    required this.ranges,
  });

  factory AvailabilityDayDto.fromJson(Map<String, dynamic> json) {
    return AvailabilityDayDto(
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      off: json['off'] as bool? ?? false,
      ranges: (json['ranges'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AvailabilityRangeDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final int dayOfWeek;
  final String label;
  final bool off;
  final List<AvailabilityRangeDto> ranges;

  Map<String, dynamic> toPayload() => {
        'day_of_week': dayOfWeek,
        'off': off,
        'ranges': off ? const [] : ranges.map((range) => range.toPayload()).toList(),
      };

  AvailabilityDayDto copyWith({bool? off, List<AvailabilityRangeDto>? ranges}) {
    return AvailabilityDayDto(
      dayOfWeek: dayOfWeek,
      label: label,
      off: off ?? this.off,
      ranges: ranges ?? this.ranges,
    );
  }
}

class TeacherAvailabilityDto {
  const TeacherAvailabilityDto({
    required this.teacherId,
    required this.workType,
    required this.weekly,
    required this.overrides,
  });

  factory TeacherAvailabilityDto.fromJson(Map<String, dynamic> json) {
    return TeacherAvailabilityDto(
      teacherId: json['teacher_id'] as String? ?? '',
      workType: json['work_type'] as String? ?? 'full_time',
      weekly: (json['weekly'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AvailabilityDayDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      overrides: (json['overrides'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AvailabilityOverrideDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String teacherId;
  final String workType;
  final List<AvailabilityDayDto> weekly;
  final List<AvailabilityOverrideDto> overrides;
}

class AvailabilityOverrideDto {
  const AvailabilityOverrideDto({
    required this.id,
    required this.date,
    required this.type,
    this.start,
    this.end,
  });

  factory AvailabilityOverrideDto.fromJson(Map<String, dynamic> json) {
    return AvailabilityOverrideDto(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'available',
      start: json['start'] as String?,
      end: json['end'] as String?,
    );
  }

  final String id;
  final String date;
  final String type;
  final String? start;
  final String? end;
}

class ScheduleSlotDto {
  const ScheduleSlotDto({
    required this.start,
    required this.end,
    required this.status,
    this.bookingId,
    this.studentName,
    this.bookingType,
    this.leaveId,
  });

  factory ScheduleSlotDto.fromJson(Map<String, dynamic> json) {
    return ScheduleSlotDto(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      bookingId: json['booking_id'] as String?,
      studentName: json['student_name'] as String?,
      bookingType: json['booking_type'] as String?,
      leaveId: json['leave_id'] as String?,
    );
  }

  final String start;
  final String end;
  final String status;
  final String? bookingId;
  final String? studentName;
  final String? bookingType;
  final String? leaveId;

  bool get isAvailable => status == 'available';
}

class ScheduleBreakDto {
  const ScheduleBreakDto({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleBreakDto.fromJson(Map<String, dynamic> json) {
    return ScheduleBreakDto(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
    );
  }

  final String id;
  final String type;
  final String startTime;
  final String endTime;
}

class ScheduleLeaveDto {
  const ScheduleLeaveDto({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isFullDay,
    this.reason,
    this.teacherId,
    this.teacherName,
    this.createdAt,
  });

  factory ScheduleLeaveDto.fromJson(Map<String, dynamic> json) {
    return ScheduleLeaveDto(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      isFullDay: json['is_full_day'] as bool? ?? false,
      reason: json['reason'] as String?,
      teacherId: json['teacher_id'] as String?,
      teacherName: json['teacher_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final bool isFullDay;
  final String? reason;
  final String? teacherId;
  final String? teacherName;
  final String? createdAt;
}

class SessionBookingDto {
  const SessionBookingDto({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.type,
    required this.date,
    required this.start,
    required this.end,
    required this.status,
    this.studentName,
    this.teacherName,
    this.meetingUrl,
    this.attemptNumber,
    this.learningWeek,
    this.startsAtIso,
    this.endsAtIso,
    this.attendance,
  });

  factory SessionBookingDto.fromJson(Map<String, dynamic> json) {
    return SessionBookingDto(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      date: json['date'] as String? ?? '',
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      studentName: json['student_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      meetingUrl: json['meeting_url'] as String?,
      attemptNumber: (json['attempt_number'] as num?)?.toInt(),
      learningWeek: (json['learning_week'] as num?)?.toInt(),
      startsAtIso: json['starts_at'] as String?,
      endsAtIso: json['ends_at'] as String?,
      attendance: json['attendance'] is Map
          ? BookingAttendanceDto.fromJson(Map<String, dynamic>.from(json['attendance'] as Map))
          : null,
    );
  }

  final String id;
  final String studentId;
  final String teacherId;
  final String type;
  final String date;
  final String start;
  final String end;
  final String status;
  final String? studentName;
  final String? teacherName;
  final String? meetingUrl;
  final int? attemptNumber;
  final int? learningWeek;
  final String? startsAtIso;
  final String? endsAtIso;
  final BookingAttendanceDto? attendance;

  String get typeLabel => type == 'master_class' ? 'Master Class' : 'Introduction Call';

  String get teacherSlotLine {
    final name = studentName ?? 'Student';
    final slot = '${formatHm(start)} – ${formatHm(end)}';
    if (type == 'master_class') {
      final attempt = ordinal(attemptNumber ?? 1);
      final week = ordinal(learningWeek ?? 1);
      final last = (attemptNumber ?? 1) >= 2 ? ' — last chance this month' : '';
      return '$name booked Master Class slot $slot ($attempt attempt, $week week)$last';
    }
    final last = (attemptNumber ?? 1) >= 2 ? ' — last chance' : '';
    return '$name booked interview slot $slot$last';
  }

  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';

  DateTime? get startsAt {
    final iso = DateTime.tryParse(startsAtIso ?? '');
    if (iso != null) {
      return iso.toLocal();
    }
    final time = start.length >= 5 ? start.substring(0, 5) : start;
    return DateTime.tryParse('${date}T$time');
  }

  DateTime? get endsAt {
    final iso = DateTime.tryParse(endsAtIso ?? '');
    if (iso != null) {
      return iso.toLocal();
    }
    final time = end.length >= 5 ? end.substring(0, 5) : end;
    return DateTime.tryParse('${date}T$time');
  }

  bool hasEndedAt(DateTime now) {
    final end = endsAt;
    return end != null && !end.isAfter(now);
  }

  bool isOngoingAt(DateTime now) {
    if (!isScheduled) {
      return false;
    }
    final start = startsAt;
    final end = endsAt;
    if (start == null || end == null) {
      return false;
    }
    return !start.isAfter(now) && end.isAfter(now);
  }
}

class BookingAttendanceDto {
  const BookingAttendanceDto({
    this.canJoin = false,
    this.canReportTeacherDidNotJoin = false,
    this.canReportStudentDidNotJoin = false,
    this.canRateStudent = false,
    this.canEditStudentRating = false,
    this.monthlyFeedbackId,
    this.classCompleted = false,
    this.reportSubmitted = false,
    this.rebookingAvailable = false,
    this.isLastChance = false,
    this.lastChanceMessage,
    this.canWhatsAppStudent = false,
    this.whatsappWindow,
    this.whatsappHint,
    this.studentJoinCount = 0,
  });

  factory BookingAttendanceDto.fromJson(Map<String, dynamic> json) {
    return BookingAttendanceDto(
      canJoin: json['can_join'] as bool? ?? false,
      canReportTeacherDidNotJoin: json['can_report_teacher_did_not_join'] as bool? ?? false,
      canReportStudentDidNotJoin: json['can_report_student_did_not_join'] as bool? ?? false,
      canRateStudent: json['can_rate_student'] as bool? ?? false,
      canEditStudentRating: json['can_edit_student_rating'] as bool? ?? false,
      monthlyFeedbackId: json['monthly_feedback_id'] as String?,
      classCompleted: json['class_completed'] as bool? ?? false,
      reportSubmitted: json['report_submitted'] as bool? ?? false,
      rebookingAvailable: json['rebooking_available'] as bool? ?? false,
      isLastChance: json['is_last_chance'] as bool? ?? false,
      lastChanceMessage: json['last_chance_message'] as String?,
      canWhatsAppStudent: json['can_whatsapp_student'] as bool? ?? false,
      whatsappWindow: json['whatsapp_window'] as String?,
      whatsappHint: json['whatsapp_hint'] as String?,
      studentJoinCount: (json['student_join_count'] as num?)?.toInt() ?? 0,
    );
  }

  final bool canJoin;
  final bool canReportTeacherDidNotJoin;
  final bool canReportStudentDidNotJoin;
  final bool canRateStudent;
  final bool canEditStudentRating;
  final String? monthlyFeedbackId;
  final bool classCompleted;
  final bool reportSubmitted;
  final bool rebookingAvailable;
  final bool isLastChance;
  final String? lastChanceMessage;
  final bool canWhatsAppStudent;
  final String? whatsappWindow;
  final String? whatsappHint;
  final int studentJoinCount;
}

class TeacherWhatsAppDto {
  const TeacherWhatsAppDto({
    required this.whatsappUrl,
    required this.message,
    required this.loginUrl,
    this.studentName,
    this.teacherName,
  });

  factory TeacherWhatsAppDto.fromJson(Map<String, dynamic> json) {
    return TeacherWhatsAppDto(
      whatsappUrl: json['whatsapp_url'] as String? ?? '',
      message: json['message'] as String? ?? '',
      loginUrl: json['login_url'] as String? ?? '',
      studentName: json['student_name'] as String?,
      teacherName: json['teacher_name'] as String?,
    );
  }

  final String whatsappUrl;
  final String message;
  final String loginUrl;
  final String? studentName;
  final String? teacherName;
}

class AttendanceIssueDto {
  const AttendanceIssueDto({
    required this.id,
    required this.issueType,
    required this.status,
    this.studentName,
    this.teacherName,
    this.studentId,
    this.teacherId,
    this.date,
    this.start,
    this.message,
    this.studentJoinCount = 0,
    this.studentFirstJoinAt,
    this.teacherDayJoinAt,
    this.teacherBookingJoinCount = 0,
    this.meetingUrl,
    this.adminDecision,
    this.adminNotes,
    this.rebookingGranted = false,
    this.bookingType,
    this.attemptNumber,
    this.learningWeek,
    this.levelName,
  });

  factory AttendanceIssueDto.fromJson(Map<String, dynamic> json) {
    return AttendanceIssueDto(
      id: json['id'] as String? ?? '',
      issueType: json['issue_type'] as String? ?? '',
      status: json['verification_status'] as String? ?? 'pending',
      studentName: json['student_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      studentId: json['student_id'] as String?,
      teacherId: json['teacher_id'] as String?,
      date: json['date'] as String?,
      start: json['start'] as String?,
      message: json['message'] as String?,
      studentJoinCount: (json['student_join_count'] as num?)?.toInt() ?? 0,
      studentFirstJoinAt: json['student_first_join_at'] as String?,
      teacherDayJoinAt: json['teacher_day_join_at'] as String?,
      teacherBookingJoinCount: (json['teacher_booking_join_count'] as num?)?.toInt() ?? 0,
      meetingUrl: json['meeting_url'] as String?,
      adminDecision: json['admin_decision'] as String?,
      adminNotes: json['admin_notes'] as String?,
      rebookingGranted: json['rebooking_granted'] as bool? ?? false,
      bookingType: json['booking_type'] as String?,
      attemptNumber: (json['attempt_number'] as num?)?.toInt(),
      learningWeek: (json['learning_week'] as num?)?.toInt(),
      levelName: json['level_name'] as String?,
    );
  }

  final String id;
  final String issueType;
  final String status;
  final String? studentName;
  final String? teacherName;
  final String? studentId;
  final String? teacherId;
  final String? date;
  final String? start;
  final String? message;
  final int studentJoinCount;
  final String? studentFirstJoinAt;
  final String? teacherDayJoinAt;
  final int teacherBookingJoinCount;
  final String? meetingUrl;
  final String? adminDecision;
  final String? adminNotes;
  final bool rebookingGranted;
  final String? bookingType;
  final int? attemptNumber;
  final int? learningWeek;
  final String? levelName;

  String get issueLabel =>
      issueType == 'student_did_not_join' ? "Student didn't join" : "Teacher didn't join";

  String get classLabel => bookingType == 'master_class' ? 'Master Class' : 'Introduction Call';

  String get attemptLabel => attemptNumber == null ? '—' : '$attemptNumber';

  String get weekLabel => learningWeek == null ? '—' : '$learningWeek';
}

class ScheduleDayDto {
  const ScheduleDayDto({
    required this.date,
    required this.slots,
    this.breaks = const [],
    this.leaves = const [],
    this.bookings = const [],
  });

  factory ScheduleDayDto.fromJson(Map<String, dynamic> json) {
    return ScheduleDayDto(
      date: json['date'] as String? ?? '',
      slots: (json['slots'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ScheduleSlotDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      breaks: (json['breaks'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ScheduleBreakDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      leaves: (json['leaves'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ScheduleLeaveDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      bookings: (json['bookings'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => SessionBookingDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String date;
  final List<ScheduleSlotDto> slots;
  final List<ScheduleBreakDto> breaks;
  final List<ScheduleLeaveDto> leaves;
  final List<SessionBookingDto> bookings;
}

class ScheduleMonthDayDto {
  const ScheduleMonthDayDto({
    required this.date,
    required this.available,
    required this.booked,
    required this.leave,
    required this.hasFullDayLeave,
  });

  factory ScheduleMonthDayDto.fromJson(Map<String, dynamic> json) {
    return ScheduleMonthDayDto(
      date: json['date'] as String? ?? '',
      available: (json['available'] as num?)?.toInt() ?? 0,
      booked: (json['booked'] as num?)?.toInt() ?? 0,
      leave: (json['leave'] as num?)?.toInt() ?? 0,
      hasFullDayLeave: json['has_full_day_leave'] as bool? ?? false,
    );
  }

  final String date;
  final int available;
  final int booked;
  final int leave;
  final bool hasFullDayLeave;
}

class BookingEligibilityDto {
  const BookingEligibilityDto({
    required this.introductionCompleted,
    required this.canBookIntroduction,
    required this.canBookMasterClass,
    this.introductionLastChance = false,
    this.levelStartedOn,
  });

  factory BookingEligibilityDto.fromJson(Map<String, dynamic> json) {
    return BookingEligibilityDto(
      introductionCompleted: json['introduction_completed'] as bool? ?? false,
      canBookIntroduction: json['can_book_introduction'] as bool? ?? false,
      canBookMasterClass: json['can_book_master_class'] as bool? ?? false,
      introductionLastChance: json['introduction_last_chance'] as bool? ?? false,
      levelStartedOn: json['level_started_on'] as String?,
    );
  }

  final bool introductionCompleted;
  final bool canBookIntroduction;
  final bool canBookMasterClass;
  final bool introductionLastChance;
  final String? levelStartedOn;
}

class GoogleMeetConnectionDto {
  const GoogleMeetConnectionDto({
    required this.connected,
    this.googleEmail,
    this.connectedAt,
    this.redirectUri,
  });

  factory GoogleMeetConnectionDto.fromJson(Map<String, dynamic> json) {
    return GoogleMeetConnectionDto(
      connected: json['connected'] as bool? ?? false,
      googleEmail: json['google_email'] as String?,
      connectedAt: json['connected_at'] as String?,
      redirectUri: json['redirect_uri'] as String?,
    );
  }

  final bool connected;
  final String? googleEmail;
  final String? connectedAt;
  final String? redirectUri;
}

String ordinal(int value) {
  final mod100 = value % 100;
  if (mod100 >= 11 && mod100 <= 13) {
    return '${value}th';
  }
  switch (value % 10) {
    case 1:
      return '${value}st';
    case 2:
      return '${value}nd';
    case 3:
      return '${value}rd';
    default:
      return '${value}th';
  }
}

String formatHm(String hm) {
  final parts = hm.split(':');
  if (parts.length < 2) return hm;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$display:$minute $suffix';
}

DateTime scheduleDateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime scheduleToday() => scheduleDateOnly(DateTime.now());

bool isScheduleDatePast(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return false;
  return scheduleDateOnly(parsed).isBefore(scheduleToday());
}

String formatScheduleDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String formatPrettyDate(String ymd) {
  final parsed = DateTime.tryParse(ymd);
  if (parsed == null) {
    return ymd;
  }
  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = [
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
  return '${weekdays[parsed.weekday - 1]} · ${parsed.day} ${months[parsed.month - 1]}';
}
