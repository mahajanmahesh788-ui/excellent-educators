import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Premium brand presentation panel featuring Student Growth & Mentorship visuals.
class LoginBrandPanel extends ConsumerWidget {
  const LoginBrandPanel({
    super.key,
    required this.compact,
    this.content,
  });

  final bool compact;
  final LoginPageContentDto? content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoginPageContentDto resolvedContent = content ??
        ref.watch(loginPageContentProvider).maybeWhen(
              data: (value) => value,
              orElse: () => LoginPageContentDto.defaults,
            );

    final tagline = resolvedContent.tagline.trim().isNotEmpty
        ? resolvedContent.tagline.trim().toUpperCase()
        : 'STUDENT GROWTH & MENTORSHIP';

    final headline = resolvedContent.headline.trim().isNotEmpty
        ? resolvedContent.headline.trim()
        : 'Discover what makes\nyou different.';

    final pillars = resolvedContent.pillars.isNotEmpty
        ? resolvedContent.pillars
        : const [
            LoginPagePillarDto(
              icon: 'psychology_outlined',
              title: 'Innate Strengths',
              body: '',
            ),
            LoginPagePillarDto(
              icon: 'trending_up_rounded',
              title: 'Habits & Skills',
              body: '',
            ),
            LoginPagePillarDto(
              icon: 'explore_outlined',
              title: 'Clear Direction',
              body: '',
            ),
            LoginPagePillarDto(
              icon: 'school_outlined',
              title: '1:1 Master Mentors',
              body: '',
            ),
          ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 48,
        vertical: compact ? 24 : 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Brand Logo & Platform Badge
          Row(
            children: [
              AppLogo(height: compact ? 48 : 64),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tagline,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 20 : 28),

          // Main Headline (Admin Dynamic)
          Text(
            headline,
            style: TextStyle(
              fontSize: compact ? 26 : 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),

          // Subtitle / Tagline Lead
          Text(
            'Build skills that matter. Find your direction.',
            style: TextStyle(
              fontSize: compact ? 15 : 19,
              fontWeight: FontWeight.w600,
              color: AppColors.mintText,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),

          // Description (Admin Dynamic)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              resolvedContent.description,
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.55,
              ),
            ),
          ),

          // Optional Mission Quote (Admin Dynamic)
          if (!compact && (resolvedContent.missionQuote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 580),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      resolvedContent.missionQuote!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: compact ? 16 : 24),

          // Growth Pillar Pills (Admin Dynamic)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pillar in pillars)
                _GrowthPill(
                  icon: loginPageIcon(pillar.icon),
                  label: pillar.title,
                ),
            ],
          ),

          // Large Original Educational / Student Growth Visual
          if (!compact) ...[
            const SizedBox(height: 32),
            const _StudentGrowthHeroVisual(),
          ],
        ],
      ),
    );
  }
}

/// Pill representing a growth pillar
class _GrowthPill extends StatelessWidget {
  const _GrowthPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large, original educational / student-growth visual composition
class _StudentGrowthHeroVisual extends StatelessWidget {
  const _StudentGrowthHeroVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 580, maxHeight: 290),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background subtle concentric orbit rings
          Positioned.fill(
            child: CustomPaint(
              painter: _GrowthOrbitPainter(),
            ),
          ),

          // Floating Milestone Card 1: Top-Left (Self-Discovery)
          Positioned(
            top: 20,
            left: 20,
            child: _FloatingMilestoneCard(
              stageNumber: '01',
              title: 'Self-Discovery Compass',
              subtitle: '10 Growth Dimensions & Curiosity',
              icon: Icons.lightbulb_outline_rounded,
              iconBgColor: AppColors.accent.withValues(alpha: 0.18),
              iconColor: AppColors.accent,
            ),
          ),

          // Floating Milestone Card 2: Right (1:1 Master Mentoring)
          Positioned(
            top: 90,
            right: 20,
            child: _FloatingMilestoneCard(
              stageNumber: '04',
              title: '1:1 Master Mentor',
              subtitle: 'Weekly Review & True Direction',
              icon: Icons.school_outlined,
              iconBgColor: AppColors.primaryMid.withValues(alpha: 0.25),
              iconColor: const Color(0xFFA5B4FC),
            ),
          ),

          // Floating Milestone Card 3: Bottom-Left (Skill Mastery)
          Positioned(
            bottom: 20,
            left: 36,
            child: _FloatingMilestoneCard(
              stageNumber: '02',
              title: 'Skills & Habits Mastery',
              subtitle: 'Problem Solving & Communication',
              icon: Icons.auto_awesome_rounded,
              iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.20),
              iconColor: const Color(0xFF34D399),
            ),
          ),

          // Central Nexus: Growth Core Badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 26,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating glassmorphism milestone card for the hero visual
class _FloatingMilestoneCard extends StatelessWidget {
  const _FloatingMilestoneCard({
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  final String stageNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'STAGE $stageNumber',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw subtle concentric orbit paths
class _GrowthOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.08);

    // Three concentric orbit circles
    canvas.drawCircle(center, size.height * 0.28, paint);
    canvas.drawCircle(center, size.height * 0.45, paint);

    // Diagonal connecting trajectory line
    final trajPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.primaryMid.withValues(alpha: 0.25);

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.82, size.height * 0.45),
      trajPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.75),
      Offset(size.width * 0.50, size.height * 0.50),
      trajPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
