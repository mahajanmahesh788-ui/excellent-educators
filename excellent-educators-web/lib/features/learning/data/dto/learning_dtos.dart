class LearningNamedRef {
  const LearningNamedRef({required this.id, required this.name});

  factory LearningNamedRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LearningNamedRef(id: '', name: '');
    }
    return LearningNamedRef(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
    );
  }

  final String id;
  final String name;
}

class LearningWeekDto {
  const LearningWeekDto({
    required this.journeyId,
    required this.level,
    required this.weekNumber,
    required this.assignmentStatus,
    required this.attemptsUsed,
    required this.attemptsMax,
    required this.canSubmit,
    required this.hasVideo,
    this.videoUrl,
    this.studyDate,
    this.month,
    this.year,
    this.studentName,
    this.currentLevelName,
    this.questions = const [],
    this.attempts = const [],
    this.score,
  });

  factory LearningWeekDto.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map ? Map<String, dynamic>.from(json['student'] as Map) : null;
    return LearningWeekDto(
      journeyId: json['journey_id'] as String? ?? '',
      level: LearningNamedRef.fromJson(
        json['level'] is Map ? Map<String, dynamic>.from(json['level'] as Map) : null,
      ),
      weekNumber: (json['week_number'] as num?)?.toInt() ?? 0,
      assignmentStatus: json['assignment_status'] as String? ?? 'pending',
      attemptsUsed: (json['attempts_used'] as num?)?.toInt() ?? 0,
      attemptsMax: (json['attempts_max'] as num?)?.toInt() ?? 2,
      canSubmit: json['can_submit'] as bool? ?? false,
      hasVideo: json['has_video'] as bool? ?? false,
      videoUrl: json['video_url'] as String?,
      studyDate: json['study_date'] as String?,
      month: json['month'] as String?,
      year: (json['year'] as num?)?.toInt(),
      studentName: student?['full_name'] as String?,
      currentLevelName: student?['current_level'] as String?,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => LearningQuestionDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      attempts: (json['attempts'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => LearningAttemptDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      score: json['score'] is Map
          ? LearningWeekScoreDto.fromJson(Map<String, dynamic>.from(json['score'] as Map))
          : null,
    );
  }

  final String journeyId;
  final LearningNamedRef level;
  final int weekNumber;
  final String assignmentStatus;
  final int attemptsUsed;
  final int attemptsMax;
  final bool canSubmit;
  final bool hasVideo;
  final String? videoUrl;
  final String? studyDate;
  final String? month;
  final int? year;
  final String? studentName;
  final String? currentLevelName;
  final List<LearningQuestionDto> questions;
  final List<LearningAttemptDto> attempts;
  final LearningWeekScoreDto? score;

  bool get completed => assignmentStatus == 'completed';
}

class LearningWeekScoreDto {
  const LearningWeekScoreDto({
    required this.correct,
    required this.total,
    required this.percentage,
    required this.display,
    this.attemptNumber,
  });

  factory LearningWeekScoreDto.fromJson(Map<String, dynamic> json) {
    return LearningWeekScoreDto(
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      display: json['display'] as String? ?? '',
      attemptNumber: (json['attempt_number'] as num?)?.toInt(),
    );
  }

  final int correct;
  final int total;
  final int percentage;
  final String display;
  final int? attemptNumber;
}

class LearningQuestionDto {
  const LearningQuestionDto({
    required this.id,
    required this.questionText,
    required this.options,
  });

  factory LearningQuestionDto.fromJson(Map<String, dynamic> json) {
    return LearningQuestionDto(
      id: json['id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => LearningOptionDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String id;
  final String questionText;
  final List<LearningOptionDto> options;
}

class LearningOptionDto {
  const LearningOptionDto({
    required this.id,
    required this.optionText,
    this.isCorrect,
  });

  factory LearningOptionDto.fromJson(Map<String, dynamic> json) {
    return LearningOptionDto(
      id: json['id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? '',
      isCorrect: json['is_correct'] as bool?,
    );
  }

  final String id;
  final String optionText;
  final bool? isCorrect;
}

class LearningAttemptDto {
  const LearningAttemptDto({
    required this.attemptNumber,
    required this.answers,
    this.submittedAt,
    this.videoUrl,
  });

  factory LearningAttemptDto.fromJson(Map<String, dynamic> json) {
    return LearningAttemptDto(
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 0,
      submittedAt: json['submitted_at'] as String?,
      videoUrl: json['video_url'] as String?,
      answers: (json['answers'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  final int attemptNumber;
  final String? submittedAt;
  final String? videoUrl;
  final List<Map<String, dynamic>> answers;

  String? optionIdFor(String questionId) {
    for (final answer in answers) {
      if (answer['question_id'] == questionId) {
        return answer['option_id'] as String?;
      }
    }
    return null;
  }
}

class LearningLevelGroupDto {
  const LearningLevelGroupDto({
    required this.level,
    required this.journeyId,
    required this.isCurrent,
    required this.weekCount,
    required this.weeks,
  });

  factory LearningLevelGroupDto.fromJson(Map<String, dynamic> json) {
    return LearningLevelGroupDto(
      level: LearningNamedRef.fromJson(
        json['level'] is Map ? Map<String, dynamic>.from(json['level'] as Map) : null,
      ),
      journeyId: json['journey_id'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      weekCount: (json['week_count'] as num?)?.toInt() ?? 0,
      weeks: (json['weeks'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => LearningWeekDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final LearningNamedRef level;
  final String journeyId;
  final bool isCurrent;
  final int weekCount;
  final List<LearningWeekDto> weeks;
}

class LearningJournalDto {
  const LearningJournalDto({
    required this.levels,
    this.studentName,
    this.currentLevelName,
  });

  factory LearningJournalDto.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map ? Map<String, dynamic>.from(json['student'] as Map) : null;
    return LearningJournalDto(
      studentName: student?['full_name'] as String?,
      currentLevelName: student?['current_level'] as String?,
      levels: (json['levels'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => LearningLevelGroupDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String? studentName;
  final String? currentLevelName;
  final List<LearningLevelGroupDto> levels;
}

class LearningDashboardDto {
  const LearningDashboardDto({
    required this.currentWeek,
    required this.nextAction,
    required this.ctaLabel,
    required this.completedWeeks,
    required this.totalWeeks,
    this.currentLevel,
    this.week,
  });

  factory LearningDashboardDto.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] is Map ? Map<String, dynamic>.from(json['progress'] as Map) : const {};
    return LearningDashboardDto(
      currentLevel: json['current_level'] is Map
          ? LearningNamedRef.fromJson(Map<String, dynamic>.from(json['current_level'] as Map))
          : null,
      currentWeek: (json['current_week'] as num?)?.toInt() ?? 0,
      nextAction: json['next_action'] as String? ?? '',
      ctaLabel: json['cta_label'] as String? ?? '',
      completedWeeks: (progress['completed_weeks'] as num?)?.toInt() ?? 0,
      totalWeeks: (progress['total_weeks'] as num?)?.toInt() ?? 52,
      week: json['week'] is Map ? LearningWeekDto.fromJson(Map<String, dynamic>.from(json['week'] as Map)) : null,
    );
  }

  final LearningNamedRef? currentLevel;
  final int currentWeek;
  final String nextAction;
  final String ctaLabel;
  final int completedWeeks;
  final int totalWeeks;
  final LearningWeekDto? week;

  bool get assignmentPending => !(week?.completed ?? false);
}

class WeeklyLearningContentDto {
  const WeeklyLearningContentDto({
    required this.id,
    required this.levelId,
    required this.weekNumber,
    required this.videoUrl,
    required this.questions,
  });

  factory WeeklyLearningContentDto.fromJson(Map<String, dynamic> json) {
    return WeeklyLearningContentDto(
      id: json['id'] as String? ?? '',
      levelId: json['level_id'] as String? ?? '',
      weekNumber: (json['week_number'] as num?)?.toInt() ?? 0,
      videoUrl: json['video_url'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => LearningQuestionDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String id;
  final String levelId;
  final int weekNumber;
  final String videoUrl;
  final List<LearningQuestionDto> questions;
}
