import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_view.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final studentMentorProfileProvider = FutureProvider.autoDispose
    .family<TeacherDto, String>((ref, teacherId) {
      return ref
          .watch(academicRepositoryProvider)
          .studentMentorProfile(teacherId);
    });

class StudentMentorProfilePage extends ConsumerWidget {
  const StudentMentorProfilePage({
    super.key,
    required this.teacherId,
    this.bookingType,
  });

  final String teacherId;
  final String? bookingType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentMentorProfileProvider(teacherId));
    final eligibility = ref.watch(studentEligibilityProvider);
    final canBook = eligibility.maybeWhen(
      data: (value) {
        final canIntro = value.canBookIntroduction;
        final canMaster =
            value.canBookMasterClass && value.masterClassRemaining > 0;
        return canIntro || canMaster;
      },
      orElse: () => false,
    );

    return StudentScaffold(
      title: 'Meet Your Mentor',
      backTo: RoutePaths.studentBookNew,
      body: AsyncBody(
        value: profile,
        onRetry: () => ref.invalidate(studentMentorProfileProvider(teacherId)),
        builder: (teacher) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 600 ? 0.0 : 4.0;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  36,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: MentorProfileContent(
                        teacher: teacher,
                        bookLabel: 'Book a Session',
                        onBook: canBook
                            ? () {
                                final type = bookingType ??
                                    eligibility.maybeWhen(
                                      data: (value) => value.canBookIntroduction
                                          ? 'introduction_call'
                                          : 'master_class',
                                      orElse: () => 'master_class',
                                    );
                                context.go(
                                  '${RoutePaths.studentBookNew}?type=$type&teacher=${teacher.id}',
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
