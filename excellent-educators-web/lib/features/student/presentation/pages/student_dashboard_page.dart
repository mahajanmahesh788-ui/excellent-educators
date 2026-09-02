import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/feedback_read_only_card.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/mandatory_assessment_panel.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);
    final assessment = ref.watch(studentAssessmentProvider);
    final feedback = ref.watch(studentFeedbackProvider);
    final assessmentPending = assessment.maybeWhen(
      data: (payload) => payload.available && payload.assessment != null,
      orElse: () => false,
    );
    final assessmentCompleted = assessment.maybeWhen(
      data: (payload) => payload.reason == 'already_completed',
      orElse: () => false,
    );

    return StudentScaffold(
      title: 'Dashboard',
      body: AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(studentProfileProvider),
        builder: (student) {
          if (assessmentPending) {
            return ListView(
              children: [
                _hero(student),
                const SizedBox(height: 20),
                const MandatoryAssessmentPanel(),
                const SizedBox(height: 24),
              ],
            );
          }

          return ListView(
            children: [
              _hero(student),
              const SizedBox(height: 20),
              if (assessmentCompleted)
                StudentSectionCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Assessment submitted',
                  child: Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 48, color: Brand.gold.withValues(alpha: 0.75)),
                      const SizedBox(height: 12),
                      const Text(
                        'Thank you for completing your aptitude assessment. Detailed dimension results are shared with your teachers only — they will review them and share monthly feedback with you here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Brand.muted, height: 1.45),
                      ),
                    ],
                  ),
                ),
              if (assessmentCompleted) const SizedBox(height: 16),
              AsyncBody(
                value: feedback,
                onRetry: () => ref.invalidate(studentFeedbackProvider),
                builder: (feedbackItems) {
                  if (feedbackItems.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return StudentSectionCard(
                    icon: Icons.rate_review_rounded,
                    title: 'Latest feedback',
                    action: TextButton(
                      onPressed: () => context.go(RoutePaths.studentFeedback),
                      child: const Text('See all'),
                    ),
                    child: FeedbackReadOnlyCard(feedback: feedbackItems.first),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(StudentDto student) {
    return StudentHeroCard(
      title: 'Hello, ${student.fullName.split(' ').first}!',
      subtitle: student.careerCompassLevel?.displayName ?? 'Your learning journey starts here.',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Brand.gold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
        ),
        child: Text(
          student.studentCode,
          style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          StudentStatChip(
            icon: Icons.school_rounded,
            label: 'Career Compass',
            value: student.careerCompassLevel?.shortCode ?? '—',
          ),
          StudentStatChip(
            icon: Icons.groups_rounded,
            label: 'Batch',
            value: student.batch?.label ?? 'Not assigned',
            accent: const Color(0xFF4E8BC9),
          ),
          StudentStatChip(
            icon: Icons.psychology_alt_rounded,
            label: 'Master Teacher',
            value: student.masterTeacher?.label ?? 'Not assigned',
            accent: const Color(0xFF5BB98C),
          ),
        ],
      ),
    );
  }
}
