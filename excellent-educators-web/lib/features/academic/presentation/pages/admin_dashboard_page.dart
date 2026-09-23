import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/time/app_clock.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/utils/admin_list_route_sync.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);
    final filter = ref.watch(adminDashboardFilterProvider);

    return AppScaffold(
      title: AppStrings.dashboard,
      body: AsyncBody(
        value: dashboard,
        onRetry: () => ref.invalidate(adminDashboardProvider),
        builder: (data) {
          final counts = data.counts;
          final totalAttention = counts.pendingVerification +
              counts.studentsWithoutBatch +
              counts.studentsAssessmentPending +
              counts.studentsWithoutRatingThisMonth +
              counts.fullBatches;

          final isMobile = MediaQuery.sizeOf(context).width < 600;

          return ListView(
            padding: EdgeInsets.only(bottom: isMobile ? 16 : 24),
            children: [
              // 1. Quick Actions Bar
              _buildQuickActionsBar(context, ref),
              SizedBox(height: isMobile ? 10 : 16),

              // 2. Interactive Filter Toolbar
              _buildFilterToolbar(context, ref, filter),
              SizedBox(height: isMobile ? 8 : 12),

              // 3. Category Filter Chips
              _buildCategoryChips(context, ref, filter, totalAttention),
              SizedBox(height: isMobile ? 8 : 12),

              // 4. Active Filter Banner (if filter is active)
              if (filter.hasActiveFilter) ...[
                _buildActiveFilterBanner(context, ref, filter),
                SizedBox(height: isMobile ? 10 : 16),
              ],

              // 5. Academic Directory Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.academic) ...[
                _buildSectionHeader(
                  context: context,
                  title: AppStrings.academicDirectory,
                  subtitle: AppStrings.studentsTeachersAndBatchesAcrossTheAcademy,
                  actionLabel: AppStrings.viewStudents,
                  onAction: () => context.go(
                    studentsRouteWithFilters(
                      status: 'active',
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 10),
                StatGrid(
                  children: [
                    StatTile(
                      label: AppStrings.activeStudents,
                      value: '${counts.activeStudents}',
                      icon: Icons.school_outlined,
                      accentColor: const Color(0xFF2E7D32),
                      subtitle: 'enrolled',
                      onTap: () => context.go(
                        studentsRouteWithFilters(
                          status: 'active',
                        ),
                      ),
                    ),
                    StatTile(
                      label: AppStrings.inactiveStudents,
                      value: '${counts.inactiveStudents}',
                      icon: Icons.person_off_outlined,
                      accentColor: Brand.muted,
                      subtitle: 'archived',
                      onTap: () => context.go(
                        studentsRouteWithFilters(
                          status: 'inactive',
                        ),
                      ),
                    ),
                    StatTile(
                      label: AppStrings.activeTeachers,
                      value: '${counts.activeTeachers}',
                      icon: Icons.psychology_outlined,
                      accentColor: Brand.navy,
                      subtitle: 'instructors',
                      onTap: () => context.go(RoutePaths.adminTeachers),
                    ),
                    StatTile(
                      label: AppStrings.activeBatches,
                      value: '${counts.activeBatches}',
                      icon: Icons.view_carousel_outlined,
                      accentColor: Brand.goldDark,
                      subtitle: 'running',
                      onTap: () => context.go(
                        batchesRouteWithFilters(
                          status: 'active',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 14 : 24),
              ],

              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.progress) ...[
                _buildSectionHeader(
                  context: context,
                  title: AppStrings.academySnapshot,
                  subtitle: AppStrings.headcountClassesPromotionsAndWhoIsDoingWell,
                ),
                SizedBox(height: isMobile ? 6 : 10),
                StatGrid(
                  children: [
                    StatTile(
                      label: AppStrings.allStudents,
                      value: '${counts.totalStudents}',
                      icon: Icons.groups_outlined,
                      accentColor: Brand.navy,
                      subtitle: '${counts.activeStudents} active',
                      onTap: () => context.go(studentsRouteWithFilters(status: 'active')),
                    ),
                    StatTile(
                      label: AppStrings.teachers,
                      value: '${counts.activeTeachers}',
                      icon: Icons.badge_outlined,
                      accentColor: Brand.navy,
                      subtitle: 'active',
                      onTap: () => context.go(RoutePaths.adminTeachers),
                    ),
                    StatTile(
                      label: AppStrings.interviews,
                      value: '${counts.interviews}',
                      icon: Icons.call_outlined,
                      accentColor: const Color(0xFF2F6FED),
                      subtitle: filter.hasActiveFilter ? AppStrings.inSelectedMonth : AppStrings.heldBooked,
                    ),
                    StatTile(
                      label: AppStrings.masterClasses2,
                      value: '${counts.masterClasses}',
                      icon: Icons.school_outlined,
                      accentColor: const Color(0xFF1B7A4E),
                      subtitle: filter.hasActiveFilter ? AppStrings.inSelectedMonth : AppStrings.heldBooked,
                    ),
                    StatTile(
                      label: AppStrings.levelledUp,
                      value: '${counts.promotedStudents}',
                      icon: Icons.trending_up,
                      accentColor: Brand.goldDark,
                      subtitle: AppStrings.studentsPromoted,
                      onTap: () => context.go(studentsRouteWithAttention('promoted', status: 'active')),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 16),
                Text(
                  AppStrings.studentsByLevelAndBatch,
                  style: TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                ...data.byLevel.map((level) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE6DCCB)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go(
                          studentsRouteWithFilters(status: 'active', levelId: level.id),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isMobile ? 8 : 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      level.name,
                                      style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    '${level.studentCount} students',
                                    style: const TextStyle(color: Brand.muted, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (level.batches.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final batch in level.batches)
                                      ActionChip(
                                        label: Text('${batch.name} · ${batch.studentCount}'),
                                        onPressed: () => context.go(
                                          studentsRouteWithFilters(status: 'active', batchId: batch.id),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: isMobile ? 10 : 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(RoutePaths.adminBestStudents),
                      icon: Icon(Icons.emoji_events_outlined, size: isMobile ? 16 : 18),
                      label: const Text(AppStrings.bestStudents),
                      style: isMobile
                          ? FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            )
                          : null,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(RoutePaths.adminBestTeachers),
                      icon: Icon(Icons.workspace_premium_outlined, size: isMobile ? 16 : 18),
                      label: const Text(AppStrings.bestTeachers),
                      style: isMobile
                          ? FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            )
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 14 : 24),
              ],

              // 6. Needs Attention / Action Required Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.attention) ...[
                _buildSectionHeader(
                  context: context,
                  title: AppStrings.needsAttention,
                  subtitle: AppStrings.itemsRequiringAdministrativeReviewOrAssignment,
                  badgeCount: totalAttention,
                ),
                SizedBox(height: isMobile ? 6 : 10),
                AttentionCard(
                  label: AppStrings.pendingClassConflicts,
                  count: counts.pendingVerification,
                  onTap: () => context.go(RoutePaths.adminAttendance),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: AppStrings.studentsNotInABatch,
                  count: counts.studentsWithoutBatch,
                  onTap: () => context.go(
                    studentsRouteWithAttention('without_batch'),
                  ),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: AppStrings.studentsAssessmentPending,
                  count: counts.studentsAssessmentPending,
                  onTap: () => context.go(
                    studentsRouteWithAttention('assessment_pending'),
                  ),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: AppStrings.studentsNoMonthlyRating,
                  count: counts.studentsWithoutRatingThisMonth,
                  onTap: () => context.go(
                    studentsRouteWithAttention('without_rating_this_month'),
                  ),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: AppStrings.fullBatches40Students,
                  count: counts.fullBatches,
                  onTap: () => context.go(
                    batchesRouteWithAttention('full'),
                  ),
                ),
                SizedBox(height: isMobile ? 14 : 24),
              ],

              // 7. Classes & Attendance Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.classes) ...[
                _buildSectionHeader(
                  context: context,
                  title: AppStrings.classesAttendance,
                  subtitle: AppStrings.operationalSessionBookingsAndFulfillment,
                  actionLabel: AppStrings.openAttendanceHub,
                  onAction: () => context.go(RoutePaths.adminAttendance),
                ),
                SizedBox(height: isMobile ? 6 : 10),
                StatGrid(
                  children: [
                    StatTile(
                      label: AppStrings.totalClasses,
                      value: '${counts.totalClasses}',
                      icon: Icons.event_available_outlined,
                      accentColor: Brand.navy,
                      subtitle: 'scheduled',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: AppStrings.completedClasses,
                      value: '${counts.completedClasses}',
                      icon: Icons.check_circle_outline,
                      accentColor: const Color(0xFF2E7D32),
                      subtitle: counts.totalClasses > 0
                          ? '${((counts.completedClasses / counts.totalClasses) * 100).toStringAsFixed(0)}% completion'
                          : 'conducted',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: AppStrings.rebookingsGiven,
                      value: '${counts.rebookingsGiven}',
                      icon: Icons.replay_outlined,
                      accentColor: const Color(0xFF1976D2),
                      subtitle: AppStrings.extraChances,
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: AppStrings.technicalIssues,
                      value: '${counts.technicalIssues}',
                      icon: Icons.wifi_off_outlined,
                      accentColor: counts.technicalIssues > 0 ? const Color(0xFFE65100) : Brand.muted,
                      subtitle: AppStrings.meetingErrors,
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 14 : 24),
              ],

              // 8. Conflicts & Resolutions Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.conflicts) ...[
                _buildSectionHeader(
                  context: context,
                  title: AppStrings.conflictsIssueReports,
                  subtitle: AppStrings.disputeReportsFiledByStudentsAndTeachers,
                  actionLabel: AppStrings.resolveIssues,
                  onAction: () => context.go(RoutePaths.adminAttendance),
                ),
                SizedBox(height: isMobile ? 6 : 10),
                StatGrid(
                  children: [
                    StatTile(
                      label: AppStrings.pendingVerification,
                      value: '${counts.pendingVerification}',
                      icon: Icons.pending_actions_outlined,
                      accentColor: counts.pendingVerification > 0 ? const Color(0xFFD32F2F) : Brand.muted,
                      subtitle: AppStrings.awaitingAdmin,
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: AppStrings.studentReports,
                      value: '${counts.studentAttendanceReports}',
                      icon: Icons.report_problem_outlined,
                      accentColor: const Color(0xFFE65100),
                      subtitle: AppStrings.filedByStudents,
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: AppStrings.teacherReports,
                      value: '${counts.teacherAttendanceReports}',
                      icon: Icons.report_gmailerrorred_outlined,
                      accentColor: const Color(0xFFE65100),
                      subtitle: AppStrings.filedByTeachers,
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: AppStrings.verifiedTeacherAbsence,
                      value: '${counts.verifiedTeacherAbsence}',
                      icon: Icons.person_remove_outlined,
                      accentColor: const Color(0xFFC2185B),
                      subtitle: 'no-show',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 14 : 24),
              ],

              // 8. Google Meet Integration Banner
              _buildGoogleMeetBanner(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsBar(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (user?.canAdmin(AdminPermission.studentsCreate) ?? false) ...[
            FilledButton.icon(
              onPressed: () => context.go(RoutePaths.adminStudentNew),
              icon: Icon(Icons.person_add_outlined, size: isMobile ? 15 : 18),
              label: Text(AppStrings.addStudent, style: TextStyle(fontSize: isMobile ? 12 : 14)),
              style: FilledButton.styleFrom(
                visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 10),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
          ],
          if (user?.canAdmin(AdminPermission.teachersCreate) ?? false) ...[
            FilledButton.tonalIcon(
              onPressed: () => context.go(RoutePaths.adminTeacherNew),
              icon: Icon(Icons.group_add_outlined, size: isMobile ? 15 : 18),
              label: Text(AppStrings.addTeacher, style: TextStyle(fontSize: isMobile ? 12 : 14)),
              style: FilledButton.styleFrom(
                visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 10),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
          ],
          if (user?.canAdmin(AdminPermission.levelsManage) ?? false) ...[
            FilledButton.tonalIcon(
              onPressed: () => context.go(RoutePaths.adminBatchNew),
              icon: Icon(Icons.post_add_outlined, size: isMobile ? 15 : 18),
              label: Text(AppStrings.addLevelBatch, style: TextStyle(fontSize: isMobile ? 12 : 14)),
              style: FilledButton.styleFrom(
                visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 10),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
          ],
          OutlinedButton.icon(
            onPressed: () => context.go(RoutePaths.adminBestStudents),
            icon: Icon(Icons.emoji_events_outlined, size: isMobile ? 15 : 18),
            label: Text(AppStrings.bestStudents, style: TextStyle(fontSize: isMobile ? 12 : 14)),
            style: OutlinedButton.styleFrom(
              visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 10),
            ),
          ),
          SizedBox(width: isMobile ? 6 : 8),
          OutlinedButton.icon(
            onPressed: () => context.go(RoutePaths.adminBestTeachers),
            icon: Icon(Icons.workspace_premium_outlined, size: isMobile ? 15 : 18),
            label: Text(AppStrings.bestTeachers, style: TextStyle(fontSize: isMobile ? 12 : 14)),
            style: OutlinedButton.styleFrom(
              visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 10),
            ),
          ),
          if (user?.canAnyAdmin(const [AdminPermission.queriesView, AdminPermission.queriesResolve]) ?? false) ...[
            SizedBox(width: isMobile ? 6 : 8),
            OutlinedButton.icon(
              onPressed: () => context.go(RoutePaths.adminAttendance),
              icon: Icon(Icons.fact_check_outlined, size: isMobile ? 15 : 18),
              label: Text(AppStrings.attendance, style: TextStyle(fontSize: isMobile ? 12 : 14)),
              style: OutlinedButton.styleFrom(
                visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 10),
              ),
            ),
          ],
          if (user?.canAdmin(AdminPermission.settingsManage) ?? false) ...[
            SizedBox(width: isMobile ? 6 : 8),
            OutlinedButton.icon(
              onPressed: () => context.go(RoutePaths.adminSettings),
              icon: Icon(Icons.videocam_outlined, size: isMobile ? 15 : 18),
              label: Text(AppStrings.googleMeet, style: TextStyle(fontSize: isMobile ? 12 : 14)),
              style: OutlinedButton.styleFrom(
                visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardFilter filter,
  ) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final now = DateTime.now();
    final months = <MapEntry<String, String>>[
      const MapEntry('all', AppStrings.allTime2),
      MapEntry('${now.year}-${now.month}', 'This month (${AppClock.monthLabel(now.year, now.month)})'),
      for (var i = 1; i <= 5; i++) ...[
        () {
          final d = DateTime(now.year, now.month - i, 1);
          return MapEntry('${d.year}-${d.month}', AppClock.monthLabel(d.year, d.month));
        }(),
      ],
    ];

    final currentPeriodKey = (filter.year == null || filter.month == null)
        ? 'all'
        : '${filter.year}-${filter.month}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
        border: Border.all(color: const Color(0xFFE6DCCB)),
      ),
      child: Wrap(
        spacing: isMobile ? 8 : 12,
        runSpacing: isMobile ? 6 : 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_rounded, size: isMobile ? 16 : 18, color: Brand.navy),
              const SizedBox(width: 5),
              Text(
                AppStrings.filters,
                style: TextStyle(
                  color: Brand.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ],
          ),

          // Period / Month Dropdown
          Container(
            height: isMobile ? 32 : 38,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EA),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              border: Border.all(
                color: (filter.year != null && filter.month != null) ? Brand.goldDark : const Color(0xFFE6DCCB),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: months.any((m) => m.key == currentPeriodKey) ? currentPeriodKey : 'all',
                icon: Icon(Icons.keyboard_arrow_down, size: isMobile ? 16 : 18, color: Brand.navy),
                style: TextStyle(
                  color: Brand.navy,
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  for (final entry in months)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) {
                  if (value == null || value == 'all') {
                    ref.read(adminDashboardFilterProvider.notifier).state =
                        filter.copyWith(clearDate: true);
                  } else {
                    final parts = value.split('-');
                    ref.read(adminDashboardFilterProvider.notifier).state = filter.copyWith(
                      year: int.parse(parts[0]),
                      month: int.parse(parts[1]),
                    );
                  }
                },
              ),
            ),
          ),

          if (filter.hasActiveFilter)
            TextButton.icon(
              onPressed: () {
                ref.read(adminDashboardFilterProvider.notifier).state = const AdminDashboardFilter();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text(AppStrings.resetFilters),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Brand.goldDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardFilter filter,
    int totalAttention,
  ) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final categories = [
      (AdminDashboardCategory.all, AppStrings.allOverview, null),
      (AdminDashboardCategory.attention, AppStrings.actionRequired, totalAttention > 0 ? '$totalAttention' : null),
      (AdminDashboardCategory.academic, AppStrings.academicDirectory, null),
      (AdminDashboardCategory.progress, AppStrings.progressStandouts, null),
      (AdminDashboardCategory.classes, AppStrings.classesAttendance, null),
      (AdminDashboardCategory.conflicts, AppStrings.conflictsIssues, null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (cat, label, badge) in categories) ...[
            ChoiceChip(
              visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (badge != null) ...[
                    SizedBox(width: isMobile ? 4 : 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 5 : 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cat == filter.category ? Colors.white : const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: cat == filter.category ? Brand.navy : Colors.white,
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: filter.category == cat,
              showCheckmark: false,
              selectedColor: Brand.navy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: filter.category == cat ? Colors.white : Brand.navy,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 11.5 : 13,
              ),
              side: BorderSide(
                color: filter.category == cat ? Brand.navy : const Color(0xFFE6DCCB),
              ),
              onSelected: (selected) {
                if (selected) {
                  ref.read(adminDashboardFilterProvider.notifier).state =
                      filter.copyWith(category: cat);
                }
              },
            ),
            SizedBox(width: isMobile ? 6 : 8),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilterBanner(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardFilter filter,
  ) {
    final chips = <String>[
      if (filter.year != null && filter.month != null) 'Period: ${AppClock.monthLabel(filter.year!, filter.month!)}',
      if (filter.category != AdminDashboardCategory.all)
        'Section: ${switch (filter.category) {
          AdminDashboardCategory.attention => AppStrings.actionRequired,
          AdminDashboardCategory.academic => AppStrings.academicDirectory,
          AdminDashboardCategory.progress => AppStrings.progressStandouts,
          AdminDashboardCategory.classes => AppStrings.classesAttendance,
          AdminDashboardCategory.conflicts => AppStrings.conflictsIssues,
          _ => '',
        }}',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6EA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Brand.goldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Filtered by: ${chips.join('  •  ')}',
              style: const TextStyle(color: Brand.navy, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminDashboardFilterProvider.notifier).state = const AdminDashboardFilter();
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: Brand.goldDark,
            ),
            child: const Text(AppStrings.clearAll, style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    int? badgeCount,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Brand.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 15 : 18,
                    ),
                  ),
                  if (badgeCount != null && badgeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(color: Brand.muted, fontSize: isMobile ? 11 : 12),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(Icons.arrow_forward, size: isMobile ? 14 : 16),
            label: Text(actionLabel, style: TextStyle(fontSize: isMobile ? 12 : 13)),
            style: TextButton.styleFrom(
              visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
              padding: isMobile ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : null,
              foregroundColor: Brand.goldDark,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoogleMeetBanner(BuildContext context) {
    return Material(
      color: const Color(0xFFFBF6EA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Brand.gold),
      ),
      child: InkWell(
        onTap: () => context.go(RoutePaths.adminSettings),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.videocam_outlined, color: Brand.navy),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.googleMeetIntegration,
                      style: TextStyle(color: Brand.navy, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppStrings.connectGoogleAccountSetMeetingRulesOrManageCredentials,
                      style: TextStyle(color: Brand.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Brand.navy),
            ],
          ),
        ),
      ),
    );
  }
}
