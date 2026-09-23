import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_dashboard.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class StudentHeroSection extends ConsumerStatefulWidget {
  const StudentHeroSection({
    super.key,
    required this.student,
    required this.snapshot,
    this.learning,
  });

  final StudentDto student;
  final StudentJourneySnapshot snapshot;
  final LearningDashboardDto? learning;

  @override
  ConsumerState<StudentHeroSection> createState() => _StudentHeroSectionState();
}

class _StudentHeroSectionState extends ConsumerState<StudentHeroSection> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final snapshot = widget.snapshot;
    final learning = widget.learning;
    final firstName = student.fullName.trim().split(' ').first;
    final classLabel = student.classGrade > 0
        ? 'Class ${student.classGrade}'
        : null;
    final levelLabel = student.level != null && !student.level!.isEmpty
        ? student.level!.label
        : AppStrings.level;
    final batchLabel = student.batch != null && !student.batch!.isEmpty
        ? student.batch!.label
        : null;

    // Calculate level progression percentage
    final completedWeeks =
        learning?.completedWeeks ?? (snapshot.introductionCompleted ? 1 : 0);
    final totalWeeks = (learning?.totalWeeks ?? 0) > 0
        ? learning!.totalWeeks
        : 12;
    final progressFactor = (completedWeeks / (totalWeeks > 0 ? totalWeeks : 1))
        .clamp(0.0, 1.0);
    final percentInt = (progressFactor * 100).round();
    final remainingSessions = (totalWeeks - completedWeeks).clamp(0, 99);

    final liveSession = snapshot.joinableSession;
    final hasLive = liveSession != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet =
            constraints.maxWidth >= 650 && constraints.maxWidth < 1000;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: StudentColors.heroGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: StudentColors.forestDeep.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ambient background decorative blobs
              Positioned(
                top: -40,
                right: isMobile ? -30 : 60,
                child: Container(
                  width: 180,
                  height: 180,
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
                bottom: -30,
                left: 120,
                child: Container(
                  width: 140,
                  height: 140,
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

              // Hero content layout
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Chips (Level, Batch, Streak, Student ID)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _HeroTag(
                          icon: Icons.school_rounded,
                          text: levelLabel,
                          color: StudentColors.forestTint,
                          bgColor: StudentColors.forestDark.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        if (batchLabel != null)
                          _HeroTag(
                            icon: Icons.groups_rounded,
                            text: batchLabel,
                            color: StudentColors.amberLight,
                            bgColor: StudentColors.amberDark.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        if (classLabel != null)
                          _HeroTag(
                            icon: Icons.menu_book_rounded,
                            text: classLabel,
                            color: StudentColors.forestTint,
                            bgColor: Colors.white.withValues(alpha: 0.12),
                          ),
                        _HeroTag(
                          icon: Icons.local_fire_department_rounded,
                          text: '${math.max(3, completedWeeks * 2)} Day Streak',
                          color: StudentColors.amberBorder,
                          bgColor: StudentColors.amberDeep.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        if (student.studentCode.isNotEmpty)
                          _HeroTag(
                            icon: Icons.badge_outlined,
                            text: 'ID: ${student.studentCode}',
                            color: Colors.white70,
                            bgColor: Colors.white.withValues(alpha: 0.08),
                          ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 12 : 16),

                    // Main Greeting & Subtitle + Illustration
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Copy
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${greetingForNow()}, $firstName 👋',
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? 22
                                      : (isTablet ? 27 : 30),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ready to continue your learning journey today?',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 15,
                                  color: StudentColors.forestTint,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasLive
                                          ? Icons.live_tv_rounded
                                          : Icons.lightbulb_outline_rounded,
                                      size: 16,
                                      color: hasLive
                                          ? StudentColors.emeraldPrimary
                                          : StudentColors.amberWarm,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        snapshot.heroMessage,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isMobile ? 12 : 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!isMobile) ...[
                          const SizedBox(width: 16),
                          _HeroRatingPanel(
                            rating: student.feedbackOverallAverage,
                            ratingCount: student.feedbackTotalSessions,
                            compact: isTablet,
                          ),
                        ],
                      ],
                    ),

                    if (isMobile) ...[
                      const SizedBox(height: 12),
                      _HeroRatingPanel(
                        rating: student.feedbackOverallAverage,
                        ratingCount: student.feedbackTotalSessions,
                        compact: true,
                        fullWidth: true,
                      ),
                    ],

                    SizedBox(height: isMobile ? 14 : 18),

                    // Level Progress Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$levelLabel Progress',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '$percentInt%',
                                style: const TextStyle(
                                  color: StudentColors.amberWarm,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: double.infinity,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                LayoutBuilder(
                                  builder: (context, barConstraints) {
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      height: 8,
                                      width:
                                          barConstraints.maxWidth *
                                          progressFactor,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(99),
                                        gradient: const LinearGradient(
                                          colors: [
                                            StudentColors.forestSoft,
                                            StudentColors.progressGold,
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            remainingSessions > 0
                                ? '$remainingSessions more ${remainingSessions == 1 ? "session" : "sessions"} to complete this level milestone'
                                : 'Level milestone complete! Ready for next level',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 13 : 17),

                    // Contextual Action Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _HeroActionButton(
                          busy: _busy,
                          isPrimary: true,
                          isLive: hasLive,
                          label: hasLive
                              ? (liveSession.type == 'master_class'
                                    ? AppStrings.joinMasterClass
                                    : AppStrings.joinIntroductionCall)
                              : snapshot.nextSession != null
                              ? AppStrings.viewYourSession
                              : AppStrings.continueYourJourney,
                          icon: hasLive
                              ? Icons.videocam_rounded
                              : Icons.arrow_forward_rounded,
                          onPressed: () async {
                            if (hasLive) {
                              setState(() => _busy = true);
                              try {
                                await joinStudentSession(ref, liveSession);
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                              return;
                            }
                            if (snapshot.nextSession != null) {
                              context.go(RoutePaths.studentBookings);
                            } else if (snapshot.primaryType != null) {
                              context.go(
                                '${RoutePaths.studentBookNew}?type=${snapshot.primaryType}',
                              );
                            } else {
                              context.go(RoutePaths.studentBookings);
                            }
                          },
                        ),
                        if (snapshot.canBookMasterClass && !hasLive)
                          _HeroActionButton(
                            busy: false,
                            isPrimary: false,
                            label: 'Book Master Class',
                            icon: Icons.calendar_month_rounded,
                            onPressed: () => context.go(
                              '${RoutePaths.studentBookNew}?type=master_class',
                            ),
                          ),
                        if (learning?.week?.videoUrl != null)
                          _HeroActionButton(
                            busy: false,
                            isPrimary: false,
                            label: 'Week ${learning!.currentWeek} Video',
                            icon: Icons.play_circle_fill_rounded,
                            onPressed: () {
                              final journeyId = learning.week?.journeyId;
                              if (journeyId != null && journeyId.isNotEmpty) {
                                context.go(
                                  RoutePaths.studentJournalWeekFor(
                                    journeyId,
                                    learning.currentWeek,
                                  ),
                                );
                              } else {
                                context.go(RoutePaths.studentJournal);
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({
    required this.icon,
    required this.text,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatefulWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
    this.isLive = false,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLive;
  final bool busy;

  @override
  State<_HeroActionButton> createState() => _HeroActionButtonState();
}

class _HeroActionButtonState extends State<_HeroActionButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final bgGradient = widget.isLive
        ? const LinearGradient(
            colors: [StudentColors.forestMid, StudentColors.forest],
          )
        : widget.isPrimary
        ? const LinearGradient(
            colors: [StudentColors.gold, StudentColors.goldDark],
          )
        : null;

    final bgColor = widget.isPrimary
        ? null
        : Colors.white.withValues(alpha: _hover ? 0.20 : 0.12);
    final borderColor = widget.isPrimary
        ? (widget.isLive ? StudentColors.forestSoft : StudentColors.gold)
        : Colors.white.withValues(alpha: 0.25);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.busy ? SystemMouseCursors.wait : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hover ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.busy ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: bgGradient,
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color:
                              (widget.isLive
                                      ? StudentColors.forestMid
                                      : StudentColors.goldDark)
                                  .withValues(alpha: _hover ? 0.45 : 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: widget.isPrimary && !widget.isLive
                          ? StudentColors.forestDeep
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isPrimary && !widget.isLive
                          ? StudentColors.forestDeep
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroRatingPanel extends StatelessWidget {
  const _HeroRatingPanel({
    required this.rating,
    required this.ratingCount,
    this.compact = false,
    this.fullWidth = false,
  });

  final double? rating;
  final int ratingCount;
  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating != null;
    final stars = (rating ?? 0) / 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RoutePaths.studentFeedback),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: fullWidth ? double.infinity : (compact ? 148 : 168),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.overallRating,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasRating ? rating!.toStringAsFixed(1) : '—',
                    style: TextStyle(
                      color: StudentColors.amberWarm,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 28 : 34,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      '/ 10',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        stars >= i
                            ? Icons.star_rounded
                            : stars >= i - 0.5
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: StudentColors.amberWarm,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hasRating
                    ? '$ratingCount monthly rating${ratingCount == 1 ? '' : 's'}'
                    : AppStrings.noRating,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
