import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const statusFilterItems = [
  DropdownMenuItem(value: 'active', child: Text('Active')),
  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
];

const studentAttentionFilterItems = [
  DropdownMenuItem(value: 'without_batch', child: Text('Not in a batch')),
  DropdownMenuItem(value: 'without_master_teacher', child: Text('Without Master Teacher')),
  DropdownMenuItem(value: 'assessment_pending', child: Text('Assessment pending')),
  DropdownMenuItem(value: 'without_rating_this_month', child: Text('No monthly rating')),
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
