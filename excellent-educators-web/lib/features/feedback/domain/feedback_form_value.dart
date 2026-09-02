class FeedbackFormValue {
  const FeedbackFormValue({
    required this.sessionDate,
    required this.targetType,
    required this.targetId,
    required this.rating,
    this.positivePoints = '',
    this.areasForImprovement = '',
  });

  final String sessionDate;
  final String targetType;
  final String targetId;
  final int rating;
  final String positivePoints;
  final String areasForImprovement;

  static String? validate(FeedbackFormValue value) {
    if (value.sessionDate.isEmpty) {
      return 'Class date is required.';
    }
    if (!const {'skill', 'module', 'dimension'}.contains(value.targetType)) {
      return 'Choose Skill, Module, or Dimension.';
    }
    if (value.targetId.isEmpty) {
      return 'Choose a target.';
    }
    if (value.rating < 1 || value.rating > 10) {
      return 'Rating must be between 1 and 10.';
    }
    return null;
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'session_date': sessionDate,
      'items': [_item()],
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {'items': [_item()]};
  }

  Map<String, dynamic> _item() {
    return {
      'target_type': targetType,
      'target_id': targetId,
      'rating': rating,
      'positive_points': positivePoints.trim().isEmpty ? null : positivePoints.trim(),
      'areas_for_improvement': areasForImprovement.trim().isEmpty ? null : areasForImprovement.trim(),
    };
  }
}
