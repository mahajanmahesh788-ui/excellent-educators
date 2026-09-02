import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Student shell — keeps profile accessible; locks results/feedback until assessment is done.
class StudentScaffold extends ConsumerWidget {
  const StudentScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.backTo,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? backTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(studentAssessmentProvider);
    final pending = assessment.maybeWhen(
      data: (payload) => payload.available && payload.assessment != null,
      orElse: () => false,
    );

    return AppScaffold(
      title: title,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      backTo: backTo,
      disabledNavPaths: pending ? const [RoutePaths.studentFeedback] : const [],
    );
  }
}
