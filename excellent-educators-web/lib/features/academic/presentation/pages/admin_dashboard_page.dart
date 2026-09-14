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

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);
    final filter = ref.watch(adminDashboardFilterProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return AppScaffold(
      title: 'Dashboard',
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

          return ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              // 1. Quick Actions Bar
              _buildQuickActionsBar(context),
              const SizedBox(height: 16),

              // 2. Interactive Filter Toolbar
              _buildFilterToolbar(context, ref, filter),
              const SizedBox(height: 12),

              // 3. Category Filter Chips
              _buildCategoryChips(context, ref, filter, totalAttention),
              const SizedBox(height: 12),

              // 4. Active Filter Banner (if filter is active)
              if (filter.hasActiveFilter) ...[
                _buildActiveFilterBanner(context, ref, filter),
                const SizedBox(height: 16),
              ],

              // 5. Academic Directory Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.academic) ...[
                _buildSectionHeader(
                  title: 'Academic directory',
                  subtitle: 'Students, teachers, and batches across the academy',
                  actionLabel: 'View students',
                  onAction: () => context.go(
                    studentsRouteWithFilters(
                      status: 'active',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: wide ? 4 : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: wide ? 2.4 : 1.9,
                  children: [
                    StatTile(
                      label: 'Active students',
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
                      label: 'Inactive students',
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
                      label: 'Active teachers',
                      value: '${counts.activeTeachers}',
                      icon: Icons.psychology_outlined,
                      accentColor: Brand.navy,
                      subtitle: 'instructors',
                      onTap: () => context.go(RoutePaths.adminTeachers),
                    ),
                    StatTile(
                      label: 'Active batches',
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
                const SizedBox(height: 24),
              ],

              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.progress) ...[
                _buildSectionHeader(
                  title: 'Academy snapshot',
                  subtitle: 'Headcount, classes, promotions, and who is doing well',
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: wide ? 4 : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: wide ? 2.4 : 1.9,
                  children: [
                    StatTile(
                      label: 'All students',
                      value: '${counts.totalStudents}',
                      icon: Icons.groups_outlined,
                      accentColor: Brand.navy,
                      subtitle: '${counts.activeStudents} active',
                      onTap: () => context.go(studentsRouteWithFilters(status: 'active')),
                    ),
                    StatTile(
                      label: 'Teachers',
                      value: '${counts.activeTeachers}',
                      icon: Icons.badge_outlined,
                      accentColor: Brand.navy,
                      subtitle: 'active',
                      onTap: () => context.go(RoutePaths.adminTeachers),
                    ),
                    StatTile(
                      label: 'Interviews',
                      value: '${counts.interviews}',
                      icon: Icons.call_outlined,
                      accentColor: const Color(0xFF2F6FED),
                      subtitle: filter.hasActiveFilter ? 'in selected month' : 'held / booked',
                    ),
                    StatTile(
                      label: 'Master classes',
                      value: '${counts.masterClasses}',
                      icon: Icons.school_outlined,
                      accentColor: const Color(0xFF1B7A4E),
                      subtitle: filter.hasActiveFilter ? 'in selected month' : 'held / booked',
                    ),
                    StatTile(
                      label: 'Levelled up',
                      value: '${counts.promotedStudents}',
                      icon: Icons.trending_up,
                      accentColor: Brand.goldDark,
                      subtitle: 'students promoted',
                      onTap: () => context.go(studentsRouteWithAttention('promoted', status: 'active')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Students by level and batch',
                  style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
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
                          padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(RoutePaths.adminBestStudents),
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text('Best students'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.go(RoutePaths.adminBestTeachers),
                      icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                      label: const Text('Best teachers'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // 6. Needs Attention / Action Required Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.attention) ...[
                _buildSectionHeader(
                  title: 'Needs attention',
                  subtitle: 'Items requiring administrative review or assignment',
                  badgeCount: totalAttention,
                ),
                const SizedBox(height: 10),
                AttentionCard(
                  label: 'Pending class conflicts',
                  count: counts.pendingVerification,
                  onTap: () => context.go(RoutePaths.adminAttendance),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: 'Students not in a batch',
                  count: counts.studentsWithoutBatch,
                  onTap: () => context.go(
                    studentsRouteWithAttention('without_batch'),
                  ),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: 'Students — assessment pending',
                  count: counts.studentsAssessmentPending,
                  onTap: () => context.go(
                    studentsRouteWithAttention('assessment_pending'),
                  ),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: 'Students — no monthly rating',
                  count: counts.studentsWithoutRatingThisMonth,
                  onTap: () => context.go(
                    studentsRouteWithAttention('without_rating_this_month'),
                  ),
                ),
                const SizedBox(height: 6),
                AttentionCard(
                  label: 'Full batches (40 students)',
                  count: counts.fullBatches,
                  onTap: () => context.go(
                    batchesRouteWithAttention('full'),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 7. Classes & Attendance Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.classes) ...[
                _buildSectionHeader(
                  title: 'Classes & attendance',
                  subtitle: 'Operational session bookings and fulfillment',
                  actionLabel: 'Open attendance hub',
                  onAction: () => context.go(RoutePaths.adminAttendance),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: wide ? 4 : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: wide ? 2.4 : 1.9,
                  children: [
                    StatTile(
                      label: 'Total classes',
                      value: '${counts.totalClasses}',
                      icon: Icons.event_available_outlined,
                      accentColor: Brand.navy,
                      subtitle: 'scheduled',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: 'Completed classes',
                      value: '${counts.completedClasses}',
                      icon: Icons.check_circle_outline,
                      accentColor: const Color(0xFF2E7D32),
                      subtitle: counts.totalClasses > 0
                          ? '${((counts.completedClasses / counts.totalClasses) * 100).toStringAsFixed(0)}% completion'
                          : 'conducted',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: 'Rebookings given',
                      value: '${counts.rebookingsGiven}',
                      icon: Icons.replay_outlined,
                      accentColor: const Color(0xFF1976D2),
                      subtitle: 'extra chances',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: 'Technical issues',
                      value: '${counts.technicalIssues}',
                      icon: Icons.wifi_off_outlined,
                      accentColor: counts.technicalIssues > 0 ? const Color(0xFFE65100) : Brand.muted,
                      subtitle: 'meeting errors',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // 8. Conflicts & Resolutions Section
              if (filter.category == AdminDashboardCategory.all ||
                  filter.category == AdminDashboardCategory.conflicts) ...[
                _buildSectionHeader(
                  title: 'Conflicts & issue reports',
                  subtitle: 'Dispute reports filed by students and teachers',
                  actionLabel: 'Resolve issues',
                  onAction: () => context.go(RoutePaths.adminAttendance),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: wide ? 4 : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: wide ? 2.4 : 1.9,
                  children: [
                    StatTile(
                      label: 'Pending verification',
                      value: '${counts.pendingVerification}',
                      icon: Icons.pending_actions_outlined,
                      accentColor: counts.pendingVerification > 0 ? const Color(0xFFD32F2F) : Brand.muted,
                      subtitle: 'awaiting admin',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: 'Student reports',
                      value: '${counts.studentAttendanceReports}',
                      icon: Icons.report_problem_outlined,
                      accentColor: const Color(0xFFE65100),
                      subtitle: 'filed by students',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: 'Teacher reports',
                      value: '${counts.teacherAttendanceReports}',
                      icon: Icons.report_gmailerrorred_outlined,
                      accentColor: const Color(0xFFE65100),
                      subtitle: 'filed by teachers',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                    StatTile(
                      label: 'Verified teacher absence',
                      value: '${counts.verifiedTeacherAbsence}',
                      icon: Icons.person_remove_outlined,
                      accentColor: const Color(0xFFC2185B),
                      subtitle: 'no-show',
                      onTap: () => context.go(RoutePaths.adminAttendance),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // 8. Google Meet Integration Banner
              _buildGoogleMeetBanner(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: () => context.go(RoutePaths.adminStudentNew),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Add student'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () => context.go(RoutePaths.adminTeacherNew),
            icon: const Icon(Icons.group_add_outlined, size: 18),
            label: const Text('Add teacher'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () => context.go(RoutePaths.adminBatchNew),
            icon: const Icon(Icons.post_add_outlined, size: 18),
            label: const Text('Add level / batch'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.go(RoutePaths.adminBestStudents),
            icon: const Icon(Icons.emoji_events_outlined, size: 18),
            label: const Text('Best students'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.go(RoutePaths.adminBestTeachers),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Best teachers'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.go(RoutePaths.adminAttendance),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('Attendance'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.go(RoutePaths.adminSettings),
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('Google Meet'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardFilter filter,
  ) {
    final now = DateTime.now();
    final months = <MapEntry<String, String>>[
      const MapEntry('all', 'All time'),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DCCB)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list_rounded, size: 18, color: Brand.navy),
              const SizedBox(width: 6),
              const Text(
                'Filters:',
                style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),

          // Period / Month Dropdown
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (filter.year != null && filter.month != null) ? Brand.goldDark : const Color(0xFFE6DCCB),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: months.any((m) => m.key == currentPeriodKey) ? currentPeriodKey : 'all',
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Brand.navy),
                style: const TextStyle(color: Brand.navy, fontSize: 13, fontWeight: FontWeight.w600),
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
              label: const Text('Reset filters'),
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
    final categories = [
      (AdminDashboardCategory.all, 'All overview', null),
      (AdminDashboardCategory.attention, 'Action required', totalAttention > 0 ? '$totalAttention' : null),
      (AdminDashboardCategory.academic, 'Academic directory', null),
      (AdminDashboardCategory.progress, 'Progress & standouts', null),
      (AdminDashboardCategory.classes, 'Classes & attendance', null),
      (AdminDashboardCategory.conflicts, 'Conflicts & issues', null),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (cat, label, badge) in categories) ...[
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cat == filter.category ? Colors.white : const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: cat == filter.category ? Brand.navy : Colors.white,
                          fontSize: 11,
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
                fontSize: 13,
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
            const SizedBox(width: 8),
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
          AdminDashboardCategory.attention => 'Action required',
          AdminDashboardCategory.academic => 'Academic directory',
          AdminDashboardCategory.progress => 'Progress & standouts',
          AdminDashboardCategory.classes => 'Classes & attendance',
          AdminDashboardCategory.conflicts => 'Conflicts & issues',
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
            child: const Text('Clear all', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    int? badgeCount,
  }) {
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
                    style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  if (badgeCount != null && badgeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Brand.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(actionLabel),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
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
                      'Google Meet Integration',
                      style: TextStyle(color: Brand.navy, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Connect Google account, set meeting rules, or manage credentials',
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
