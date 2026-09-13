import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/utils/admin_list_route_sync.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return AppScaffold(
      title: 'Dashboard',
      body: AsyncBody(
        value: dashboard,
        onRetry: () => ref.invalidate(adminDashboardProvider),
        builder: (data) {
          final counts = data.counts;
          return ListView(
            children: [
              const Text(
                'Overview',
                style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: wide ? 2.2 : 1.8,
                children: [
                  StatTile(label: 'Active students', value: '${counts.activeStudents}'),
                  StatTile(label: 'Active teachers', value: '${counts.activeTeachers}'),
                  StatTile(label: 'Active batches', value: '${counts.activeBatches}'),
                  StatTile(label: 'Inactive students', value: '${counts.inactiveStudents}'),
                  StatTile(label: 'Total classes', value: '${counts.totalClasses}'),
                  StatTile(label: 'Completed classes', value: '${counts.completedClasses}'),
                  StatTile(label: 'Pending conflicts', value: '${counts.pendingVerification}'),
                  StatTile(label: 'Student reports', value: '${counts.studentAttendanceReports}'),
                  StatTile(label: 'Teacher reports', value: '${counts.teacherAttendanceReports}'),
                  StatTile(label: 'Teacher absence', value: '${counts.verifiedTeacherAbsence}'),
                  StatTile(label: 'Student absence', value: '${counts.verifiedStudentAbsence}'),
                  StatTile(label: 'Technical issues', value: '${counts.technicalIssues}'),
                  StatTile(label: 'Rebookings given', value: '${counts.rebookingsGiven}'),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Needs attention',
                style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              AttentionCard(
                label: 'Pending class conflicts',
                count: counts.pendingVerification,
                onTap: () => context.go(RoutePaths.adminAttendance),
              ),
              const SizedBox(height: 6),
              AttentionCard(
                label: 'Students not in a batch',
                count: counts.studentsWithoutBatch,
                onTap: () => context.go(studentsRouteWithAttention('without_batch')),
              ),
              const SizedBox(height: 6),
              AttentionCard(
                label: 'Students without Master Teacher',
                count: counts.studentsWithoutMasterTeacher,
                onTap: () => context.go(studentsRouteWithAttention('without_master_teacher')),
              ),
              const SizedBox(height: 6),
              AttentionCard(
                label: 'Students — assessment pending',
                count: counts.studentsAssessmentPending,
                onTap: () => context.go(studentsRouteWithAttention('assessment_pending')),
              ),
              const SizedBox(height: 6),
              AttentionCard(
                label: 'Students — no monthly rating',
                count: counts.studentsWithoutRatingThisMonth,
                onTap: () => context.go(studentsRouteWithAttention('without_rating_this_month')),
              ),
              const SizedBox(height: 6),
              AttentionCard(
                label: 'Batches without Common Teacher',
                count: counts.batchesWithoutCommonTeacher,
                onTap: () => context.go(batchesRouteWithAttention('without_common_teacher')),
              ),
              const SizedBox(height: 6),
              AttentionCard(
                label: 'Full batches (40 students)',
                count: counts.fullBatches,
                onTap: () => context.go(batchesRouteWithAttention('full')),
              ),
              const SizedBox(height: 20),
              const Text(
                'Google Meet',
                style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Material(
                color: const Color(0xFFFBF6EA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Brand.gold),
                ),
                child: InkWell(
                  onTap: () => context.go(RoutePaths.adminSettings),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.videocam_outlined, color: Brand.navy),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Open Google Meet — Connect Google',
                            style: TextStyle(color: Brand.navy, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Brand.navy),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'By Career Compass',
                style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...data.careerCompass.map((level) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE6DCCB)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${level.shortCode} · ${level.name}',
                                  style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Classes ${level.classFrom}–${level.classTo}',
                                  style: const TextStyle(color: Brand.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${level.activeStudents} students',
                            style: const TextStyle(color: Brand.muted, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${level.activeBatches} batches',
                            style: const TextStyle(color: Brand.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

List<DropdownMenuItem<String>> careerCompassDropdownItems(List<CareerCompassLevelDto> levels) {
  return [
    for (final level in levels)
      DropdownMenuItem(value: level.id, child: Text('${level.shortCode} · ${level.name}')),
  ];
}
