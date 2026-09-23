class FeedbackItemDto {
  const FeedbackItemDto({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.rating,
    this.positivePoints,
    this.areasForImprovement,
    this.recommendedNextAction,
  });

  factory FeedbackItemDto.fromJson(Map<String, dynamic> json) {
    return FeedbackItemDto(
      id: json['id'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      targetName: json['target_name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      positivePoints: json['positive_points'] as String?,
      areasForImprovement: json['areas_for_improvement'] as String?,
      recommendedNextAction: json['recommended_next_action'] as String?,
    );
  }

  final String id;
  final String targetType;
  final String targetId;
  final String targetName;
  final int rating;
  final String? positivePoints;
  final String? areasForImprovement;
  final String? recommendedNextAction;
}

class MonthlyFeedbackDto {
  const MonthlyFeedbackDto({
    required this.id,
    required this.year,
    required this.month,
    required this.editable,
    required this.deletable,
    required this.items,
    this.sessionDate,
    this.sessionBookingId,
    this.submittedAt,
    this.editableUntil,
    this.masterTeacherName,
    this.overallRating,
    this.positivePoints,
    this.areasForImprovement,
    this.discussedInClass,
  });

  factory MonthlyFeedbackDto.fromJson(Map<String, dynamic> json) {
    return MonthlyFeedbackDto(
      id: json['id'] as String,
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      sessionDate: json['session_date'] as String?,
      sessionBookingId: json['session_booking_id'] as String?,
      submittedAt: json['submitted_at'] as String?,
      editable: json['editable'] == true,
      deletable: json['deletable'] == true,
      editableUntil: json['editable_until'] as String?,
      masterTeacherName: json['master_teacher'] is Map
          ? (json['master_teacher'] as Map)['full_name'] as String?
          : null,
      overallRating: (json['overall_rating'] as num?)?.toDouble(),
      positivePoints: json['positive_points'] as String?,
      areasForImprovement: json['areas_for_improvement'] as String?,
      discussedInClass: json['discussed_in_class'] as String?,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FeedbackItemDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String id;
  final int year;
  final int month;
  final String? sessionDate;
  final String? sessionBookingId;
  final String? submittedAt;
  final bool editable;
  final bool deletable;
  final String? editableUntil;
  final String? masterTeacherName;
  final double? overallRating;
  final String? positivePoints;
  final String? areasForImprovement;
  final String? discussedInClass;
  final List<FeedbackItemDto> items;

  double? get averageRating {
    if (overallRating != null) {
      return overallRating;
    }
    if (items.isEmpty) {
      return null;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.rating);
    return total / items.length;
  }

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
}

class FeedbackMonthSummaryDto {
  const FeedbackMonthSummaryDto({
    required this.year,
    required this.month,
    required this.averageRating,
    required this.sessionCount,
  });

  factory FeedbackMonthSummaryDto.fromJson(Map<String, dynamic> json) {
    return FeedbackMonthSummaryDto(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
    );
  }

  final int year;
  final int month;
  final double? averageRating;
  final int sessionCount;

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

class FeedbackDimensionSummaryDto {
  const FeedbackDimensionSummaryDto({
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.averageRating,
    required this.sessionCount,
  });

  factory FeedbackDimensionSummaryDto.fromJson(Map<String, dynamic> json) {
    return FeedbackDimensionSummaryDto(
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      targetName: json['target_name'] as String? ?? '',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String targetType;
  final String targetId;
  final String targetName;
  final double averageRating;
  final int sessionCount;
}

class FeedbackSummaryDto {
  const FeedbackSummaryDto({
    required this.overallAverage,
    required this.totalSessions,
    required this.byMonth,
    required this.byDimension,
  });

  factory FeedbackSummaryDto.fromJson(Map<String, dynamic> json) {
    return FeedbackSummaryDto(
      overallAverage: (json['overall_average'] as num?)?.toDouble(),
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      byMonth: (json['by_month'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FeedbackMonthSummaryDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      byDimension: (json['by_dimension'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FeedbackDimensionSummaryDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final double? overallAverage;
  final int totalSessions;
  final List<FeedbackMonthSummaryDto> byMonth;
  final List<FeedbackDimensionSummaryDto> byDimension;
}

class FeedbackSkillDto {
  const FeedbackSkillDto({required this.id, required this.name});

  factory FeedbackSkillDto.fromJson(Map<String, dynamic> json) {
    return FeedbackSkillDto(id: json['id'] as String, name: json['name'] as String? ?? '');
  }

  final String id;
  final String name;
}

class FeedbackModuleDto {
  const FeedbackModuleDto({required this.id, required this.name, required this.skills});

  factory FeedbackModuleDto.fromJson(Map<String, dynamic> json) {
    return FeedbackModuleDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FeedbackSkillDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String id;
  final String name;
  final List<FeedbackSkillDto> skills;
}

class FeedbackDimensionDto {
  const FeedbackDimensionDto({
    required this.id,
    required this.code,
    required this.name,
    required this.modules,
  });

  factory FeedbackDimensionDto.fromJson(Map<String, dynamic> json) {
    return FeedbackDimensionDto(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      modules: (json['modules'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FeedbackModuleDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String id;
  final String code;
  final String name;
  final List<FeedbackModuleDto> modules;
}
