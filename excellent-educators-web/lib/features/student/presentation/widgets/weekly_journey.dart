import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/fresh_student_onboarding.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class WeeklyJourneyWidget extends StatelessWidget {
  const WeeklyJourneyWidget({super.key, required this.snapshot, this.learning});

  final StudentJourneySnapshot snapshot;
  final LearningDashboardDto? learning;

  @override
  Widget build(BuildContext context) {
    final currentWeek = learning?.currentWeek ?? 1;
    final isAssignmentCompleted = !(learning?.assignmentPending ?? true);
    final hasVideo = learning?.week?.hasVideo ?? false;
    final hasScore = learning?.week?.score != null;
    final isMasterCompleted =
        snapshot.masterClass.phase == JourneyPhase.completed;
    final isMasterScheduled =
        snapshot.masterClass.phase == JourneyPhase.current &&
        snapshot.nextSession != null;

    // Define the 5 pedagogical milestones for this week
    final steps = [
      _JourneyStepData(
        day: 'STEP 1',
        title: 'Weekly Video',
        subtitle: 'Core Concept',
        icon: Icons.play_circle_fill_rounded,
        status: hasVideo ? _StepStatus.completed : _StepStatus.current,
        actionLabel: 'Watch Video',
        onTap: () {
          final videoUrl = learning?.week?.videoUrl;
          if (videoUrl != null && videoUrl.isNotEmpty) {
            final journeyId = learning?.week?.journeyId;
            if (journeyId != null) {
              context.go(
                RoutePaths.studentJournalWeekFor(journeyId, currentWeek),
              );
            } else {
              context.go(RoutePaths.studentJournal);
            }
          } else {
            context.go(RoutePaths.studentJournal);
          }
        },
      ),
      _JourneyStepData(
        day: 'STEP 2',
        title: 'Aptitude Challenge',
        subtitle: hasScore
            ? '${learning!.week!.score!.percentage}% Score'
            : 'Weekly Quiz',
        icon: Icons.psychology_rounded,
        status: isAssignmentCompleted
            ? _StepStatus.completed
            : (hasVideo ? _StepStatus.current : _StepStatus.upcoming),
        actionLabel: isAssignmentCompleted ? 'Review' : 'Start',
        onTap: () {
          final journeyId = learning?.week?.journeyId;
          if (journeyId != null && journeyId.isNotEmpty) {
            context.go(
              RoutePaths.studentJournalWeekFor(journeyId, currentWeek),
            );
          } else {
            context.go(RoutePaths.studentJournal);
          }
        },
      ),
      _JourneyStepData(
        day: 'STEP 3',
        title: 'Master Class',
        subtitle: isMasterScheduled
            ? 'Scheduled'
            : (isMasterCompleted ? 'Completed' : '1-on-1 Mentor'),
        icon: Icons.record_voice_over_rounded,
        status: isMasterCompleted
            ? _StepStatus.completed
            : (isMasterScheduled || snapshot.canBookMasterClass
                  ? _StepStatus.current
                  : _StepStatus.upcoming),
        actionLabel: isMasterScheduled ? 'View' : 'Book',
        onTap: () {
          if (isMasterScheduled || isMasterCompleted) {
            context.go(RoutePaths.studentBookings);
          } else if (snapshot.masterClassOpensNextMonth) {
            MasterClassOpensNextMonthDialog.show(context);
          } else {
            context.go('${RoutePaths.studentBookNew}?type=master_class');
          }
        },
      ),
      _JourneyStepData(
        day: 'STEP 4',
        title: 'Learning Journal',
        subtitle: isAssignmentCompleted ? 'Reflected' : 'Reflect & Log',
        icon: Icons.history_edu_rounded,
        status: isAssignmentCompleted
            ? _StepStatus.completed
            : (isAssignmentCompleted
                  ? _StepStatus.current
                  : _StepStatus.upcoming),
        actionLabel: 'Open Journal',
        onTap: () => context.go(RoutePaths.studentJournal),
      ),
      _JourneyStepData(
        day: 'STEP 5',
        title: 'Mentor Review',
        subtitle: 'Feedback & Level',
        icon: Icons.military_tech_rounded,
        status: isMasterCompleted
            ? _StepStatus.completed
            : _StepStatus.upcoming,
        actionLabel: 'Guidance',
        onTap: () => context.go(RoutePaths.studentFeedback),
      ),
    ];

    final isMobile = MediaQuery.sizeOf(context).width < 680;

    return StudentCard(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: StudentColors.indigoLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      size: 18,
                      color: StudentColors.indigoPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MY LEARNING JOURNEY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: StudentColors.indigoPrimary,
                        ),
                      ),
                      Text(
                        'Week $currentWeek Learning Pathway',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: StudentColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.indigoLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${steps.where((s) => s.status == _StepStatus.completed).length} / 5 Done',
                  style: const TextStyle(
                    color: StudentColors.indigoPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Horizontal Journey Track
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _JourneyNodeCard(
                    step: steps[i],
                    isFirst: i == 0,
                    isLast: i == steps.length - 1,
                  ),
                  if (i < steps.length - 1)
                    _ConnectorLine(
                      isPassed: steps[i].status == _StepStatus.completed,
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

enum _StepStatus { completed, current, upcoming }

class _JourneyStepData {
  const _JourneyStepData({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.actionLabel,
    required this.onTap,
  });

  final String day;
  final String title;
  final String subtitle;
  final IconData icon;
  final _StepStatus status;
  final String actionLabel;
  final VoidCallback onTap;
}

class _JourneyNodeCard extends StatefulWidget {
  const _JourneyNodeCard({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final _JourneyStepData step;
  final bool isFirst;
  final bool isLast;

  @override
  State<_JourneyNodeCard> createState() => _JourneyNodeCardState();
}

class _JourneyNodeCardState extends State<_JourneyNodeCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final isCompleted = step.status == _StepStatus.completed;
    final isCurrent = step.status == _StepStatus.current;

    final Color statusColor;
    final Color iconBg;
    final Widget statusBadge;

    if (isCompleted) {
      statusColor = StudentColors.emeraldDark;
      iconBg = StudentColors.emeraldLight;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: StudentColors.emeraldLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: StudentColors.emeraldDark,
            ),
            SizedBox(width: 3),
            Text(
              'Done',
              style: TextStyle(
                color: StudentColors.emeraldDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (isCurrent) {
      statusColor = StudentColors.indigoPrimary;
      iconBg = StudentColors.indigoLight;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: StudentColors.indigoLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: StudentColors.indigoPrimary),
            SizedBox(width: 4),
            Text(
              'In Progress',
              style: TextStyle(
                color: StudentColors.indigoPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      statusColor = StudentColors.textMuted;
      iconBg = StudentColors.surfaceMuted;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: StudentColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Upcoming',
          style: TextStyle(
            color: StudentColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: step.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.white
                : (_hover ? Colors.white : const Color(0xFFF9FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? StudentColors.indigoPrimary
                  : (_hover
                        ? StudentColors.indigoPrimary.withValues(alpha: 0.4)
                        : StudentColors.border),
              width: isCurrent ? 1.6 : 1.0,
            ),
            boxShadow: isCurrent || _hover ? StudentColors.cardShadow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    step.day,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isCurrent
                          ? StudentColors.indigoPrimary
                          : StudentColors.textMuted,
                    ),
                  ),
                  statusBadge,
                ],
              ),
              const SizedBox(height: 10),

              // Icon in round container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: statusColor, size: 20),
              ),

              const SizedBox(height: 8),

              // Step Title
              Text(
                step.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: StudentColors.textPrimary,
                ),
              ),

              const SizedBox(height: 2),

              // Subtitle
              Text(
                step.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted
                      ? StudentColors.emeraldDark
                      : StudentColors.textSecondary,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              // Action link text
              Row(
                children: [
                  Text(
                    step.actionLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? StudentColors.indigoPrimary
                          : StudentColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 11,
                    color: isCurrent
                        ? StudentColors.indigoPrimary
                        : StudentColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine({required this.isPassed});

  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(top: 48),
      color: isPassed ? StudentColors.emeraldPrimary : StudentColors.border,
    );
  }
}
