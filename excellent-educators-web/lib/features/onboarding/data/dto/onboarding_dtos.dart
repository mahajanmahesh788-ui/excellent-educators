class InterestOptionDto {
  InterestOptionDto({
    required this.id,
    required this.optionText,
    this.source = 'admin',
    this.displayOrder = 0,
    this.isActive = true,
    this.usageCount = 0,
  });

  factory InterestOptionDto.fromJson(Map<String, dynamic> json) {
    return InterestOptionDto(
      id: json['id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? '',
      source: json['source'] as String? ?? 'admin',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] != false,
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String optionText;
  final String source;
  final int displayOrder;
  final bool isActive;
  final int usageCount;

  bool get isFromStudents => source == 'student';
}

class InterestQuestionDto {
  InterestQuestionDto({
    required this.id,
    required this.questionText,
    this.allowOther = true,
    this.maxSelections = 5,
    this.displayOrder = 0,
    this.isActive = true,
    this.options = const [],
  });

  factory InterestQuestionDto.fromJson(Map<String, dynamic> json) {
    return InterestQuestionDto(
      id: json['id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      allowOther: json['allow_other'] != false,
      maxSelections: (json['max_selections'] as num?)?.toInt() ?? 5,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] != false,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => InterestOptionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String questionText;
  final bool allowOther;
  final int maxSelections;
  final int displayOrder;
  final bool isActive;
  final List<InterestOptionDto> options;
}

class ParentOptionDto {
  ParentOptionDto({
    required this.id,
    required this.optionText,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory ParentOptionDto.fromJson(Map<String, dynamic> json) {
    return ParentOptionDto(
      id: json['id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? '',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] != false,
    );
  }

  final String id;
  final String optionText;
  final int displayOrder;
  final bool isActive;
}

class ParentQuestionDto {
  ParentQuestionDto({
    required this.id,
    required this.questionText,
    required this.questionType,
    this.displayOrder = 0,
    this.isActive = true,
    this.options = const [],
  });

  factory ParentQuestionDto.fromJson(Map<String, dynamic> json) {
    return ParentQuestionDto(
      id: json['id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      questionType: json['question_type'] as String? ?? 'text',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] != false,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ParentOptionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String questionText;
  final String questionType;
  final int displayOrder;
  final bool isActive;
  final List<ParentOptionDto> options;

  bool get isText => questionType == 'text';
  bool get isOptions => questionType == 'options';
}

class SavedInterestAnswerDto {
  SavedInterestAnswerDto({
    this.optionIds = const [],
    this.otherText = '',
  });

  factory SavedInterestAnswerDto.fromJson(Map<String, dynamic> json) {
    return SavedInterestAnswerDto(
      optionIds: (json['option_ids'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      otherText: json['other_text'] as String? ?? '',
    );
  }

  final List<String> optionIds;
  final String otherText;
}

class SavedParentAnswerDto {
  SavedParentAnswerDto({
    this.optionId,
    this.textAnswer = '',
  });

  factory SavedParentAnswerDto.fromJson(Map<String, dynamic> json) {
    return SavedParentAnswerDto(
      optionId: json['option_id'] as String?,
      textAnswer: json['text_answer'] as String? ?? '',
    );
  }

  final String? optionId;
  final String textAnswer;
}

class InterestProfileDto {
  InterestProfileDto({
    required this.completed,
    required this.questions,
    this.savedAnswers = const {},
  });

  factory InterestProfileDto.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['saved_answers'];
    final saved = <String, SavedInterestAnswerDto>{};
    if (rawAnswers is Map) {
      rawAnswers.forEach((key, value) {
        if (value is Map) {
          saved[key.toString()] = SavedInterestAnswerDto.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    return InterestProfileDto(
      completed: json['completed'] == true,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => InterestQuestionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      savedAnswers: saved,
    );
  }

  final bool completed;
  final List<InterestQuestionDto> questions;
  final Map<String, SavedInterestAnswerDto> savedAnswers;
}

class ParentIntakeDto {
  ParentIntakeDto({
    required this.completed,
    required this.skipped,
    required this.questions,
    this.savedAnswers = const {},
  });

  factory ParentIntakeDto.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['saved_answers'];
    final saved = <String, SavedParentAnswerDto>{};
    if (rawAnswers is Map) {
      rawAnswers.forEach((key, value) {
        if (value is Map) {
          saved[key.toString()] = SavedParentAnswerDto.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    return ParentIntakeDto(
      completed: json['completed'] == true,
      skipped: json['skipped'] == true,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ParentQuestionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      savedAnswers: saved,
    );
  }

  final bool completed;
  final bool skipped;
  final List<ParentQuestionDto> questions;
  final Map<String, SavedParentAnswerDto> savedAnswers;
}
