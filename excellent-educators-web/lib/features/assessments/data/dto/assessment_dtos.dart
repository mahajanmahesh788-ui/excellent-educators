import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';

class AptitudeOptionDto {
  const AptitudeOptionDto({
    required this.id,
    required this.optionText,
    required this.displayOrder,
    this.dimensionCodes = const [],
    this.dimensionNames = const [],
  });

  factory AptitudeOptionDto.fromJson(Map<String, dynamic> json) {
    final codes = (json['dimension_codes'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final legacyCode = json['dimension_code'] as String?;
    final resolvedCodes = codes.isNotEmpty
        ? codes
        : legacyCode == null
            ? const <String>[]
            : [legacyCode];

    return AptitudeOptionDto(
      id: json['id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      dimensionCodes: resolvedCodes,
      dimensionNames: (json['dimension_names'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  final String id;
  final String optionText;
  final int displayOrder;
  final List<String> dimensionCodes;
  final List<String> dimensionNames;
}

class AptitudeQuestionDto {
  const AptitudeQuestionDto({
    required this.id,
    required this.questionText,
    required this.displayOrder,
    required this.options,
  });

  factory AptitudeQuestionDto.fromJson(Map<String, dynamic> json) {
    return AptitudeQuestionDto(
      id: json['id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AptitudeOptionDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String id;
  final String questionText;
  final int displayOrder;
  final List<AptitudeOptionDto> options;
}

class AptitudeAssessmentDto {
  const AptitudeAssessmentDto({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.careerCompassLevel,
    this.careerCompassLevelId,
    this.questionsCount = 0,
    this.submittedAttemptsCount = 0,
    this.questions = const [],
    this.createdAt,
  });

  factory AptitudeAssessmentDto.fromJson(Map<String, dynamic> json) {
    return AptitudeAssessmentDto(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'draft',
      careerCompassLevel: json['career_compass_level'] is Map
          ? CareerCompassLevelDto.fromJson(Map<String, dynamic>.from(json['career_compass_level'] as Map))
          : null,
      careerCompassLevelId: json['career_compass_level_id'] as String?,
      questionsCount: (json['questions_count'] as num?)?.toInt() ??
          (json['questions'] as List?)?.length ??
          0,
      submittedAttemptsCount: (json['submitted_attempts_count'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AptitudeQuestionDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String title;
  final String? description;
  final String status;
  final CareerCompassLevelDto? careerCompassLevel;
  final String? careerCompassLevelId;
  final int questionsCount;
  final int submittedAttemptsCount;
  final List<AptitudeQuestionDto> questions;
  final String? createdAt;

  bool get hasSubmissions => submittedAttemptsCount > 0;
}

class StudentAssessmentPayload {
  const StudentAssessmentPayload({
    required this.available,
    this.reason,
    this.assessment,
  });

  factory StudentAssessmentPayload.fromJson(Map<String, dynamic> json) {
    return StudentAssessmentPayload(
      available: json['available'] == true,
      reason: json['reason'] as String?,
      assessment: json['assessment'] is Map
          ? AptitudeAssessmentDto.fromJson(Map<String, dynamic>.from(json['assessment'] as Map))
          : null,
    );
  }

  final bool available;
  final String? reason;
  final AptitudeAssessmentDto? assessment;
}

class DimensionScoreDto {
  const DimensionScoreDto({required this.name, required this.score, this.code});

  factory DimensionScoreDto.fromJson(Map<String, dynamic> json) {
    return DimensionScoreDto(
      name: json['name'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      code: json['code'] as String?,
    );
  }

  final String name;
  final int score;
  final String? code;
}

class AssessmentResultDto {
  const AssessmentResultDto({
    required this.id,
    required this.dimensions,
    this.assessmentTitle,
    this.assessmentId,
    this.careerCompassLevel,
    this.submittedAt,
    this.studentName,
  });

  factory AssessmentResultDto.fromJson(Map<String, dynamic> json) {
    final assessment = json['assessment'] is Map ? json['assessment'] as Map : null;
    return AssessmentResultDto(
      id: json['id'] as String? ?? '',
      assessmentId: assessment?['id'] as String?,
      assessmentTitle: assessment?['title'] as String?,
      careerCompassLevel: json['career_compass_level'] is Map
          ? CareerCompassLevelDto.fromJson(Map<String, dynamic>.from(json['career_compass_level'] as Map))
          : null,
      submittedAt: json['submitted_at'] as String?,
      studentName: json['student'] is Map ? (json['student'] as Map)['full_name'] as String? : null,
      dimensions: (json['dimensions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => DimensionScoreDto.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  final String id;
  final String? assessmentId;
  final String? assessmentTitle;
  final CareerCompassLevelDto? careerCompassLevel;
  final String? submittedAt;
  final String? studentName;
  final List<DimensionScoreDto> dimensions;
}
