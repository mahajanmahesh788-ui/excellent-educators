import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class AchievementCardsWidget extends StatelessWidget {
  const AchievementCardsWidget({
    super.key,
    required this.student,
    required this.snapshot,
    this.learning,
  });

  final StudentDto student;
  final StudentJourneySnapshot snapshot;
  final LearningDashboardDto? learning;

  @override
  Widget build(BuildContext context) {
    final completedWeeks =
        learning?.completedWeeks ?? (snapshot.introductionCompleted ? 1 : 0);
    final totalAttended = student.feedbackTotalSessions > 0
        ? student.feedbackTotalSessions
        : (snapshot.introductionCompleted ? 1 : 0) + snapshot.masterThisMonth;
    final streakDays = math.max(
      3,
      completedWeeks * 2 + (totalAttended > 0 ? 1 : 0),
    );

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return StudentCard(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: StudentColors.amberLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 18,
                  color: StudentColors.amberDark,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MILESTONES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: StudentColors.amberDark,
                    ),
                  ),
                  Text(
                    'Badges & Learning Streaks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: StudentColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AchievementBadge(
                emoji: '🔥',
                title: '$streakDays Day Streak',
                subtitle: 'Consistent Daily Study',
                bgColor: StudentColors.orangeSoft,
                borderColor: StudentColors.orangeBorder,
                textColor: StudentColors.orangeText,
              ),
              _AchievementBadge(
                emoji: '⭐',
                title:
                    '$totalAttended ${totalAttended == 1 ? "Class" : "Classes"} Held',
                subtitle: 'Live Mentorships',
                bgColor: StudentColors.amberLight,
                borderColor: StudentColors.amberBorder,
                textColor: StudentColors.amberDeep,
              ),
              _AchievementBadge(
                emoji: '🎯',
                title:
                    '$completedWeeks ${completedWeeks == 1 ? "Week" : "Weeks"} Cleared',
                subtitle: 'Curriculum Progress',
                bgColor: StudentColors.forestLight,
                borderColor: StudentColors.forestBorder,
                textColor: StudentColors.forest,
              ),
              if (student.hasSubmittedAptitudeAssessment)
                const _AchievementBadge(
                  emoji: '🧠',
                  title: 'Aptitude Certified',
                  subtitle: 'Diagnostic Passed',
                  bgColor: StudentColors.successSoft,
                  borderColor: StudentColors.successBorder,
                  textColor: StudentColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
