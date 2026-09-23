import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

/// ---------------------------------------------------------------------------
/// 1. Fresh Student Welcome Hero
/// ---------------------------------------------------------------------------
class FreshStudentHero extends StatelessWidget {
  const FreshStudentHero({
    super.key,
    required this.student,
    this.onStartQuestionnaire,
  });

  final StudentDto student;
  final VoidCallback? onStartQuestionnaire;

  @override
  Widget build(BuildContext context) {
    final firstName = student.fullName.trim().split(' ').first;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            offset: const Offset(0, 10),
            blurRadius: 28,
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background decorative rings
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StudentColors.amberBorder.withValues(alpha: 0.22),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Step Badge
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: StudentColors.amberLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: StudentColors.amberBorder),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rocket_launch_rounded,
                            size: 14,
                            color: StudentColors.amberDark,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'STEP 1 OF YOUR JOURNEY',
                            style: TextStyle(
                              color: StudentColors.amberBrown,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        student.level?.label.isNotEmpty == true
                            ? student.level!.label
                            : 'Fresh Student',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Welcome Heading
                Text(
                  'Welcome to Excellent Educators, $firstName 👋',
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    "Let's discover what makes you unique. Help us learn about your interests, mindset, and strengths so we can personalize your learning journey and faculty mentors.",
                    style: TextStyle(
                      fontSize: isMobile ? 13.5 : 15,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.5,
                    ),
                  ),
                ),

                if (onStartQuestionnaire != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onStartQuestionnaire,
                    style: FilledButton.styleFrom(
                      backgroundColor: StudentColors.amberPrimary,
                      foregroundColor: StudentColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                      color: StudentColors.textPrimary,
                    ),
                    label: const Text(
                      'Start Questionnaire',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
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
/// 2. Top-Level Onboarding Stepper (Steps 1 to 4)
/// ---------------------------------------------------------------------------
class FreshStudentStepper extends StatelessWidget {
  const FreshStudentStepper({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    final steps = [
      (
        step: 1,
        title: 'Discover Yourself',
        subtitle: 'Interests & Mindset',
        isActive: true,
        isCompleted: false,
        isLocked: false,
      ),
      (
        step: 2,
        title: 'Understand Strengths',
        subtitle: 'Faculty Insights',
        isActive: false,
        isCompleted: false,
        isLocked: true,
      ),
      (
        step: 3,
        title: 'Build Your Journey',
        subtitle: 'Curriculum & Habits',
        isActive: false,
        isCompleted: false,
        isLocked: true,
      ),
      (
        step: 4,
        title: 'Start Sessions',
        subtitle: '1-on-1 Mentorship',
        isActive: false,
        isCompleted: false,
        isLocked: true,
      ),
    ];

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: StudentColors.border),
          boxShadow: StudentColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR ONBOARDING JOURNEY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: StudentColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: StudentColors.indigoLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Step 1 of 4 Active',
                    style: TextStyle(
                      color: StudentColors.indigoPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < steps.length; i++) ...[
              _MobileStepRow(step: steps[i], isLast: i == steps.length - 1),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudentColors.border),
        boxShadow: StudentColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR ONBOARDING JOURNEY',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: StudentColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.indigoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Complete Step 1 to Unlock Next Stages',
                  style: TextStyle(
                    color: StudentColors.indigoPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(child: _DesktopStepItem(step: steps[i])),
                if (i < steps.length - 1)
                  Container(
                    width: 28,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: StudentColors.border,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopStepItem extends StatelessWidget {
  const _DesktopStepItem({required this.step});

  final ({
    bool isActive,
    bool isCompleted,
    bool isLocked,
    int step,
    String subtitle,
    String title,
  })
  step;

  @override
  Widget build(BuildContext context) {
    final active = step.isActive;
    final locked = step.isLocked;

    final (Color stepThemeColor, Color stepThemeLight) = switch (step.step) {
      1 => (StudentColors.indigoPrimary, StudentColors.indigoLight),
      2 => (StudentColors.amberDark, StudentColors.amberLight), // Warm Amber
      3 => (StudentColors.live, StudentColors.successSoft), // Fresh Emerald
      4 => (StudentColors.skyPrimary, StudentColors.skyLight), // Sky Blue
      _ => (StudentColors.indigoPrimary, StudentColors.indigoLight),
    };

    final Color badgeBg = active
        ? stepThemeColor
        : (locked ? stepThemeLight : StudentColors.emeraldLight);
    final Color badgeColor = active
        ? Colors.white
        : (locked ? stepThemeColor : StudentColors.emeraldDark);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? StudentColors.indigoLight.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? StudentColors.indigoPrimary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
              boxShadow: active
                  ? StudentColors.glow(
                      StudentColors.indigoPrimary,
                      opacity: 0.3,
                    )
                  : null,
            ),
            child: Center(
              child: locked
                  ? Icon(Icons.lock_rounded, size: 16, color: badgeColor)
                  : (step.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : Text(
                            '${step.step}',
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'STEP ${step.step}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: active
                            ? stepThemeColor
                            : stepThemeColor.withValues(alpha: 0.85),
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: StudentColors.indigoPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: locked
                        ? StudentColors.textMuted
                        : StudentColors.textPrimary,
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

class _MobileStepRow extends StatelessWidget {
  const _MobileStepRow({required this.step, required this.isLast});

  final ({
    bool isActive,
    bool isCompleted,
    bool isLocked,
    int step,
    String subtitle,
    String title,
  })
  step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final active = step.isActive;
    final locked = step.isLocked;

    final (Color stepThemeColor, Color stepThemeLight) = switch (step.step) {
      1 => (StudentColors.indigoPrimary, StudentColors.indigoLight),
      2 => (StudentColors.amberDark, StudentColors.amberLight),
      3 => (StudentColors.live, StudentColors.successSoft),
      4 => (StudentColors.skyPrimary, StudentColors.skyLight),
      _ => (StudentColors.indigoPrimary, StudentColors.indigoLight),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active
                  ? stepThemeColor
                  : (locked ? stepThemeLight : StudentColors.emeraldLight),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: locked
                  ? Icon(Icons.lock_rounded, size: 14, color: stepThemeColor)
                  : Text(
                      '${step.step}',
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : StudentColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: locked
                            ? StudentColors.textMuted
                            : StudentColors.textPrimary,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: StudentColors.indigoPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ] else if (locked) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: StudentColors.textMuted,
                      ),
                    ],
                  ],
                ),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: StudentColors.textMuted,
                  ),
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
/// 3. Dashboard Lock Banner (Required First Step Action Banner)
/// ---------------------------------------------------------------------------
class FreshStudentLockBanner extends StatelessWidget {
  const FreshStudentLockBanner({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: StudentColors.amberWash, // Warm amber background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudentColors.amberBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: StudentColors.amberPrimary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: isMobile
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudentColors.amberPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: StudentColors.amberDeep,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Your first step starts here 🚀',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: StudentColors.amberBrown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete your Discovery Questionnaire to unlock your learning journey and booking.',
                  style: TextStyle(
                    fontSize: 13,
                    color: StudentColors.amberInk,
                    height: 1.35,
                  ),
                ),
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: StudentColors.amberDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 14),
                    label: const Text(
                      'Continue Questionnaire',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: StudentColors.amberDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
              label: const Text(
                'Continue Questionnaire',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 4. "What Happens Next?" Roadmap Card
/// ---------------------------------------------------------------------------
class FreshStudentRoadmapCard extends StatelessWidget {
  const FreshStudentRoadmapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudentColors.border),
        boxShadow: StudentColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudentColors.indigoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  size: 18,
                  color: StudentColors.indigoPrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHAT HAPPENS NEXT?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: StudentColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your Path After Completing Discovery',
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
          const SizedBox(height: 18),
          const Divider(height: 1, color: StudentColors.border),
          const SizedBox(height: 16),
          const _MilestoneItem(
            index: '1',
            title: 'Discover Yourself',
            subtitle: 'Compulsory first step to map your interests, mindset, and strengths.',
            status: 'IN PROGRESS',
            statusColor: StudentColors.amberPrimary,
            isCurrent: true,
          ),
          const SizedBox(height: 14),
          const _MilestoneItem(
            index: '2',
            title: 'Understand Your Strengths',
            subtitle: 'Faculty mentors review your profile to prepare personalized mentorship.',
            status: 'LOCKED',
            statusColor: StudentColors.textMuted,
            isCurrent: false,
          ),
          const SizedBox(height: 14),
          const _MilestoneItem(
            index: '3',
            title: 'Build Your Skills',
            subtitle: 'Unlock weekly video modules, aptitude questions & reflective journals.',
            status: 'LOCKED',
            statusColor: StudentColors.textMuted,
            isCurrent: false,
          ),
          const SizedBox(height: 14),
          const _MilestoneItem(
            index: '4',
            title: 'Start Your Sessions',
            subtitle: 'Book your 1-on-1 Introduction Call and ongoing Master Classes.',
            status: 'LOCKED',
            statusColor: StudentColors.textMuted,
            isCurrent: false,
          ),
        ],
      ),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  const _MilestoneItem({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.isCurrent,
  });

  final String index;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCurrent
                ? StudentColors.indigoPrimary
                : StudentColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: isCurrent
                ? const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.lock_rounded,
                    size: 13,
                    color: StudentColors.textMuted,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$index. $title',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                      color: isCurrent
                          ? StudentColors.textPrimary
                          : StudentColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: StudentColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// 5. Locked Feature Notice Dialog (Shown when student clicks locked nav items)
/// ---------------------------------------------------------------------------
class LockedFeatureNoticeDialog extends StatelessWidget {
  const LockedFeatureNoticeDialog({super.key, required this.featureName});

  final String featureName;

  static Future<void> show(
    BuildContext context, {
    required String featureName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) =>
          LockedFeatureNoticeDialog(featureName: featureName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: StudentColors.amberLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: StudentColors.amberBorder,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.explore_rounded,
                    color: StudentColors.amberDeep,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Complete your Discovery Questionnaire first',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: StudentColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access to $featureName and session bookings unlocks as soon as you finish your Interest & Mindset Discovery.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: StudentColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StudentColors.textSecondary,
                        side: const BorderSide(color: StudentColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Maybe Later',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(RoutePaths.studentDashboard);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: StudentColors.indigoPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue Questionnaire',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
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

/// ---------------------------------------------------------------------------
/// 6. Booking Protection Guard Card (Shown on /student/bookings if questionnaire pending)
/// ---------------------------------------------------------------------------
class BookingQuestionnaireGuardCard extends StatelessWidget {
  const BookingQuestionnaireGuardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          padding: EdgeInsets.all(isMobile ? 24 : 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: StudentColors.amberBorder, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: StudentColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: StudentColors.amberLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: StudentColors.amberWarm, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: StudentColors.amberDeep,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.amberPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'COMPULSORY FOR NEW STUDENTS',
                  style: TextStyle(
                    color: StudentColors.amberDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Complete Your First Step',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: StudentColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your Discovery Questionnaire is required before booking your first session. Help our mentors understand your interests, hobbies, and learning mindset.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: StudentColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go(RoutePaths.studentDashboard),
                style: FilledButton.styleFrom(
                  backgroundColor: StudentColors.indigoPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                label: const Text(
                  'Complete Questionnaire',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
