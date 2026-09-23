import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

const statusFilterItems = [
  DropdownMenuItem(value: 'active', child: Text(AppStrings.active)),
  DropdownMenuItem(value: 'inactive', child: Text(AppStrings.inactive)),
];

const studentAttentionFilterItems = [
  DropdownMenuItem(value: 'without_batch', child: Text(AppStrings.notInABatch)),
  DropdownMenuItem(value: 'assessment_pending', child: Text(AppStrings.assessmentPending)),
  DropdownMenuItem(value: 'without_rating_this_month', child: Text(AppStrings.noMonthlyRating)),
  DropdownMenuItem(value: 'top_rated', child: Text(AppStrings.topRated)),
  DropdownMenuItem(value: 'longest', child: Text(AppStrings.longestWithUs)),
  DropdownMenuItem(value: 'promoted', child: Text(AppStrings.levelledUp)),
];

final teacherBatchAssessmentsProvider =
    FutureProvider.autoDispose.family<List<AssessmentDto>, String>((ref, batchId) {
  return ref.watch(academicRepositoryProvider).teacherBatchAssessments(batchId);
});

final teacherAssessmentProvider =
    FutureProvider.autoDispose.family<AssessmentDto, ({String batchId, String assessmentId})>((ref, args) {
  return ref.watch(academicRepositoryProvider).teacherAssessment(args.batchId, args.assessmentId);
});

final teacherAssessmentScoresProvider =
    FutureProvider.autoDispose.family<AssessmentScoresPayload, ({String batchId, String assessmentId})>((ref, args) {
  return ref.watch(academicRepositoryProvider).teacherAssessmentScores(args.batchId, args.assessmentId);
});
