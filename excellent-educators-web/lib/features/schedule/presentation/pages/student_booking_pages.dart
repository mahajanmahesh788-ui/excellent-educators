import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/session_labels.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_view.dart';
import 'package:excellent_educators_web/features/assessments/presentation/providers/assessment_feature_providers.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/attendance_report_dialog.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/schedule_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/fresh_student_onboarding.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';

class StudentBookingsPage extends ConsumerStatefulWidget {
  const StudentBookingsPage({super.key});

  @override
  ConsumerState<StudentBookingsPage> createState() =>
      _StudentBookingsPageState();
}

class _StudentBookingsPageState extends ConsumerState<StudentBookingsPage> {
  // Main Tab Filter: 0 = All, 1 = Upcoming, 2 = Past Sessions
  int _selectedTab = 0;

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Update countdown timers periodically
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  DateTime _getSessionTime(
    SessionBookingDto booking, {
    bool fallbackFuture = true,
  }) {
    return booking.startsAt ??
        (fallbackFuture ? DateTime(2099) : DateTime(1970));
  }

  @override
  Widget build(BuildContext context) {
    final assessment = ref.watch(studentAssessmentProvider);
    final assessmentPending = assessment.maybeWhen(
      data: (payload) => payload.available && payload.assessment != null,
      orElse: () => false,
    );

    if (assessmentPending) {
      return const StudentScaffold(
        title: AppStrings.mySessions,
        body: BookingQuestionnaireGuardCard(),
      );
    }

    final bookings = ref.watch(studentBookingsProvider);
    final eligibility = ref.watch(studentEligibilityProvider);
    final now = DateTime.now();

    final bookType = eligibility.maybeWhen(
      data: (value) => value.canBookIntroduction
          ? 'introduction_call'
          : (value.canBookMasterClass && value.masterClassRemaining > 0)
          ? 'master_class'
          : null,
      orElse: () => null,
    );

    return StudentScaffold(
      title: AppStrings.mySessions,
      body: AnimatedPortalBackdrop(
        child: bookings.when(
          skipLoadingOnReload: true,
          loading: () => ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: const [
              AcademySkeleton(height: 140),
              SizedBox(height: 16),
              AcademySkeleton(height: 76),
              SizedBox(height: 16),
              AcademySkeleton(height: 160),
              SizedBox(height: 16),
              AcademySkeleton(height: 140),
            ],
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: AcademyError(
              message: AppStrings.somethingWentWrongWhileLoadingYourSessions,
              onRetry: () => ref.invalidate(studentBookingsProvider),
            ),
          ),
          data: (items) {
            // STRICT SORTING RULES:
            // 1. Upcoming sessions: sorted ASCENDING by session datetime (nearest first)
            final allUpcoming =
                items.where((item) {
                  if (item.isCancelled || item.isCompleted) return false;
                  return item.isScheduled && !item.hasEndedAt(now);
                }).toList()..sort(
                  (a, b) => _getSessionTime(
                    a,
                    fallbackFuture: true,
                  ).compareTo(_getSessionTime(b, fallbackFuture: true)),
                );

            // 2. Past sessions: sorted DESCENDING by session datetime (newest/latest first)
            final allPast =
                items.where((item) {
                  if (item.isCancelled || item.isCompleted) return true;
                  return item.hasEndedAt(now);
                }).toList()..sort(
                  (a, b) => _getSessionTime(
                    b,
                    fallbackFuture: false,
                  ).compareTo(_getSessionTime(a, fallbackFuture: false)),
                );

            // Nearest upcoming session for the Spotlight feature card
            final nearestUpcoming = allUpcoming.isNotEmpty
                ? allUpcoming.first
                : null;

            return ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                // 1. Modern Page Header
                _SessionsHeader(
                  type: bookType,
                  onBook: () => context.go(
                    bookType == null
                        ? RoutePaths.studentBookNew
                        : '${RoutePaths.studentBookNew}?type=$bookType',
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Session Overview KPI Strip
                _SessionsOverviewStrip(
                  completedCount: items.where((b) => b.isCompleted).length,
                  totalSessions: items.length,
                  nextSession: nearestUpcoming,
                  now: now,
                ),

                const SizedBox(height: 20),

                // 3. Spotlight Next Session Card
                if (nearestUpcoming != null &&
                    (_selectedTab == 0 || _selectedTab == 1)) ...[
                  _NextSessionFeatureCard(
                    booking: nearestUpcoming,
                    now: now,
                    onJoin: () async {
                      await ref
                          .read(scheduleRepositoryProvider)
                          .studentJoinClass(nearestUpcoming.id);
                      ref.invalidate(studentBookingsProvider);
                      final url = nearestUpcoming.meetingUrl;
                      if (url != null && url.isNotEmpty) {
                        await launchUrl(
                          Uri.parse(url),
                          webOnlyWindowName: AppStrings.blank,
                        );
                      }
                    },
                    onReschedule: () => context.go(
                      '${RoutePaths.studentBookNew}?type=${nearestUpcoming.type}&bookingId=${nearestUpcoming.id}',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 4. Session tabs
                _SessionsFilterBar(
                  selectedTab: _selectedTab,
                  allCount: items.length,
                  upcomingCount: allUpcoming.length,
                  pastCount: allPast.length,
                  onTabChanged: (val) => setState(() => _selectedTab = val),
                ),

                const SizedBox(height: 18),

                // 5. Main Timeline / Session List Content
                _buildSessionsList(
                  selectedTab: _selectedTab,
                  upcomingList: allUpcoming,
                  pastList: allPast,
                  bookType: bookType,
                  now: now,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSessionsList({
    required int selectedTab,
    required List<SessionBookingDto> upcomingList,
    required List<SessionBookingDto> pastList,
    required String? bookType,
    required DateTime now,
  }) {
    if (selectedTab == 1) {
      // Upcoming Only
      if (upcomingList.isEmpty) {
        return _SessionEmptyState(
          isPast: false,
          isFiltered: false,
          bookType: bookType,
          onBook: bookType == null
              ? null
              : () => context.go('${RoutePaths.studentBookNew}?type=$bookType'),
          onResetFilters: null,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            title: 'UPCOMING TIMELINE (${upcomingList.length})',
            subtitle: 'Nearest sessions first',
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < upcomingList.length; i++)
            _SessionTimelineCard(
              booking: upcomingList[i],
              isPast: false,
              now: now,
            ),
        ],
      );
    }

    if (selectedTab == 2) {
      // Past Only
      if (pastList.isEmpty) {
        return _SessionEmptyState(
          isPast: true,
          isFiltered: false,
          bookType: bookType,
          onBook: bookType == null
              ? null
              : () => context.go('${RoutePaths.studentBookNew}?type=$bookType'),
          onResetFilters: null,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            title: 'SESSION HISTORY (${pastList.length})',
            subtitle: 'Latest sessions first',
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < pastList.length; i++)
            _SessionTimelineCard(booking: pastList[i], isPast: true, now: now),
        ],
      );
    }

    // All Sessions View (Upcoming first, then Past History)
    final bool isEmptyAll = upcomingList.isEmpty && pastList.isEmpty;
    if (isEmptyAll) {
      return _SessionEmptyState(
        isPast: false,
        isFiltered: false,
        bookType: bookType,
        onBook: bookType == null
            ? null
            : () => context.go('${RoutePaths.studentBookNew}?type=$bookType'),
        onResetFilters: null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcomingList.isNotEmpty) ...[
          _SectionLabel(
            title: 'UPCOMING SESSIONS (${upcomingList.length})',
            subtitle: 'Chronological timeline (nearest first)',
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < upcomingList.length; i++)
            _SessionTimelineCard(
              booking: upcomingList[i],
              isPast: false,
              now: now,
            ),
          const SizedBox(height: 24),
        ],
        if (pastList.isNotEmpty) ...[
          _SectionLabel(
            title: 'PAST SESSION HISTORY (${pastList.length})',
            subtitle: 'Historical learning journey (latest first)',
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < pastList.length; i++)
            _SessionTimelineCard(booking: pastList[i], isPast: true, now: now),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: StudentColors.indigoPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: StudentColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '•  $subtitle',
          style: const TextStyle(
            fontSize: 11.5,
            color: StudentColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// 1. Modern Page Header
/// ---------------------------------------------------------------------------
class _SessionsHeader extends StatelessWidget {
  const _SessionsHeader({required this.type, required this.onBook});

  final String? type;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 650;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: StudentColors.heroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: StudentColors.textPrimary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient shapes
          Positioned(
            top: -30,
            right: 40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    StudentColors.forestSoft.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 140,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    StudentColors.amberPrimary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Sessions 👋',
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep track of your classes, mentoring sessions, and learning progress.',
                        style: TextStyle(
                          fontSize: isMobile ? 12.5 : 14,
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (type != null) ...[
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: onBook,
                    style: FilledButton.styleFrom(
                      backgroundColor: StudentColors.amberPrimary,
                      foregroundColor: StudentColors.textPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 18,
                        vertical: isMobile ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                    ),
                    label: Text(
                      bookingActionLabel(type),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 2. Session Overview KPI Strip
/// ---------------------------------------------------------------------------
class _SessionsOverviewStrip extends StatelessWidget {
  const _SessionsOverviewStrip({
    required this.completedCount,
    required this.totalSessions,
    required this.nextSession,
    required this.now,
  });

  final int completedCount;
  final int totalSessions;
  final SessionBookingDto? nextSession;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final nextSessionLabel = _formatNextSessionLabel(nextSession, now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final cards = [
          _OverviewCard(
            label: 'Completed',
            value: '$completedCount',
            subtitle: 'Attended sessions',
            icon: Icons.check_circle_outline_rounded,
            accentColor: StudentColors.emeraldDark,
            bgColor: StudentColors.emeraldLight,
          ),
          _OverviewCard(
            label: 'Total Sessions',
            value: '$totalSessions',
            subtitle: 'Lifetime classes',
            icon: Icons.auto_stories_rounded,
            accentColor: StudentColors.indigoPrimary,
            bgColor: StudentColors.indigoLight,
          ),
          _OverviewCard(
            label: 'Next Session',
            value: nextSessionLabel.primary,
            subtitle: nextSessionLabel.secondary,
            icon: Icons.alarm_rounded,
            accentColor: StudentColors.amberDark,
            bgColor: StudentColors.amberLight,
          ),
        ];

        if (isMobile) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < cards.length; i++)
                SizedBox(
                  width: i == 2
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2,
                  child: cards[i],
                ),
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  ({String primary, String secondary}) _formatNextSessionLabel(
    SessionBookingDto? session,
    DateTime now,
  ) {
    if (session == null) {
      return (primary: '— / —', secondary: 'No classes scheduled');
    }
    final startsAt = session.startsAt;
    if (startsAt == null) {
      return (primary: formatHm(session.start), secondary: session.date);
    }
    final diff = startsAt.difference(now);
    if (session.attendance?.canJoin == true || session.isOngoingAt(now)) {
      return (primary: 'Live Now', secondary: 'Ready to join');
    }
    if (startsAt.day == now.day &&
        startsAt.month == now.month &&
        startsAt.year == now.year) {
      return (primary: formatHm(session.start), secondary: 'Today');
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (startsAt.day == tomorrow.day &&
        startsAt.month == tomorrow.month &&
        startsAt.year == tomorrow.year) {
      return (primary: formatHm(session.start), secondary: 'Tomorrow');
    }
    if (diff.inDays < 7) {
      return (
        primary: formatHm(session.start),
        secondary: 'In ${diff.inDays} days',
      );
    }
    return (
      primary: formatHm(session.start),
      secondary: formatPrettyDate(session.date),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudentColors.border),
        boxShadow: StudentColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: StudentColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: StudentColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 3. Spotlight "Next Session" Feature Card
/// ---------------------------------------------------------------------------
class _NextSessionFeatureCard extends StatelessWidget {
  const _NextSessionFeatureCard({
    required this.booking,
    required this.now,
    required this.onJoin,
    required this.onReschedule,
  });

  final SessionBookingDto booking;
  final DateTime now;
  final VoidCallback onJoin;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final startsAt = booking.startsAt;
    final isLive =
        booking.attendance?.canJoin == true || booking.isOngoingAt(now);
    final isMasterClass = booking.type == 'master_class';

    // Countdown / status pill
    final String countdownText;
    final Color badgeColor;
    final Color badgeBg;

    if (isLive) {
      countdownText = 'Happening Now';
      badgeColor = StudentColors.emeraldDark;
      badgeBg = StudentColors.emeraldLight;
    } else if (startsAt != null) {
      final diff = startsAt.difference(now);
      if (diff.inMinutes <= 0) {
        countdownText = 'Starting now';
        badgeColor = StudentColors.emeraldDark;
        badgeBg = StudentColors.emeraldLight;
      } else if (diff.inMinutes <= 60) {
        countdownText = 'Starts in ${diff.inMinutes} min';
        badgeColor = StudentColors.amberDark;
        badgeBg = StudentColors.amberLight;
      } else if (startsAt.day == now.day && startsAt.month == now.month) {
        countdownText = 'Today at ${formatHm(booking.start)}';
        badgeColor = StudentColors.indigoPrimary;
        badgeBg = StudentColors.indigoLight;
      } else if (diff.inDays <= 1) {
        countdownText = 'Tomorrow at ${formatHm(booking.start)}';
        badgeColor = StudentColors.indigoPrimary;
        badgeBg = StudentColors.indigoLight;
      } else {
        countdownText = 'Starts in ${diff.inDays} days';
        badgeColor = StudentColors.textSecondary;
        badgeBg = StudentColors.surfaceMuted;
      }
    } else {
      countdownText = 'Scheduled';
      badgeColor = StudentColors.textSecondary;
      badgeBg = StudentColors.surfaceMuted;
    }

    final isMobile = MediaQuery.sizeOf(context).width < 650;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive
              ? StudentColors.emeraldPrimary
              : StudentColors.indigoPrimary.withValues(alpha: 0.3),
          width: isLive ? 1.6 : 1.2,
        ),
        boxShadow: isLive
            ? StudentColors.glow(StudentColors.emeraldPrimary, opacity: 0.15)
            : StudentColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spotlight Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLive
                          ? StudentColors.emeraldLight
                          : StudentColors.indigoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLive ? Icons.videocam_rounded : Icons.star_rounded,
                          size: 13,
                          color: isLive
                              ? StudentColors.emeraldDark
                              : StudentColors.indigoPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isLive
                              ? 'LIVE SESSION SPOTLIGHT'
                              : 'NEXT UP ON CALENDAR',
                          style: TextStyle(
                            color: isLive
                                ? StudentColors.emeraldDark
                                : StudentColors.indigoPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      const _PulsingLiveDot(),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      countdownText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (booking.wasReassigned) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.sessionUpdated,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.yourMentorWasChangedDueToAnUnexpectedAvailabilityIssue} ${booking.teacherName ?? AppStrings.teacher}.',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Main Info Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Avatar
              AcademyAvatar(
                name: booking.teacherName ?? 'Teacher',
                size: isMobile ? 48 : 54,
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
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isMasterClass
                                ? StudentColors.indigoLight
                                : StudentColors.skyLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            booking.typeLabel,
                            style: TextStyle(
                              color: isMasterClass
                                  ? StudentColors.indigoPrimary
                                  : StudentColors.skyDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '30 min duration',
                          style: TextStyle(
                            color: StudentColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.teacherName != null &&
                              booking.teacherName!.isNotEmpty
                          ? 'with ${booking.teacherName}'
                          : 'with Assigned Faculty Mentor',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: StudentColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatPrettyDate(booking.date)} · ${formatHm(booking.start)} – ${formatHm(booking.end)}',
                      style: const TextStyle(
                        color: StudentColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Row
          Row(
            children: [
              if (isLive) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onJoin,
                    style: FilledButton.styleFrom(
                      backgroundColor: StudentColors.emeraldDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: Text(
                      isMasterClass
                          ? 'Join Master Class Now'
                          : 'Join Introduction Call Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: StudentColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: StudentColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: StudentColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMasterClass
                                ? AppStrings.joinOpens2MinBeforeClass
                                : AppStrings.joinOpens2MinBeforeCall,
                            style: const TextStyle(
                              color: StudentColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onReschedule,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StudentColors.indigoPrimary,
                    side: BorderSide(
                      color: StudentColors.indigoPrimary.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 15),
                  label: const Text(
                    'Reschedule',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 4. Session tabs
/// ---------------------------------------------------------------------------
class _SessionsFilterBar extends StatelessWidget {
  const _SessionsFilterBar({
    required this.selectedTab,
    required this.allCount,
    required this.upcomingCount,
    required this.pastCount,
    required this.onTabChanged,
  });

  final int selectedTab;
  final int allCount;
  final int upcomingCount;
  final int pastCount;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudentColors.border),
        boxShadow: StudentColors.cardShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterTabPill(
              label: 'All Sessions',
              count: allCount,
              isSelected: selectedTab == 0,
              onTap: () => onTabChanged(0),
            ),
            const SizedBox(width: 8),
            _FilterTabPill(
              label: 'Upcoming',
              count: upcomingCount,
              isSelected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
            const SizedBox(width: 8),
            _FilterTabPill(
              label: 'Past Sessions',
              count: pastCount,
              isSelected: selectedTab == 2,
              onTap: () => onTabChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabPill extends StatelessWidget {
  const _FilterTabPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? StudentColors.indigoPrimary
              : StudentColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? StudentColors.indigoPrimary
                : StudentColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : StudentColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : StudentColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 5. Chronological Session Timeline Card
/// ---------------------------------------------------------------------------
const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];
const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class _SessionTimelineCard extends ConsumerStatefulWidget {
  const _SessionTimelineCard({
    required this.booking,
    required this.isPast,
    required this.now,
  });

  final SessionBookingDto booking;
  final bool isPast;
  final DateTime now;

  @override
  ConsumerState<_SessionTimelineCard> createState() =>
      _SessionTimelineCardState();
}

class _SessionTimelineCardState extends ConsumerState<_SessionTimelineCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPast = widget.isPast;
    final now = widget.now;

    final dt = DateTime.tryParse(booking.date);
    final month = dt != null && dt.month >= 1 && dt.month <= 12
        ? _months[dt.month - 1]
        : '—';
    final day = dt != null ? '${dt.day}' : '—';
    final weekday = dt != null && dt.weekday >= 1 && dt.weekday <= 7
        ? _weekdays[dt.weekday - 1]
        : '';

    final isToday =
        dt != null &&
        dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    final isTomorrow =
        dt != null &&
        dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day + 1;

    final ongoing = !isPast && booking.isOngoingAt(now);
    final isMasterClass = booking.type == 'master_class';
    final att = booking.attendance;
    final canJoin = att?.canJoin == true || ongoing;

    final teacherDisplayName =
        (booking.teacherName != null && booking.teacherName!.isNotEmpty)
        ? booking.teacherName!
        : 'Assigned Master Teacher';

    final isMobile = MediaQuery.sizeOf(context).width < 680;

    // 1. Date Block
    final dateBlock = Container(
      width: isMobile ? 54 : 64,
      height: isMobile ? 60 : 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? StudentColors.emeraldPrimary
              : (isTomorrow
                    ? StudentColors.indigoPrimary
                    : StudentColors.border),
          width: isToday || isTomorrow ? 1.6 : 1.0,
        ),
        boxShadow: StudentColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isToday
                  ? StudentColors.emeraldDark
                  : (isTomorrow
                        ? StudentColors.indigoPrimary
                        : StudentColors.textPrimary),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                isToday ? 'TODAY' : month,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: isToday
                        ? StudentColors.emeraldDark
                        : StudentColors.textPrimary,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                if (weekday.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    weekday,
                    style: const TextStyle(
                      color: StudentColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // 2. Info Content
    final infoContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category + Status row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Session Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: isMasterClass
                    ? StudentColors.indigoLight
                    : StudentColors.skyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMasterClass
                        ? Icons.school_rounded
                        : Icons.phone_in_talk_rounded,
                    size: 13,
                    color: isMasterClass
                        ? StudentColors.indigoPrimary
                        : StudentColors.skyDark,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    booking.typeLabel,
                    style: TextStyle(
                      color: isMasterClass
                          ? StudentColors.indigoPrimary
                          : StudentColors.skyDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Live / Status Badges
            if (canJoin)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.emeraldLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StudentColors.emeraldBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulsingLiveDot(),
                    const SizedBox(width: 5),
                    Text(
                      ongoing ? 'CLASS IN PROGRESS' : 'READY TO JOIN',
                      style: const TextStyle(
                        color: StudentColors.emeraldDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              )
            else if (booking.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.emeraldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: StudentColors.emeraldDark,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: StudentColors.emeraldDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
            else if (booking.isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Cancelled',
                  style: TextStyle(
                    color: StudentColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              )
            else if (!isPast && booking.isScheduled)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.indigoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Confirmed',
                  style: TextStyle(
                    color: StudentColors.indigoPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Time slot & duration
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 14,
              color: StudentColors.indigoPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              '${formatHm(booking.start)} – ${formatHm(booking.end)}',
              style: const TextStyle(
                color: StudentColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${formatPrettyDate(booking.date)})',
              style: const TextStyle(
                color: StudentColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Teacher profile
        Row(
          children: [
            AcademyAvatar(name: teacherDisplayName, size: 24),
            const SizedBox(width: 8),
            Text(
              teacherDisplayName,
              style: const TextStyle(
                color: StudentColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '• Faculty Mentor',
              style: TextStyle(color: StudentColors.textMuted, fontSize: 11),
            ),
          ],
        ),

        // Last chance alert
        if (att?.isLastChance == true &&
            (att?.lastChanceMessage ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: StudentColors.amberLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: StudentColors.amberBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: StudentColors.amberDark,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    att!.lastChanceMessage!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: StudentColors.amberDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    // 3. Action Buttons
    final actionButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (canJoin)
          FilledButton.icon(
            onPressed: () async {
              await ref
                  .read(scheduleRepositoryProvider)
                  .studentJoinClass(booking.id);
              ref.invalidate(studentBookingsProvider);
              final url = booking.meetingUrl;
              if (url != null && url.isNotEmpty) {
                await launchUrl(
                  Uri.parse(url),
                  webOnlyWindowName: AppStrings.blank,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: StudentColors.emeraldDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.videocam_rounded, size: 16),
            label: Text(
              ongoing
                  ? 'Join Meet'
                  : (isMasterClass ? 'Join Class' : 'Join Call'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          )
        else if (!isPast && booking.isScheduled) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: StudentColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: StudentColors.textMuted,
                ),
                SizedBox(width: 4),
                Text(
                  'Join opens 2m before',
                  style: TextStyle(
                    color: StudentColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go(
              '${RoutePaths.studentBookNew}?type=${booking.type}&bookingId=${booking.id}',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: StudentColors.indigoPrimary,
              side: BorderSide(
                color: StudentColors.indigoPrimary.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.edit_calendar_outlined, size: 13),
            label: const Text(
              'Reschedule',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
            ),
          ),
        ],

        if (att?.canReportTeacherDidNotJoin == true)
          OutlinedButton.icon(
            onPressed: () async {
              final sessionLabel = isMasterClass
                  ? 'class'
                  : AppStrings.introductionCall;
              final message = await showAttendanceReportDialog(
                context,
                title: AppStrings.teacherDidnTJoin,
                hint: 'Tell Admin what happened on this $sessionLabel:',
              );
              if (message == null) return;
              await ref
                  .read(scheduleRepositoryProvider)
                  .studentReportTeacher(booking.id, message);
              ref.invalidate(studentBookingsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.reportSentToAdmin)),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: StudentColors.amberDark,
              side: const BorderSide(color: StudentColors.amberDark),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.report_problem_outlined, size: 13),
            label: const Text(
              'Teacher didn\'t join',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
            ),
          ),

        if (att?.reportSubmitted == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StudentColors.amberLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Report Sent to Admin',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: StudentColors.amberDark,
              ),
            ),
          ),

        if (att?.rebookingAvailable == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StudentColors.indigoLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Rebooking Available',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: StudentColors.indigoPrimary,
              ),
            ),
          ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? StudentColors.indigoPrimary.withValues(alpha: 0.4)
                : (canJoin
                      ? StudentColors.emeraldBorder
                      : StudentColors.border),
            width: canJoin ? 1.4 : 1.0,
          ),
          boxShadow: _hovered
              ? StudentColors.cardShadowHover
              : StudentColors.cardShadow,
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dateBlock,
                      const SizedBox(width: 12),
                      Expanded(child: infoContent),
                    ],
                  ),
                  if (actionButtons.children.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dateBlock,
                  const SizedBox(width: 16),
                  Expanded(child: infoContent),
                  const SizedBox(width: 16),
                  actionButtons,
                ],
              ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 6. Empty State
/// ---------------------------------------------------------------------------
class _SessionEmptyState extends StatelessWidget {
  const _SessionEmptyState({
    required this.isPast,
    required this.isFiltered,
    this.bookType,
    this.onBook,
    this.onResetFilters,
  });

  final bool isPast;
  final bool isFiltered;
  final String? bookType;
  final VoidCallback? onBook;
  final VoidCallback? onResetFilters;

  @override
  Widget build(BuildContext context) {
    final title = isFiltered
        ? 'No matching sessions'
        : (isPast ? 'No completed sessions yet' : 'No sessions scheduled yet');

    final subtitle = isFiltered
        ? 'Try clearing your filter settings to see other learning sessions.'
        : (isPast
              ? 'Your learning history will appear here after your first attended master class.'
              : 'Book your next live session to keep your learning journey moving forward.');

    final icon = isFiltered
        ? Icons.filter_alt_off_rounded
        : (isPast ? Icons.history_edu_rounded : Icons.calendar_month_outlined);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudentColors.border),
        boxShadow: StudentColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: StudentColors.indigoLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: StudentColors.indigoPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: StudentColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: StudentColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (isFiltered && onResetFilters != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onResetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: StudentColors.indigoPrimary,
                side: const BorderSide(color: StudentColors.indigoPrimary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Reset All Filters',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ] else if (!isPast && onBook != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                backgroundColor: StudentColors.indigoPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: Text(
                bookingActionLabel(bookType),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Pulsing Live Dot Animation
/// ---------------------------------------------------------------------------
class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1400),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final val = (math.sin(_controller.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: StudentColors.emeraldPrimary,
            boxShadow: [
              BoxShadow(
                color: StudentColors.emeraldPrimary.withValues(
                  alpha: 0.4 + 0.5 * val,
                ),
                blurRadius: 4 + 4 * val,
                spreadRadius: 1 + 2 * val,
              ),
            ],
          ),
        );
      },
    );
  }
}

class StudentBookingWizardPage extends ConsumerStatefulWidget {
  const StudentBookingWizardPage({super.key, this.type, this.bookingId});

  final String? type;
  final String? bookingId;

  @override
  ConsumerState<StudentBookingWizardPage> createState() =>
      _StudentBookingWizardPageState();
}

class _StudentBookingWizardPageState
    extends ConsumerState<StudentBookingWizardPage> {
  String? _type;
  TeacherDto? _teacher;
  DateTime? _date;
  String? _start;
  bool _saving = false;
  bool _typeLocked = false;
  bool _shownMasterClassLockDialog = false;

  bool get _reschedule => widget.bookingId != null;

  @override
  void initState() {
    super.initState();
    final incoming = widget.type;
    _type = incoming == null || incoming.isEmpty ? null : incoming;
    _typeLocked = _reschedule || _type != null;
  }

  String _resolvedType(BookingEligibilityDto eligibility) {
    if (_reschedule && _type != null) {
      return _type!;
    }
    final canIntro = eligibility.canBookIntroduction;
    final canMaster =
        eligibility.canBookMasterClass && eligibility.masterClassRemaining > 0;
    if (canIntro && !canMaster) {
      return 'introduction_call';
    }
    if (canMaster && !canIntro) {
      return 'master_class';
    }
    if (_type == 'master_class' && !canMaster && canIntro) {
      return 'introduction_call';
    }
    if (_type == 'introduction_call' && !canIntro && canMaster) {
      return 'master_class';
    }
    if (_type == 'master_class' && canMaster) {
      return 'master_class';
    }
    if (_type == 'introduction_call' && canIntro) {
      return 'introduction_call';
    }
    if (canIntro) {
      return 'introduction_call';
    }
    return canMaster ? 'master_class' : '';
  }

  @override
  Widget build(BuildContext context) {
    final assessment = ref.watch(studentAssessmentProvider);
    final assessmentPending = assessment.maybeWhen(
      data: (payload) => payload.available && payload.assessment != null,
      orElse: () => false,
    );

    if (assessmentPending) {
      return StudentScaffold(
        title: _reschedule ? AppStrings.reschedule : AppStrings.bookSession,
        body: const BookingQuestionnaireGuardCard(),
      );
    }

    final eligibility = ref.watch(studentEligibilityProvider);
    final teachers = ref.watch(studentBookingTeachersProvider);
    final bookings = ref.watch(studentBookingsProvider);
    SessionBookingDto? current;
    if (widget.bookingId != null) {
      final items = bookings.asData?.value ?? const <SessionBookingDto>[];
      for (final item in items) {
        if (item.id == widget.bookingId) {
          current = item;
          break;
        }
      }
    }

    return StudentScaffold(
      title: _reschedule ? AppStrings.reschedule : AppStrings.bookSession,
      body: eligibility.when(
        skipLoadingOnReload: true,
        loading: () => const AcademySkeleton(height: 220),
        error: (_, _) => AcademyError(
          onRetry: () => ref.invalidate(studentEligibilityProvider),
        ),
        data: (state) {
          if (!_reschedule &&
              widget.type == 'master_class' &&
              state.masterClassOpensNextMonth) {
            if (!_shownMasterClassLockDialog) {
              _shownMasterClassLockDialog = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) {
                  return;
                }
                final nav = GoRouter.of(context);
                await MasterClassOpensNextMonthDialog.show(context);
                if (!mounted) {
                  return;
                }
                nav.go(RoutePaths.studentBookings);
              });
            }
            return const AcademySurface(
              child: Text(
                AppStrings.masterClassOpensNextMonthBody,
                style: TextStyle(
                  color: Academy.ink,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final canMaster =
              state.canBookMasterClass && state.masterClassRemaining > 0;
          final canIntro = state.canBookIntroduction;
          final type = _resolvedType(state);
          final canChooseType =
              !_reschedule && canIntro && canMaster && !_typeLocked;
          final isMobile = MediaQuery.sizeOf(context).width < 768;
          if (!_reschedule && !canIntro && !canMaster) {
            return AcademySurface(
              child: Text(
                state.masterClassOpensNextMonth
                    ? AppStrings.masterClassOpensNextMonthBody
                    : AppStrings.noSessionsLeftToBookThisMonth,
                style: const TextStyle(
                  color: Academy.ink,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return ListView(
            padding: EdgeInsets.only(bottom: isMobile ? 24 : 48),
            children: [
              Text(
                _reschedule
                    ? AppStrings.rescheduleYourSession
                    : bookingActionLabel(type),
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.w800,
                  color: Academy.ink,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                type == 'introduction_call'
                    ? (state.introductionLastChance
                          ? AppStrings
                                .thisIsYourLastChanceToCompleteTheIntroductionCall
                          : AppStrings
                                .chooseATeacherThenPickOneAvailableTimeForYour)
                    : AppStrings.chooseATeacherThenPickOneAvailableTimeForYour2,
                style: TextStyle(
                  color: Academy.muted,
                  height: 1.4,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
              if (_reschedule && current != null) ...[
                SizedBox(height: isMobile ? 12 : 20),
                AcademySurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AcademyLabel(AppStrings.currentBooking),
                      const SizedBox(height: 8),
                      Text(
                        current.teacherName ?? AppStrings.teacher,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(formatPrettyDate(current.date)),
                      Text(formatHm(current.start)),
                    ],
                  ),
                ),
              ],
              if (canChooseType) ...[
                SizedBox(height: isMobile ? 14 : 24),
                _TypeStep(
                  canIntro: canIntro,
                  canMaster: canMaster,
                  introLastChance: state.introductionLastChance,
                  selected: type,
                  onSelect: (value) => setState(() {
                    _type = value;
                    _start = null;
                  }),
                ),
              ],
              SizedBox(height: isMobile ? 14 : 24),
              const AcademyLabel(AppStrings.yourFaculty),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                'View a mentor profile or book an available time.',
                style: TextStyle(
                  color: Academy.muted,
                  height: 1.4,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 16),
              teachers.when(
                skipLoadingOnReload: true,
                loading: () => AcademySkeleton(height: isMobile ? 120 : 220),
                error: (_, _) => AcademyError(
                  onRetry: () => ref.invalidate(studentBookingTeachersProvider),
                ),
                data: (items) => Column(
                  children: [
                    for (final teacher in items) ...[
                      MentorBookingCard(
                        teacher: teacher,
                        selected: _teacher?.id == teacher.id,
                        onSelect: () => setState(() {
                          _teacher = teacher;
                          _date ??= DateTime.now();
                          _start = null;
                        }),
                        onViewProfile: () => context.go(
                          '${RoutePaths.studentMentorProfileFor(teacher.id)}?type=${_type ?? 'master_class'}',
                        ),
                      ),
                      if (_teacher?.id == teacher.id) ...[
                        SizedBox(height: isMobile ? 8 : 10),
                        _TimeStep(
                          teacherName: teacher.fullName,
                          teacherId: teacher.id,
                          date: formatScheduleDate(_date ?? DateTime.now()),
                          selected: _start,
                          onSelect: (start) => setState(() => _start = start),
                          onChangeDate: () async {
                            final today = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date ?? today,
                              firstDate: today,
                              lastDate: today.add(const Duration(days: 120)),
                            );
                            if (picked != null) {
                              setState(() {
                                _date = picked;
                                _start = null;
                              });
                            }
                          },
                        ),
                        if (_date != null && _start != null) ...[
                          const SizedBox(height: 10),
                          _SummaryStep(
                            type: type,
                            lastChance:
                                type == 'introduction_call' &&
                                state.introductionLastChance,
                            teacher: teacher,
                            date: _date,
                            start: _start,
                            busy: _saving,
                            onBack: () => setState(() => _start = null),
                            onConfirm: () {
                              _type = type;
                              _confirm();
                            },
                          ),
                        ],
                      ],
                      SizedBox(height: isMobile ? 10 : 14),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirm() async {
    if (_teacher == null || _date == null || _start == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(scheduleRepositoryProvider);
      final date = formatScheduleDate(_date!);
      SessionBookingDto? confirmed;
      if (widget.bookingId == null) {
        confirmed = await repo.createStudentBooking(
          teacherId: _teacher!.id,
          type: _type ?? 'introduction_call',
          date: date,
          start: _start!,
        );
      } else {
        confirmed = await repo.rescheduleStudentBooking(
          bookingId: widget.bookingId!,
          teacherId: _teacher!.id,
          date: date,
          start: _start!,
        );
      }
      ref.invalidate(studentBookingsProvider);
      ref.invalidate(studentEligibilityProvider);
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      final type = _type ?? 'introduction_call';
      final booking = confirmed;
      Future<void> onJoin() async {
        await ref.read(scheduleRepositoryProvider).studentJoinClass(booking.id);
        ref.invalidate(studentBookingsProvider);
        final url = booking.meetingUrl;
        if (url != null && url.isNotEmpty) {
          await launchUrl(Uri.parse(url), webOnlyWindowName: AppStrings.blank);
        }
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _BookingConfirmedDialog(
          reschedule: _reschedule,
          type: type,
          teacherName: _teacher!.fullName,
          date: date,
          start: _start!,
          meetingUrl: booking.meetingUrl,
          canJoin: booking.attendance?.canJoin == true,
          onJoin: onJoin,
          onContinue: () => Navigator.of(dialogContext).pop(),
        ),
      );
      if (mounted) {
        context.go(RoutePaths.studentBookings);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showFailure(context, error);
      }
    }
  }
}

class _TypeStep extends StatelessWidget {
  const _TypeStep({
    required this.canIntro,
    required this.canMaster,
    required this.onSelect,
    this.introLastChance = false,
    this.selected,
  });

  final bool canIntro;
  final bool canMaster;
  final bool introLastChance;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AcademyLabel(AppStrings.whatWouldYouLikeToBook),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 720;
            final cards = <Widget>[
              if (canIntro)
                _ChoiceCard(
                  title: AppStrings.introductionCall,
                  body: introLastChance
                      ? AppStrings
                            .lastChancePleaseBeAvailableForThisInterviewAMissed
                      : AppStrings.meetYourMasterTeacherIfThisCallIsMissedYou,
                  selected: selected == 'introduction_call',
                  onTap: () => onSelect('introduction_call'),
                ),
              if (canMaster)
                _ChoiceCard(
                  title: AppStrings.masterClass,
                  body: AppStrings.yourFocusedMonthlySession,
                  selected: selected == 'master_class',
                  onTap: () => onSelect('master_class'),
                ),
            ];
            if (stacked) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.body,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return AcademySurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: Academy.ink,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            body,
            style: TextStyle(
              color: Academy.muted,
              height: 1.4,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          if (selected) ...[
            SizedBox(height: isMobile ? 6 : 8),
            const Text(
              AppStrings.selected,
              style: TextStyle(
                color: Brand.goldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeStep extends ConsumerWidget {
  const _TimeStep({
    required this.teacherName,
    required this.teacherId,
    required this.date,
    required this.selected,
    required this.onSelect,
    required this.onChangeDate,
  });

  final String teacherName;
  final String teacherId;
  final String date;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onChangeDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(
      studentAvailabilityProvider((teacherId: teacherId, date: date)),
    );
    return AcademySurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Choose a time · $date',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Brand.navy,
                ),
              ),
              AcademyButton(
                outlined: true,
                icon: Icons.calendar_today_outlined,
                label: AppStrings.changeDate,
                onPressed: onChangeDate,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'With $teacherName',
            style: const TextStyle(
              color: Academy.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          day.when(
            skipLoadingOnReload: true,
            loading: () => const AcademySkeleton(height: 120),
            error: (_, _) => AcademyError(
              onRetry: () => ref.invalidate(
                studentAvailabilityProvider((teacherId: teacherId, date: date)),
              ),
            ),
            data: (value) {
              if (value.slots.isEmpty) {
                return const Text(
                  AppStrings.noTimesOnThisDatePleaseChooseAnotherDate,
                );
              }
              return SlotGrid(
                slots: value.slots,
                selectedStart: selected,
                colorFor: studentSlotColor,
                onSelectAvailable: onSelect,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.type,
    required this.teacher,
    required this.date,
    required this.start,
    required this.busy,
    required this.onBack,
    required this.onConfirm,
    this.lastChance = false,
  });

  final String type;
  final bool lastChance;
  final TeacherDto? teacher;
  final DateTime? date;
  final String? start;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final end = start == null ? '' : _endFrom(start!);
    return AcademySurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel(AppStrings.bookingSummary),
          const SizedBox(height: 12),
          Text(
            sessionTypeLabel(type),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Academy.ink,
            ),
          ),
          const SizedBox(height: 12),
          _line(AppStrings.teacher, teacher?.fullName ?? '—'),
          _line(
            AppStrings.date2,
            date == null ? '—' : formatPrettyDate(formatScheduleDate(date!)),
          ),
          _line(
            AppStrings.time,
            start == null ? '—' : '${formatHm(start!)} – ${formatHm(end)}',
          ),
          if (lastChance) ...[
            const SizedBox(height: 12),
            const Text(
              AppStrings.lastChancePleaseBeAvailableAtThisTimeIfThis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: StudentColors.amberDeep,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AcademyButton(
                outlined: true,
                label: AppStrings.changeTime,
                onPressed: busy ? null : onBack,
              ),
              AcademyButton(
                label: type == 'master_class'
                    ? AppStrings.confirmMasterClass
                    : AppStrings.confirmIntroduction,
                busy: busy,
                onPressed: busy ? null : onConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: Academy.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Academy.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _endFrom(String start) {
    final parts = start.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final total = hour * 60 + minute + 30;
    final endHour = (total ~/ 60).toString().padLeft(2, '0');
    final endMinute = (total % 60).toString().padLeft(2, '0');
    return '$endHour:$endMinute';
  }
}

class _BookingConfirmedDialog extends StatelessWidget {
  const _BookingConfirmedDialog({
    required this.reschedule,
    required this.type,
    required this.teacherName,
    required this.date,
    required this.start,
    required this.onContinue,
    this.meetingUrl,
    this.canJoin = false,
    this.onJoin,
  });

  final bool reschedule;
  final String type;
  final String teacherName;
  final String date;
  final String start;
  final VoidCallback onContinue;
  final String? meetingUrl;
  final bool canJoin;
  final Future<void> Function()? onJoin;

  @override
  Widget build(BuildContext context) {
    final session = sessionTypeLabel(type);
    final title = reschedule
        ? AppStrings.sessionRescheduled
        : '$session confirmed';
    final body = reschedule
        ? 'Your $session has been moved to the time below.'
        : 'Your $session is booked. We look forward to seeing you.';
    final end = _slotEnd(start);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
        vertical: MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Brand.gold.withValues(alpha: 0.35), width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
            MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
            MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
            MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.gold.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Brand.gold.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Brand.navy,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Academy.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Academy.muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detail(AppStrings.session, session),
                    _detail(AppStrings.teacher, teacherName),
                    _detail(AppStrings.date2, formatPrettyDate(date)),
                    _detail(
                      AppStrings.time,
                      '${formatHm(start)} – ${formatHm(end)}',
                      last: true,
                    ),
                  ],
                ),
              ),
              if ((meetingUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  AppStrings.youAndYourTeacherJoinTheSameGoogleMeetFor,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Academy.muted, height: 1.45),
                ),
                const SizedBox(height: 12),
                if (canJoin && onJoin != null)
                  JoinMeetButton(
                    meetingUrl: meetingUrl,
                    label: AppStrings.joinGoogleMeet,
                    onPressed: onJoin,
                  )
                else
                  Text(
                    type == 'master_class'
                        ? AppStrings.joinAvailable2MinutesBeforeClass
                        : AppStrings.joinAvailable2MinutesBeforeTheCall,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Academy.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: AcademyButton(
                  label: AppStrings.viewMySessions,
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Academy.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Academy.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _slotEnd(String start) {
  final parts = start.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final total = hour * 60 + minute + 30;
  return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}
