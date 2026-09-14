import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminBestStudentsPage extends ConsumerWidget {
  const AdminBestStudentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);

    return AppScaffold(
      title: 'Best students',
      backTo: RoutePaths.adminDashboard,
      body: AsyncBody(
        value: dashboard,
        onRetry: () => ref.invalidate(adminDashboardProvider),
        builder: (data) {
          if (data.topStudents.isEmpty) {
            return const EmptyHint(
              'No standout students yet',
              subtitle: 'This list fills as Master Teachers submit monthly ratings. Until then, longest-enrolled students appear here.',
            );
          }

          return ListView.separated(
            itemCount: data.topStudents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = data.topStudents[index];
              return _StandoutCard(
                rank: index + 1,
                title: student.fullName,
                subtitle: [
                  student.studentCode,
                  if (student.levelName != null) student.levelName!,
                  if (student.ratingAverage != null) 'Avg ${student.ratingAverage!.toStringAsFixed(1)}',
                  '${student.monthsWithUs} months with us',
                  '${student.completedMasterClasses} master classes',
                ].join(' · '),
                onTap: () => context.go(RoutePaths.adminStudent(student.id)),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminBestTeachersPage extends ConsumerWidget {
  const AdminBestTeachersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);

    return AppScaffold(
      title: 'Best teachers',
      backTo: RoutePaths.adminDashboard,
      body: AsyncBody(
        value: dashboard,
        onRetry: () => ref.invalidate(adminDashboardProvider),
        builder: (data) {
          if (data.topTeachers.isEmpty) {
            return const EmptyHint(
              'No teacher activity yet',
              subtitle: 'Teachers appear here after they take interviews or master classes.',
            );
          }

          return ListView.separated(
            itemCount: data.topTeachers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final teacher = data.topTeachers[index];
              return _StandoutCard(
                rank: index + 1,
                title: teacher.fullName,
                subtitle:
                    'Interviews ${teacher.interviews} · Master classes ${teacher.masterClasses} · Promoted ${teacher.promotedStudents}',
                onTap: () => context.go(RoutePaths.adminTeacher(teacher.id)),
              );
            },
          );
        },
      ),
    );
  }
}

class _StandoutCard extends StatelessWidget {
  const _StandoutCard({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int rank;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6DCCB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF4EEE3),
                foregroundColor: Brand.navy,
                child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Brand.muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}
