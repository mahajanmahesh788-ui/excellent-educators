import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/navigation/app_navigation.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';
import 'package:flutter/material.dart';

/// Soft dashboard prompt when parent intake was skipped or never completed.
class ParentIntakeReminderBanner extends StatelessWidget {
  const ParentIntakeReminderBanner({super.key, required this.student});

  final StudentDto student;

  static bool shouldShow(StudentDto student) {
    return student.parentIntake?.needsReminder ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(student)) {
      return const SizedBox.shrink();
    }

    final skipped = student.parentIntake?.skipped ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openOnboarding(context, RoutePaths.studentParentIntake),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.parchmentCream,
                AppColors.parchmentPeach,
                AppColors.parchmentWarm,
              ],
            ),
            border: Border.all(color: AppColors.parchmentTan),
            boxShadow: [
              BoxShadow(
                color: StudentColors.forestDeep.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: StudentColors.forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: StudentColors.forest.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: StudentColors.forest,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentDark.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: AppColors.accentDark.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              skipped
                                  ? AppStrings.skippedForNow
                                  : AppStrings.parentDetailsMissingBadge,
                              style: const TextStyle(
                                color: AppColors.warningOrangeDark,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppStrings.parentDetailsMissingTitle,
                        style: TextStyle(
                          color: StudentColors.forestDeep,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.parentDetailsMissingBody,
                        style: TextStyle(
                          color: StudentColors.forestDeep.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () => openOnboarding(
                                context,
                                RoutePaths.studentParentIntake,
                              ),
                          style: FilledButton.styleFrom(
                            backgroundColor: StudentColors.forest,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text(
                            AppStrings.parentDetailsMissingCta,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
