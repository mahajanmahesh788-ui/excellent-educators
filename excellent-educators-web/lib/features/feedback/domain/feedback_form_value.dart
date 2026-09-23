import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';

class FeedbackFormValue {
  const FeedbackFormValue({
    required this.ratings,
    required this.positivePoints,
    this.bookingId,
    this.sessionDate,
    this.areasForImprovement = '',
    this.discussedInClass = '',
  });

  final String? bookingId;
  final String? sessionDate;
  final Map<String, int> ratings;
  final String positivePoints;
  final String areasForImprovement;
  final String discussedInClass;

  static String? validate(FeedbackFormValue value, {required int expectedCount}) {
    if (value.ratings.length != expectedCount) {
      return AppStrings.rateAllTenDimensions;
    }
    if (value.ratings.values.any((rating) => rating < 1 || rating > 10)) {
      return AppStrings.ratingMustBeBetween1And10;
    }
    if (value.positivePoints.trim().isEmpty) {
      return AppStrings.positivePointsAreRequired;
    }
    return null;
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      if (bookingId != null && bookingId!.isNotEmpty) 'booking_id': bookingId,
      if (sessionDate != null && sessionDate!.isNotEmpty) 'session_date': sessionDate,
      'positive_points': positivePoints.trim(),
      'areas_for_improvement': areasForImprovement.trim().isEmpty ? null : areasForImprovement.trim(),
      'discussed_in_class': discussedInClass.trim().isEmpty ? null : discussedInClass.trim(),
      'items': [
        for (final entry in ratings.entries)
          {
            'target_type': 'dimension',
            'target_id': entry.key,
            'rating': entry.value,
          },
      ],
    };
  }

  Map<String, dynamic> toUpdatePayload() => toCreatePayload();
}

class FeedbackCatalogDimension {
  const FeedbackCatalogDimension({required this.id, required this.name});

  factory FeedbackCatalogDimension.fromDto(FeedbackDimensionDto dto) {
    return FeedbackCatalogDimension(id: dto.id, name: dto.name);
  }

  final String id;
  final String name;
}
