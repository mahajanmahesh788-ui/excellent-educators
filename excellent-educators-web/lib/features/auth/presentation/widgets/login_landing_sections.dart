import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Below-the-fold landing experience sections for Excellent Educators.
/// Fully responsive across Desktop, Tablet, and Mobile screens.
class LoginLandingSections extends StatelessWidget {
  const LoginLandingSections({super.key, required this.content});

  final LoginPageContentDto content;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          // ── SECTION 1: HOW YOUR JOURNEY WORKS ───────────────────────
          _SectionPad(
            top: 72,
            bottom: 64,
            child: _JourneyWorkflowSection(wide: wide, content: content),
          ),

          // ── SECTION 2: MORE THAN LEARNING (SPLIT FEATURE) ───────────
          Container(
            color: AppColors.canvas,
            child: _SectionPad(
              top: 80,
              bottom: 80,
              child: _MoreThanLearningSection(wide: wide),
            ),
          ),

          // ── SECTION 2.5: STORIES / REAL PLATFORM EXPERIENCE ─────────
          if (content.stories.isNotEmpty)
            _SectionPad(
              top: 72,
              bottom: 64,
              child: _StoriesSection(
                stories: content.stories,
                wide: wide,
              ),
            ),

          // ── SECTION 3: TRUST SIGNALS STRIP ──────────────────────────
          if (content.trustSignals.isNotEmpty)
            _SectionPad(
              top: 64,
              bottom: 32,
              child: _TrustSignalsStrip(
                signals: content.trustSignals,
                wide: wide,
              ),
            ),

          // ── SECTION 4: TESTIMONIALS / SOCIAL PROOF ──────────────────
          if (content.testimonials.isNotEmpty)
            Container(
              color: AppColors.canvasSoft,
              child: _SectionPad(
                top: 72,
                bottom: 80,
                child: _TestimonialsSection(
                  heading: content.testimonialsHeading ?? 'Voices from our community',
                  testimonials: content.testimonials,
                  wide: wide,
                ),
              ),
            ),

          // ── SECTION 5: FOOTER ───────────────────────────────────────
          const _LandingFooter(),
        ],
      ),
    );
  }
}

/// Standardized container for landing page sections with responsive mobile scaling
class _SectionPad extends StatelessWidget {
  const _SectionPad({
    required this.child,
    this.top = 64,
    this.bottom = 64,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= Breakpoints.tablet;
    final isMobile = width < Breakpoints.mobile;

    // Scale padding down gracefully on mobile to prevent excessive empty vertical space
    final scaledTop = isMobile ? (top * 0.55).clamp(24.0, 44.0) : top;
    final scaledBottom = isMobile ? (bottom * 0.55).clamp(24.0, 44.0) : bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 48 : (isMobile ? 16 : 24),
            scaledTop,
            isDesktop ? 48 : (isMobile ? 16 : 24),
            scaledBottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. HOW YOUR JOURNEY WORKS (4 STAGES)
// ─────────────────────────────────────────────────────────────────────────────

class _StageColorPalette {
  const _StageColorPalette({required this.iconBg, required this.iconColor});
  final Color iconBg;
  final Color iconColor;
}

const _stagePalettes = [
  _StageColorPalette(iconBg: Color(0xFFFEF3C7), iconColor: Color(0xFFD97706)),
  _StageColorPalette(iconBg: Color(0xFFDDF3E8), iconColor: Color(0xFF1E7654)),
  _StageColorPalette(iconBg: Color(0xFFE0F2FE), iconColor: Color(0xFF0284C7)),
  _StageColorPalette(iconBg: Color(0xFFE6F4EA), iconColor: Color(0xFF0D9488)),
  _StageColorPalette(iconBg: Color(0xFFFCE7F3), iconColor: Color(0xFFDB2777)),
  _StageColorPalette(iconBg: Color(0xFFFFFBEB), iconColor: Color(0xFFB45309)),
];

class _JourneyWorkflowSection extends StatelessWidget {
  const _JourneyWorkflowSection({
    required this.wide,
    required this.content,
  });

  final bool wide;
  final LoginPageContentDto content;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    final heading = (content.whyHeading ?? '').trim().isNotEmpty
        ? content.whyHeading!.trim()
        : 'How Your Journey Works';

    final stages = content.pillars.isNotEmpty
        ? [
            for (var i = 0; i < content.pillars.length; i++)
              _StageData(
                number: (i + 1).toString().padLeft(2, '0'),
                title: content.pillars[i].title,
                body: content.pillars[i].body,
                icon: loginPageIcon(content.pillars[i].icon),
                iconBg: _stagePalettes[i % _stagePalettes.length].iconBg,
                iconColor: _stagePalettes[i % _stagePalettes.length].iconColor,
              ),
          ]
        : const [
            _StageData(
              number: '01',
              title: 'Discover Yourself',
              body: 'Uncover innate strengths, learning styles, and natural curiosity through guided discovery.',
              icon: Icons.lightbulb_outline_rounded,
              iconBg: Color(0xFFFEF3C7),
              iconColor: Color(0xFFD97706),
            ),
            _StageData(
              number: '02',
              title: 'Build Your Skills',
              body: 'Develop essential real-world capabilities — communication, critical thinking, and disciplined habits.',
              icon: Icons.auto_awesome_rounded,
              iconBg: Color(0xFFEEF2FF),
              iconColor: Color(0xFF4F46E5),
            ),
            _StageData(
              number: '03',
              title: 'Explore Your Future',
              body: 'Map genuine academic and career pathways tailored to your personalized profile with total clarity.',
              icon: Icons.rocket_launch_outlined,
              iconBg: Color(0xFFE0F2FE),
              iconColor: Color(0xFF0284C7),
            ),
            _StageData(
              number: '04',
              title: 'Grow With Guidance',
              body: 'Learn 1:1 with dedicated master mentors who review your weekly progress and guide your evolution.',
              icon: Icons.school_outlined,
              iconBg: Color(0xFFECFDF5),
              iconColor: Color(0xFF059669),
            ),
          ];

    return Column(
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Text(
            'STRUCTURED STUDENT DEVELOPMENT',
            style: TextStyle(
              fontSize: isMobile ? 10 : 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          heading,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 36 : (isMobile ? 24 : 28),
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'A proven, progressive roadmap designed to guide every student from self-discovery to lasting confidence and direction.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: wide ? 16 : (isMobile ? 13.5 : 14.5),
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: wide ? 48 : (isMobile ? 24 : 32)),

        // Stage Cards
        if (wide && stages.length <= 4)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                Expanded(child: _StageCard(data: stages[i])),
                if (i < stages.length - 1) const SizedBox(width: 20),
              ],
            ],
          )
        else if (wide)
          // Wide with more than 4 items: rows of up to 3 or 4 items
          Column(
            children: [
              for (var i = 0; i < stages.length; i += 3) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = i; j < i + 3 && j < stages.length; j++) ...[
                      Expanded(child: _StageCard(data: stages[j])),
                      if (j < i + 2 && j < stages.length - 1) const SizedBox(width: 20),
                    ],
                    if (i + 3 > stages.length && stages.length % 3 != 0)
                      for (var k = 0; k < 3 - (stages.length % 3); k++) ...[
                        const SizedBox(width: 20),
                        const Expanded(child: SizedBox()),
                      ],
                  ],
                ),
                if (i + 3 < stages.length) const SizedBox(height: 20),
              ],
            ],
          )
        else if (!isMobile)
          // Tablet 2x2 or 2-column
          Column(
            children: [
              for (var i = 0; i < stages.length; i += 2) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _StageCard(data: stages[i])),
                    const SizedBox(width: 16),
                    if (i + 1 < stages.length)
                      Expanded(child: _StageCard(data: stages[i + 1]))
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
                if (i + 2 < stages.length) const SizedBox(height: 16),
              ],
            ],
          )
        else
          // Mobile column
          Column(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                _StageCard(data: stages[i]),
                if (i < stages.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _StageData {
  const _StageData({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String number;
  final String title;
  final String body;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}

class _StageCard extends StatefulWidget {
  const _StageCard({required this.data});

  final _StageData data;

  @override
  State<_StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<_StageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(
            color: _hovered
                ? widget.data.iconColor.withValues(alpha: 0.45)
                : AppColors.border,
            width: _hovered ? 1.5 : 1.2,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.data.iconColor.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Number & Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: isMobile ? 42 : 48,
                  height: isMobile ? 42 : 48,
                  decoration: BoxDecoration(
                    color: widget.data.iconBg,
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: widget.data.iconColor,
                    size: isMobile ? 22 : 24,
                  ),
                ),
                Text(
                  widget.data.number,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 14 : 20),

            // Title
            Text(
              widget.data.title,
              style: TextStyle(
                fontSize: isMobile ? 16.5 : 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),

            // Explanation
            Text(
              widget.data.body,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SECOND SECTION: MORE THAN LEARNING (SPLIT FEATURE)
// ─────────────────────────────────────────────────────────────────────────────

class _MoreThanLearningSection extends StatelessWidget {
  const _MoreThanLearningSection({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;
    final visual = const _PlatformPreviewCard();

    final copy = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.accentBorder),
          ),
          child: Text(
            'BEYOND TRADITIONAL COACHING',
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: AppColors.accentDeep,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'More than learning.\nA journey to understand yourself.',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 34 : (isMobile ? 22 : 26),
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Most educational platforms focus strictly on rote textbook drilling and last-minute exam pressure. '
          'Excellent Educators builds the complete person — unlocking self-awareness, leadership, and long-term purpose.',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 13.5 : 15,
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
        SizedBox(height: isMobile ? 18 : 24),

        // Value Checklist
        const _FeatureCheckItem(
          title: 'Personalized Development Roadmap',
          subtitle: 'Shaped around the student’s innate curiosity, not a rigid one-size-fits-all syllabus.',
        ),
        const SizedBox(height: 12),
        const _FeatureCheckItem(
          title: 'Weekly Reflection & Real Evidence',
          subtitle: 'Video lessons, reflective questions, and a written trail proving real progress every week.',
        ),
        const SizedBox(height: 12),
        const _FeatureCheckItem(
          title: 'Mentors Who Truly Stay',
          subtitle: 'Continuous guidance with the same dedicated faculty week after week.',
        ),
      ],
    );

    if (!wide) {
      return Column(
        children: [
          copy,
          SizedBox(height: isMobile ? 24 : 36),
          visual,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: visual),
        const SizedBox(width: 56),
        Expanded(flex: 5, child: copy),
      ],
    );
  }
}

class _FeatureCheckItem extends StatelessWidget {
  const _FeatureCheckItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 13, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// High-fidelity preview card of the student growth platform
class _PlatformPreviewCard extends StatelessWidget {
  const _PlatformPreviewCard();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with student avatar and status
          Row(
            children: [
              Container(
                width: isMobile ? 38 : 46,
                height: isMobile ? 38 : 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryMid, AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'AS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aarav Sharma · Grade 10',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Learning Journey · Active',
                      style: TextStyle(
                        fontSize: isMobile ? 11.5 : 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'On Track',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 22),
          const Divider(color: AppColors.border),
          SizedBox(height: isMobile ? 14 : 18),

          // Growth Dimensions Snapshot
          Text(
            'KEY GROWTH DIMENSIONS',
            style: TextStyle(
              fontSize: isMobile ? 10.5 : 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),

          const _DimensionProgressRow(
            label: 'Analytical Curiosity',
            value: 0.92,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          const _DimensionProgressRow(
            label: 'Leadership & Habits',
            value: 0.88,
            color: AppColors.accent,
          ),
          const SizedBox(height: 10),
          const _DimensionProgressRow(
            label: 'Communication & Confidence',
            value: 0.84,
            color: Color(0xFF10B981),
          ),
          SizedBox(height: isMobile ? 18 : 22),

          // Mentor Note Snippet
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"Aarav demonstrated exceptional clarity during this week’s reflection call. His problem-solving structure has improved significantly."',
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 12.5,
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
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

class _DimensionProgressRow extends StatelessWidget {
  const _DimensionProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: isMobile ? 11.5 : 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: AppColors.canvas,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2.5 STORIES SECTION (ADMIN DYNAMIC)
// ─────────────────────────────────────────────────────────────────────────────

class _StoriesSection extends StatelessWidget {
  const _StoriesSection({required this.stories, required this.wide});

  final List<LoginPageStoryDto> stories;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Text(
            'EXPERIENCE & IMPACT',
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A rhythm designed for real life',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: wide ? 34 : (isMobile ? 24 : 28),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: wide ? 48 : (isMobile ? 24 : 32)),
        for (var i = 0; i < stories.length; i++) ...[
          _StoryItemRow(story: stories[i], wide: wide),
          if (i < stories.length - 1)
            SizedBox(height: wide ? 64 : (isMobile ? 32 : 48)),
        ],
      ],
    );
  }
}

class _StoryItemRow extends StatelessWidget {
  const _StoryItemRow({required this.story, required this.wide});

  final LoginPageStoryDto story;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvasSoft,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
          boxShadow: AppColors.cardShadow,
        ),
        constraints: BoxConstraints(
          maxHeight: isMobile ? 220 : 320,
          minHeight: 180,
        ),
        width: double.infinity,
        child: story.imageUrl.trim().isNotEmpty
            ? Image.network(
                story.imageUrl.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.canvas,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 44,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            : Container(
                color: AppColors.canvas,
                child: const Center(
                  child: Icon(
                    Icons.school_outlined,
                    size: 44,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
      ),
    );

    final textWidget = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          story.title,
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 28 : (isMobile ? 20 : 24),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          story.body,
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 13.5 : 15,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );

    if (!wide) {
      return Column(
        children: [
          imageWidget,
          SizedBox(height: isMobile ? 16 : 24),
          textWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: story.imageOnLeft
          ? [
              Expanded(flex: 5, child: imageWidget),
              const SizedBox(width: 48),
              Expanded(flex: 6, child: textWidget),
            ]
          : [
              Expanded(flex: 6, child: textWidget),
              const SizedBox(width: 48),
              Expanded(flex: 5, child: imageWidget),
            ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. TRUST SIGNALS STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _TrustSignalsStrip extends StatelessWidget {
  const _TrustSignalsStrip({required this.signals, required this.wide});

  final List<LoginPageTrustSignalDto> signals;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final signal in signals) _TrustMetricCard(signal: signal),
    ];

    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 20),
        ],
      ],
    );
  }
}

class _TrustMetricCard extends StatelessWidget {
  const _TrustMetricCard({required this.signal});

  final LoginPageTrustSignalDto signal;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            child: Icon(
              loginPageIcon(signal.icon),
              size: isMobile ? 20 : 24,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  signal.value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 15.5 : 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  signal.label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 12 : 13,
                    height: 1.35,
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

// ─────────────────────────────────────────────────────────────────────────────
// 4. TESTIMONIALS / SOCIAL PROOF
// ─────────────────────────────────────────────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection({
    required this.heading,
    required this.testimonials,
    required this.wide,
  });

  final String heading;
  final List<LoginPageTestimonialDto> testimonials;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Text(
            'TESTED & TRUSTED',
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          heading,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: wide ? 34 : (isMobile ? 24 : 28),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'Real experiences from parents, students, and master educators building confidence together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: wide ? 16 : (isMobile ? 13.5 : 14.5),
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: wide ? 48 : (isMobile ? 24 : 32)),

        // Grid of Quotes
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < testimonials.length; i++) ...[
                Expanded(child: _RefinedQuoteCard(item: testimonials[i])),
                if (i < testimonials.length - 1) const SizedBox(width: 20),
              ],
            ],
          )
        else if (!isMobile)
          // Tablet 2x2
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _RefinedQuoteCard(item: testimonials[0])),
                  if (testimonials.length > 1) ...[
                    const SizedBox(width: 16),
                    Expanded(child: _RefinedQuoteCard(item: testimonials[1])),
                  ],
                ],
              ),
              if (testimonials.length > 2) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _RefinedQuoteCard(item: testimonials[2])),
                    if (testimonials.length > 3) ...[
                      const SizedBox(width: 16),
                      Expanded(child: _RefinedQuoteCard(item: testimonials[3])),
                    ],
                  ],
                ),
              ],
            ],
          )
        else
          // Mobile column
          Column(
            children: [
              for (var i = 0; i < testimonials.length; i++) ...[
                _RefinedQuoteCard(item: testimonials[i]),
                if (i < testimonials.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
      ],
    );
  }
}

class _RefinedQuoteCard extends StatelessWidget {
  const _RefinedQuoteCard({required this.item});

  final LoginPageTestimonialDto item;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 5-Star Row
          Row(
            children: List.generate(
              5,
              (_) => Icon(
                Icons.star_rounded,
                size: isMobile ? 16 : 18,
                color: AppColors.accent,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // Quote Text
          Text(
            '"${item.quote}"',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isMobile ? 13.5 : 14.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMobile ? 14 : 20),
          const Divider(color: AppColors.border),
          SizedBox(height: isMobile ? 10 : 14),

          // Attribution & Role Badge
          Row(
            children: [
              Container(
                width: isMobile ? 32 : 36,
                height: isMobile ? 32 : 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.attribution.isNotEmpty ? item.attribution[0] : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: isMobile ? 13.5 : 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.attribution,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                    if ((item.role ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        item.role!.trim(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isMobile ? 11.5 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. LANDING FOOTER (MOBILE OVERFLOW-SAFE)
// ─────────────────────────────────────────────────────────────────────────────

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    Widget links = Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: isMobile ? WrapAlignment.center : WrapAlignment.end,
      children: [
        TextButton(
          onPressed: () => context.go(RoutePaths.privacyPolicy),
          child: const Text(AppStrings.privacyPolicy, style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => context.go(RoutePaths.termsAndConditions),
          child: const Text(AppStrings.termsAndConditions, style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => context.go(RoutePaths.refundPolicy),
          child: const Text(AppStrings.refundPolicy, style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => context.go(RoutePaths.contact),
          child: const Text(AppStrings.contactUs, style: TextStyle(fontSize: 12)),
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.2),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 24 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: isMobile
              ? Column(
                  children: [
                    const AppLogo(height: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Building Careers. Creating Leaders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    links,
                    const SizedBox(height: 12),
                    Text(
                      '© ${DateTime.now().year} Excellent Educators. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            AppLogo(height: 32),
                            SizedBox(width: 12),
                            Text(
                              'Building Careers. Creating Leaders.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        links,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '© ${DateTime.now().year} Excellent Educators. All rights reserved.',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
