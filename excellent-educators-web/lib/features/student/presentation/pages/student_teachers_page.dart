import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/navigation/app_navigation.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_view.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentTeachersPage extends ConsumerWidget {
  const StudentTeachersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);
    final eligibility = ref.watch(studentEligibilityProvider);

    return StudentScaffold(
      title: AppStrings.teachers,
      // Opened from Dashboard → View Teachers; never dump users on My Sessions.
      backTo: RoutePaths.studentDashboard,
      body: profile.when(
        skipLoadingOnReload: true,
        loading: () => const AcademySkeleton(height: 280),
        error: (_, _) =>
            AcademyError(onRetry: () => ref.invalidate(studentProfileProvider)),
        data: (student) {
          final type = eligibility.maybeWhen(
            data: (value) => value.canBookIntroduction
                ? 'introduction_call'
                : value.canBookMasterClass
                ? 'master_class'
                : null,
            orElse: () => null,
          );
          return ListView(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              const Text(
                AppStrings.yourTeachers,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Academy.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                type == null
                    ? AppStrings.theseMasterTeachersGuideYourLevel
                    : AppStrings
                          .theseMasterTeachersGuideYourLevelBookASessionWhenever,
                style: const TextStyle(color: Academy.muted, height: 1.5),
              ),
              const SizedBox(height: 14),
              if (student.masterTeachers.isEmpty)
                const AcademyEmpty(
                  icon: Icons.groups_outlined,
                  title: AppStrings.teachersWillAppearHere,
                  body: AppStrings.masterTeachersForYourLevelWillBeShownAsSoon,
                )
              else
                for (var i = 0; i < student.masterTeachers.length; i++) ...[
                  () {
                    final teacher = student.masterTeachers[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: MentorBookingCard(
                        teacher: teacher,
                        index: i,
                        onViewProfile: () => openAppLink(
                          context,
                          '${RoutePaths.studentMentorProfileFor(teacher.id)}${type == null ? '' : '?type=$type'}',
                        ),
                        onSelect: type == null
                            ? null
                            : () => openAppLink(
                                context,
                                '${RoutePaths.studentBookNew}?type=$type&teacher=${teacher.id}',
                              ),
                      ),
                    );
                  }(),
                ],
            ],
          );
        },
      ),
    );
  }
}
